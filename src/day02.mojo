from solution import Solution
from algorithm.functional import parallelize #, vectorize

@fieldwise_init
struct ProductIDRange(Copyable & Movable & ImplicitlyCopyable):
    var start: Int
    var end: Int

    fn __str__(self) -> String:
        return String(self.start) + "->" + String(self.end)

    fn getInvalidsOne(self) -> Int:
        var total: Int = 0

        for pid in range(self.start, self.end + 1):
            var s = String(pid)
            if len(s) % 2 == 1 or s[0] == '0': # TODO: check on the meaning of that second case
                continue

            var half = len(s) // 2
            var left = s[:half]
            var right = s[half:]
            if left == right:
                #print("Invalid!", s)
                total += pid
            
        return total

    fn getInvalidsTwo(self) -> Int:
        var total: Int = 0

        for pid in range(self.start, self.end + 1):
            var s = String(pid)
            #if len(s) % 2 == 1 or s[0] == '0': # TODO: check on the meaning of that second case
                #continue

            # closure gives better control flow with early returns
            fn isInvalidHelper() -> Bool:
                var n = len(s)
                var half = n // 2
                # check all prefix substrings
                # i.e. "123123" -> "1", "12", "123"
                for i in range(1, half + 1): # i = len of substr prefix
                    if n % i != 0:
                        continue

                    var substr = s[:i]
                    var invalid = True
                    #print("\nsearching for", substr, "in", s, end = ":\n\t")
                    # check all next patterns
                    for ii in range(i, n, i):
                        #print(s[ii:ii+i], "?", end = " ")
                        if s[ii:ii+i] != substr:
                            invalid = False
                            break
                    if invalid:
                        #print("\n\t****************invalid!", s)
                        return True
                # default
                return False

            if isInvalidHelper():
                total += pid
            
        return total

fn parseInput(input_file: String) raises -> List[ProductIDRange]:
    var pid_ranges: List[ProductIDRange] = []
    var pid_strs = input_file.split(',')

    for pr in pid_strs:
        var parts = pr.split('-')
        try:
            var start = Int(parts[0])
            var end = Int(parts[1])
            var pid_range = ProductIDRange(start, end)
            pid_ranges.append(pid_range)
        except e:
            raise e

    return pid_ranges.copy()

fn parallelSum[part_one: Bool](pid_ranges: List[ProductIDRange]) -> Int:
    var n = len(pid_ranges)
    var totals = List[Int](capacity = n)
    
    @parameter
    fn parallel_closure(tid: Int):
        #print("running", tid, pid_ranges[tid].__str__())
        @parameter
        if part_one:
            totals[tid] = pid_ranges[tid].getInvalidsOne()
        else:
            totals[tid] = pid_ranges[tid].getInvalidsTwo()
    parallelize[parallel_closure](n)

    var total = 0
    for i in range(n):
        var t = totals[i]
        #print(String(t))
        total += t
    return total

@fieldwise_init
struct Solution02(Solution):
    
    fn partOne(self, input_file: String) -> String:
        try:
            var pid_ranges = parseInput(input_file)
            var total = parallelSum[True](pid_ranges)
            return String(total)
        except e:
            return String(e)

    fn partTwo(self, input_file: String) -> String:
        try:
            var pid_ranges = parseInput(input_file) # raises
            var total = parallelSum[False](pid_ranges)
            return String(total)
        except e:
            return String(e)

