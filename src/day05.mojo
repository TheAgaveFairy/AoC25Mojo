from sys import stderr
from solution import Solution
from algorithm.functional import vectorize, parallelize
from collections import Set

@fieldwise_init 
struct MyRange(Copyable & Movable & Writable & Representable & Comparable):
    # Excuse to implement some new traits!
    var lower: Int
    var upper: Int

    fn countValid(self) -> Int:
        var n = self.upper - self.lower + 1
        #var ans = (n * (n + 1)) // 2
        #print(self, String(ans))
        return n

    fn __str__(self) -> String:
        return String(self.lower) + "->" + String(self.upper)

    fn __repr__(self) -> String:
        return self.__str__()

    fn write_to(self, mut writer: Some[Writer]):
        writer.write_bytes(self.__str__().as_bytes())

    fn __contains__(self, num: Int) -> Bool:
        return num >= self.lower and num <= self.upper

    fn __lt__(self, rhs: Self) -> Bool:
        return self.lower < rhs.lower

    fn __eq__(self, rhs: Self) -> Bool:
        return self.lower == rhs.lower

@fieldwise_init
struct Kitchen(ImplicitlyCopyable):
    var ranges: List[MyRange]
    var ids: List[Int]

    fn mergeIntervals(self):
        var merged: List[MyRange] = []
        self.ranges = sorted(self.ranges, key = lambda x: x.lower)
        print(self.ranges)

    fn __init__[o: ImmutOrigin](out self, input_file: StringSlice[o], skip_ids: Bool = False):
        var lines = input_file.split("\n")
        self.ranges: List[MyRange] = []
        self.ids: List[Int] = []
        for line in lines:
            try:
                if line and '-' in line:
                    var parts = line.split('-')
                    var lower = Int(parts[0])
                    var upper = Int(parts[1])
                    self.ranges.append(MyRange(lower, upper))
                elif line:
                    if skip_ids:
                        break
                    self.ids.append(Int(line))
            except e:
                print(e)

    fn __copyinit__(out self, existing: Self):
        self.ranges = existing.ranges.copy()
        self.ids = existing.ids.copy()

@fieldwise_init
struct Solution05(Solution):
    
    fn partOne(self, input_file: String) -> String:
        var kitchen = Kitchen(input_file)
        var num_prods = len(kitchen.ids)
        var results = List[Bool](length = num_prods, fill = False)
        fn inRanges(i: Int) capturing:
            for r in kitchen.ranges:
                if kitchen.ids[i] in r:
                    results[i] = True
        parallelize[inRanges](num_prods, 12)

        var ans = 0
        for b in results:
            if b:
                ans += 1
        return String(ans)

    fn partTwo(self, input_file: String) -> String:
        var lines = input_file.split("\n")
        var ranges: List[MyRange] = []
        for line in lines:
            try:
                if line and '-' in line:
                    var parts = line.split('-')
                    var lower = Int(parts[0])
                    var upper = Int(parts[1])
                    ranges.append(MyRange(lower, upper))
                else:
                    break
            except e:
                print(e)

        sort(ranges)

        var merged: List[MyRange] = []
        for r in ranges:
            if not merged or merged[-1].upper < r.lower:
                merged.append(r.copy())
            else:
                merged[-1].upper = max(merged[-1].upper, r.upper)
        var count = 0
        for m in merged:
            count += m.countValid()
        return String(count)
