from sys import stderr
from solution import Solution
from layout import Layout, LayoutTensor
from layout.runtime_layout import RuntimeLayout
from utils.index import IndexList
#from utils.static_tuple import StaticTuple
from math import sqrt

fn unsafeAtol(str: StringSlice) -> Int:
    var answer = 0
    for char in str.as_bytes():
        answer *= 10
        answer += Int(char) - ord('0')
    return answer

@fieldwise_init
struct Connection(Copyable, Movable):
    var distance: Playground.sftype
    var start: Int
    var end: Int

    fn __str__(self) -> String:
        try:
            return "{} -> {} = {}.".format(self.start, self.end, self.distance)
        except e:
            return String(e) # TODO : lazy choice

@fieldwise_init
struct Playground():
    # might want to move these comptimes to file-level scope?
    comptime ftype = DType.float32
    comptime sftype = Scalar[Self.ftype]
    comptime ranked_layout = Layout.row_major(0,0)
    var _boxes: List[Coordinate] # indexes will count as "IDs" # treat as FINAL
    var connections_storage: UnsafePointer[Self.sftype, MutAnyOrigin]
    var connections: LayoutTensor[Self.ftype, Self.ranked_layout, MutAnyOrigin]
    var n: Int

    fn __init__(out self, boxes: List[Coordinate]):
        print("here")
        var n = len(boxes)
        self.n = n
        var rt_shape = IndexList[2](n, n)
        var rt_stride = IndexList[2](n, 1)
        var rt_layout = RuntimeLayout[Self.ranked_layout]()
        rt_layout.shape = rt_shape
        rt_layout.stride = rt_stride

        self._boxes = boxes.copy() # is this bad practice to copy?
        self.connections_storage = alloc[Self.sftype](n * n)
        self.connections = type_of(self.connections)(self.connections_storage, rt_layout).fill(0.0)

        self._buildConnections()

    # lazy evaluation
    fn _buildConnections(self):
        for i, box_i in enumerate(self._boxes):
            for j, box_j in enumerate(self._boxes):
                var distance = box_i.distanceFrom(box_j)
                self.connections[i, j] = distance
                self.connections[j, i] = distance # or could make upper triangle, etc, but we have the storage already allocated
    
    fn findShortestConnection(self) -> Connection:
        var shortest: Self.sftype = FloatLiteral.infinity
        var start = -1
        var end = -1
        var i = 0
        for row in range(self.connections.dim(0)):
            for col in range(row, self.connections.dim(1)): # upper triangle only
                if row == col: # always 0
                    continue
                var dist = self.connections[row, col]
                #print(String(row), String(col), String(dist))
                if dist < shortest:
                    shortest = rebind[Self.sftype](dist)
                    start = row
                    end = col
        return Connection(shortest, start, end)

    fn wire(mut self, conn: Connection) -> Bool:
        var did_wire = False
        if self.connections[conn.start, conn.end] != FloatLiteral.infinity:
            self.connections[conn.start, conn.end] = FloatLiteral.infinity
            did_wire = True
        # could just do upper triangle, but we'll be thorough 
        if self.connections[conn.end, conn.start] != FloatLiteral.infinity:
            self.connections[conn.end, conn.start] = FloatLiteral.infinity
            did_wire = True
        return did_wire

    fn countCircuits(self) -> Int:
        # DFS
        var circuit_num = 1
        var seen = List[List[Int]](length = self.n, fill = List[Int](length = self.n, fill = 0))

        fn dfs(idx: Int) capturing:
            for c in range(self.n): # could check the corresponding row or col (if you dont just do an upper triangle)
                if self.connections[idx, c] == FloatLiteral.infinity:
                    if seen[idx][c] == 0:
                        seen[idx][c] = circuit_num
                        seen[c][idx] = circuit_num
                        #dfs(c)

        for row in range(self.n):
            for col in range(row, self.n): # upper triangle only needed
                if row == col: # maybe not strictly necessary
                    continue
                var conn = self.connections[row, col]
                print(String(row), String(col), String(conn), String(conn == FloatLiteral.infinity))
                if self.connections[row, col] == FloatLiteral.infinity:
                    if seen[row][col] == 0:
                        print("here")
                        dfs(row)
                        dfs(col)
                        circuit_num += 1
            for t in range(len(seen)):
                for _ in range(t):
                    print("_, ", end = "")
                for k in range(self.n - t):
                    print(String(seen[t][k + t]) + ", ", end = "")
                print()
                #print(seen_row[t:])
            print("\n\n\n")
        return circuit_num

    fn __deinit__(deinit self):
        self.connections_storage.free()

@fieldwise_init
struct Coordinate(Copyable, Movable, ImplicitlyCopyable, Writable, Representable):
    var x: Int
    var y: Int
    var z: Int

    @always_inline("nodebug")
    fn __init__(out self, line: StringSlice):
        var coords = line.split(',')
        var as_nums = [unsafeAtol(part) for part in coords]
        self.x = as_nums[0]
        self.y = as_nums[1]
        self.z = as_nums[2]

    fn distanceFrom(self, other: Self) -> Playground.sftype:
        # WHY DOES SQRT RETURN AN INT??
        var temp = Playground.sftype(pow(self.x - other.x, 2) + pow(self.y - other.y, 2) + pow(self.z - other.z, 2))
        return sqrt(temp) # ensure we get a Float back

    fn __str__(self) -> String:
        try:
            return "({},{},{})".format(self.x, self.y, self.z)
        except e:
            print(e)
            return "(error,,)"

    fn __repr__(self) -> String:
        return self.__str__()
    fn write_to(self, mut writer: Some[Writer]):
        writer.write_bytes(self.__str__().as_bytes())

@fieldwise_init
struct Solution08(Solution):
    
    fn partOne(self, input_file: String) -> String:
        var lines = input_file.split("\n")
        if not len(lines[-1]):
            _ = lines.pop()
        var m = len(lines)
        var boxes = List[Coordinate](capacity = m)
    
        for line in lines:
            boxes.append(Coordinate(line))

        var playground = Playground(boxes)
        #print(playground.connections, "\n\n")

        fn findAndWire() capturing:
            var shortest = playground.findShortestConnection()
            print(shortest.__str__(), playground._boxes[shortest.start], playground._boxes[shortest.end])
            print(String(playground.wire(shortest))) # returns if we actually needed to wire or not
        
        for _ in range(10):
            findAndWire()

        #print(playground.connections, "\n\n")
        print(String(playground.countCircuits()))
        return "0"

    fn partTwo(self, input_file: String) -> String:
        return "0"
