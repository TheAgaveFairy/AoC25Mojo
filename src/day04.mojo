from sys import stderr
from solution import Solution
from algorithm.functional import vectorize, parallelize

from gpu.host import DeviceContext, DeviceFunction, DeviceBuffer#, HostBuffer
from gpu import thread_idx, block_idx, block_dim, grid_dim, barrier
from gpu.memory import AddressSpace
from layout import Layout, LayoutTensor
from layout.runtime_layout import RuntimeLayout
from layout.runtime_tuple import RuntimeTuple
from utils.index import IndexList

comptime temp_layout = Layout.row_major(0,0) # gives it rank

fn partTwoKernel(grid: LayoutTensor[DType.uint8, temp_layout], rt_layout: RuntimeLayout, answer_out: DeviceBuffer[DType.int64]) -> None:
    var rows = rt_layout.shape[0]
    var cols = rt_layout.shape[1]
    var chunk_idx = block_idx.x
    var row_idx = thread_idx.x # 137 137
    var rows_per_chunk = block_dim.x
    var num_chunks = grid_dim.x

    var num_rows = rows // num_chunks # num rows *for this chunk
    #    num_rows += rows % num_chunks

    var start_row = chunk_idx * rows_per_chunk
    var end_row = start_row + num_rows

    var start = start_row * cols
    var end = end_row * cols + cols
    var local_text = LayoutTensor[DType.uint8, temp_layout, address_space = AddressSpace.SHARED](rt_layout).stack_allocation()

    for col_idx in range(cols):
        local_text[row_idx, col_idx] = grid[row_idx, col_idx]#[start + (row_idx * cols) + col_idx]
        if chunk_idx == num_chunks - 1:
            local_text[row_idx + 1, col_idx] = grid[row_idx + 1, col_idx]#[start + ((row_idx + 1) * cols) + col_idx]

    for col_idx in range(cols):
        print(local_text[row_idx, col_idx], end="")
    if chunk_idx == num_chunks - 1:
        for col_idx in range(cols):
            print(local_text[row_idx + 1, col_idx], end = "")

    answer_out = 69

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
                    #print("row, col", String(row), String(col), "spot", String(yy), String(xx))
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
                    if count < 4:
                        #print("Accessible:", String(r), String(c), "count", String(count))
                        #lines[r][c] = "x" # DEBUG
                        counts[i] += 1

        parallelize[processChunk](max_chunks, max_chunks)
        for i in range(len(counts)):
            accessible += counts[i]

        return String(accessible)

    fn partTwo(self, input_file: String) -> String:
        var lines = input_file.split("\n")
        var rows = len(lines)
        var cols = len(lines[0])
        var answer: Int64 = 0
        
        var rt_shape = IndexList[2](rows, cols)
        var rt_stride = IndexList[2](cols, 1)
        var rt_layout = RuntimeLayout[temp_layout]()
        rt_layout.shape = rt_shape
        rt_layout.stride = rt_stride

        var host_tensor = LayoutTensor[DType.uint8, temp_layout](input_file.unsafe_ptr())
        print("2,2", host_tensor[2, 2])
        try:
            with DeviceContext() as ctx:
                var dev_buf = host_tensor.to_device_buffer(ctx)#ctx.enqueue_create_buffer[DType.uint8](rows * cols)
                ctx.synchronize()

                var dev_tensor = LayoutTensor[DType.uint8, temp_layout](dev_buf, rt_layout)
                with dev_buf.map_to_host() as host:
                    for row in range(rows):
                        for col in range(cols):
                            print(String(chr(Int(host[row * cols + col]))))
                            host[row * cols + col] = ord(lines[row][col])

                var final_count = ctx.enqueue_create_buffer[DType.int64](1)

                comptime num_chunks = 3
                var rows_per_chunk = rows // num_chunks

                #var compiled_func = ctx.compile_function_checked[partTwoKernel
                ctx.enqueue_function_unchecked[partTwoKernel](dev_tensor, rows, cols, final_count, grid_dim = num_chunks, block_dim = rows_per_chunk)
                ctx.synchronize()

                with final_count.map_to_host() as ans:
                    answer = ans[0]
        except e:
            print(e)

        return String(answer)
