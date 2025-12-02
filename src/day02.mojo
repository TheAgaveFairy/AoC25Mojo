from solution import Solution

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
            if len(s) % 2 == 1 or s[0] == '0': # TODO: check on the meaning of that second case
                continue

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
                    print("\nsearching for", substr, "in", s, end = ":\n\t")
                    # check all next patterns
                    for ii in range(i, n, i):
                        print(s[ii:ii+i], "?", end = " ")
                        if s[ii:ii+i] != substr:
                            invalid = False
                            break
                    if invalid:
                        print("\n\t****************invalid!", s)
                        return True # True
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

@fieldwise_init
struct Solution02(Solution):
    
    fn partOne(self, input_file: String) -> String:
        var pid_strs = input_file.split(',')

        var total: Int = 0
        for pr in pid_strs:
            var parts = pr.split('-')
            try:
                var start = Int(parts[0])
                var end = Int(parts[1])
                var pid_range = ProductIDRange(start, end)
                var invalids_sum = pid_range.getInvalidsOne()
                #print(pid_range.__str__())
                total += invalids_sum
            except e:
                return String(e)

        return String(total)

    fn partTwo(self, input_file: String) -> String:
        var total: Int = 0
        try:
            var pid_ranges = parseInput(input_file) # raises
            for pr in pid_ranges:
                total += pr.getInvalidsTwo()
        except e:
            return String(e)


        return String(total)
