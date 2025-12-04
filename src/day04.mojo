from sys import stderr
from solution import Solution
from algorithm.functional import vectorize, parallelize

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
        return "0"
