from sys import stderr, param_env
from solution import Solution
from algorithm.functional import vectorize, parallelize

from gpu.host import DeviceContext, DeviceFunction, DeviceBuffer#, HostBuffer
from gpu import thread_idx, block_idx, block_dim, grid_dim, barrier
from gpu.memory import AddressSpace
from layout import Layout, LayoutTensor
from layout.runtime_layout import RuntimeLayout
from layout.runtime_tuple import RuntimeTuple
from utils.index import IndexList
from math import ceildiv
from os import Atomic
from memory import stack_allocation

comptime temp_layout = Layout.row_major(0,0) # gives it rank
comptime itype = DType.uint64
comptime sitype = Scalar[itype]

comptime tile_size = 16#Int(param_env.env_get_int["TILE_SIZE", 16]())
comptime halo = 1
comptime local_size = tile_size + 2 * halo

comptime MAGIC_NUMBER = 4

fn partTwoKernel(grid: LayoutTensor[DType.uint8, temp_layout, MutAnyOrigin], rows: UInt, cols: UInt, locations_to_zero: UnsafePointer[sitype, MutAnyOrigin]) -> None:
    var tile_row = block_idx.y
    var tile_col = block_idx.x
    var ty = thread_idx.y
    var tx = thread_idx.x

    var gy = tile_row * tile_size + ty
    var gx = tile_col * tile_size + tx

    #if tx == 0 and ty == 0 and tile_row == 0 and tile_col == 0:
    #    print("HOWDY\n", grid)

    var local_tile = LayoutTensor[DType.uint8, Layout.row_major(local_size, local_size), MutAnyOrigin, address_space = AddressSpace.SHARED].stack_allocation()

    var local_flags = LayoutTensor[itype, Layout.row_major(tile_size, tile_size), MutAnyOrigin, address_space = AddressSpace.SHARED].stack_allocation().fill(0)

    barrier()
    comptime loads = ceildiv((local_size * local_size) , (tile_size * tile_size))
    
    @parameter
    for load_id in range(loads):
        # flatten indexes and reshape them as needed
        var linear = ty * tile_size + tx + UInt(load_id * tile_size * tile_size)
        if linear < local_size * local_size:
            var sh_y = linear // local_size #ty + UInt(load_id * tile_size)
            var sh_x = linear % local_size #tx + UInt(load_id * tile_size)
            
            var gy_h = Int(tile_row * tile_size + sh_y - halo)
            var gx_h = Int(tile_col * tile_size + sh_x - halo)
            
            if gy_h >= 0 and gy_h < Int(rows) and gx_h >= 0 and gx_h < Int(cols):
                local_tile[sh_y, sh_x] = grid[gy_h, gx_h]
            else:
                local_tile[sh_y, sh_x] = 0
        barrier()
    #if ty == 0 and tx == 0:
    #    print(String(tile_row), String(tile_col), " local_tile =>\n", local_tile, "\n")

    # count neighbors
    if gy < rows and gx < cols and local_tile[ty + halo, tx + halo] != 0:
        var acc: sitype = -1 # dont count ourself
        for ky in range(-halo, halo + 1):
            for kx in range(-halo, halo + 1):
                acc += Int(local_tile[Int(ty) + ky + halo, Int(tx) + kx + halo])

        #print("cell", String(gy), String(gx), "acc", String(acc))
    
        if acc < MAGIC_NUMBER:
            locations_to_zero[gy * cols + gx] = 1
            local_flags[ty, tx] = 1
    
    fn printLocalFlags(prefix: String) capturing:
        if ty == 0 and tx == 0:
            var tile_idx_str = "(" + String(tile_row) + ", " + String(tile_col)  + ")\n"
            var tile_str = "\n"
            for r in range(tile_size):
                for c in range(tile_size):
                    tile_str += String(local_flags[r * tile_size + c])
                tile_str += "\n"

            var final = prefix + " tileidx flags " + tile_idx_str + tile_str
            print(final)

    #printLocalFlags("before")
    barrier()

    # reduce_add
    var stride = 1
    var linear = Int(ty * tile_size + tx)
    comptime tot = tile_size * tile_size
    while stride < tot:
        barrier()
        if linear + stride < tot and linear % (stride * 2) == 0:
                local_flags.ptr[linear] += local_flags.ptr[linear + stride]
        stride *= 2
    #printLocalFlags("after")
    #if ty == 0 and tx == 0:
    #    _ = Atomic[itype].fetch_add(answer_out, Int(local_flags[0, 0]))

@always_inline
fn byteToChar(byte: Byte) -> String:
    return String(chr(Int(byte)))

@fieldwise_init
struct Solution04(Solution):
    
    fn partOne(self, input_file: String) -> String:
        var lines = input_file.split("\n")
        var accessible = 0
        if not len(lines[-1]):
            _ = lines.pop()

        comptime chunk_size = 3
        var n = len(lines) # number of rows
        var m = len(lines[0]) # length of row (aka cols)
        var max_chunks = n // chunk_size
        #print("GRID DIM", String(n), String(m))

        fn checkNeighbors(row: Int, col: Int) capturing -> Int:
            if lines[row][col] == '.':
                return 1337 # anything bigger than 4 suffices

            var count = 0
            for y in range(-1, 2): # row
                var yy = row + y
                if yy < 0 or yy >= n: # invalid row number
                    continue
                for x in range(-1, 2): # col
                    var xx = col + x
                    if xx == col and yy == row: # dont count ourself
                        continue
                    if xx < 0 or xx >= m: # invalid col number
                        continue
                    if lines[yy][xx] != '.':
                        count += 1
            return count

        var counts = List[Int](length = max_chunks, fill = 0)
        fn processChunk(i: Int) capturing:
            var start = i * chunk_size
            var end = start + chunk_size
            if i == max_chunks - 1:
                end += (n % chunk_size)
            for r in range(start, end):
                for c in range(m):
                    var count = checkNeighbors(r, c)
                    if count < MAGIC_NUMBER:
                        counts[i] += 1

        parallelize[processChunk](max_chunks, max_chunks)
        for i in range(len(counts)):
            accessible += counts[i]

        return String(accessible)

    fn partTwo(self, input_file: String) -> String:
        var lines = input_file.split("\n")
        var rows = len(lines)
        var cols = len(lines[0])

        var answer: sitype = 0
        var last_count = 1 # needs to be "truthy" to start
        
        var rt_shape = IndexList[2](rows, cols)
        var rt_stride = IndexList[2](cols, 1)
        var rt_layout = RuntimeLayout[temp_layout]()
        rt_layout.shape = rt_shape
        rt_layout.stride = rt_stride
        
        var unpadded = List[Byte](capacity = rows * cols)
        for char in input_file.as_bytes():
            if char == ord('\n'):
                continue
            unpadded.append(0 if char == ord('.') else 1)

        try:
            with DeviceContext() as ctx:
                var num_tile_rows = ceildiv(rows, tile_size)
                var num_tile_cols = ceildiv(cols, tile_size)
                #var dev_buf = host_tensor.to_device_buffer(ctx) # not sure why this wouldn't work
                var dev_buf = ctx.enqueue_create_buffer[DType.uint8](rows * cols)
                ctx.synchronize()

                var dev_tensor = LayoutTensor[DType.uint8, temp_layout](dev_buf, rt_layout)
                with dev_buf.map_to_host() as thost:
                    for row in range(rows):
                        for col in range(cols):
                            thost[row * cols + col] = unpadded[row * cols + col]

                var locations_to_zero = ctx.enqueue_create_buffer[itype](rows * cols)
                var compiled_kernel = ctx.compile_function_checked[partTwoKernel, partTwoKernel]()
                
                while last_count:
                    last_count = 0
                    locations_to_zero.enqueue_fill(0)
                    
                    ctx.enqueue_function_checked(compiled_kernel, dev_tensor, UInt(rows), UInt(cols), locations_to_zero, grid_dim = (num_tile_cols, num_tile_rows), block_dim = (tile_size, tile_size))
                    ctx.synchronize()

                    with locations_to_zero.map_to_host() as ltz:
                        with dev_buf.map_to_host() as grid:
                            for i in range(rows * cols):
                                if ltz[i]:
                                    last_count += 1
                                    #print(String(i // cols), String(i % cols), "set to zero")
                                    grid[i] = 0

                    answer += last_count
        except e:
            print(e)

        return String(answer)
