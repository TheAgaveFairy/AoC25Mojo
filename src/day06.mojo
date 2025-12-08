from sys import stderr
from solution import Solution

@always_inline("nodebug")
fn unsafeAtol(text: StringSlice) -> Int:
    var ans = 0
    for c in text.as_bytes():
        ans *= 10
        ans += Int(c) - ord('0')
    return ans

@always_inline("nodebug")
fn unsafeCtol(char: Byte) -> Int:
    return Int(char) - ord('0')

@fieldwise_init
struct CephCol(Copyable, Movable, Representable):
    var nums: List[Int]
    var op: String

    fn __init__(out self, digits: Int, op: Byte):
        self.nums = List[Int](length = digits, fill = 0)
        self.op = chr(Int(op))

    fn addNumFromStr(mut self, num_str: StringSlice):
        #var num_digits = len(num.strip()) # assert == len(self.nums)
        for i, byte in enumerate(num_str.as_bytes()):
            if byte != ord(' '):
                self.nums[i] *= 10
                self.nums[i] += unsafeCtol(byte)

    fn calculateTotal(self) -> Int:
        if self.op == "+":
            var total = 0
            for n in self.nums:
                total += n
            return total
        elif self.op == "*":
            var total = 1
            for n in self.nums:
                total *= n
            return total
        print("calculate col total err", file = stderr)
        return -1

    fn __str__(self) -> String:
        return "CC " + self.op + " " + String(self.nums)
    fn __repr__(self) -> String:
        return self.__str__()

@fieldwise_init
struct Solution06(Solution):
    
    fn partOne(self, input_file: String) -> String:
        var lines = input_file.split("\n")
        if not lines[-1]:
            _ = lines.pop()
        var ops = lines[-1].split()

        var seeds = lines[0].split()
        var num_cols = len(seeds)
        var column_totals = List[Int](length = num_cols, fill = 0)
        for i, seed in enumerate(seeds):
            column_totals[i] = unsafeAtol(seed)

        for line in lines[1:-1]:
            var parts = line.split()
            for i, p in enumerate(parts):
                var val = unsafeAtol(p)
                if ops[i] == "+":
                    column_totals[i] += val
                elif ops[i] == "*":
                    column_totals[i] *= val

        var ans = 0
        for ct in column_totals:
            ans += ct
        return String(ans)

    fn partTwo(self, input_file: String) -> String:
        var lines = input_file.split('\n')
        if not lines[-1]: # remove any empty lines at the end
            _ = lines.pop()
        var ops_row = lines.pop() # these cleanly demarcate the start of a new col

        var ceph_cols: List[CephCol] = []
        var col_widths: List[Int] = [] # easier / faster than iterating all len(ceph_col.nums)
        var ops_bytes = ops_row.as_bytes() # ascii encoded
        var i = 0
        while i < len(ops_bytes):
            var char = ops_bytes[i]
            # parse new CephCol out
            if char == ord('+') or char == ord('*'): # could skip this check
                var count = 1
                while ops_bytes[i + count] == ord(' ') or ops_bytes[i + count] == ord('\n'):
                    count += 1
                ceph_cols.append(CephCol(count - 1, char))
                col_widths.append(count - 1)
                i += count
            else:
                print("error parsing", String(i), char)
        
        # parse input
        for line in lines:
            i = 0 # reuse
            var col_idx = 0
            for cw in col_widths:
                var substr = line[i : i + cw]
                ceph_cols[col_idx].addNumFromStr(substr)
                i += cw + 1 # +1 to skip the ' ' between each col
                col_idx += 1
        #print(ceph_cols)
        
        var total = 0
        for cc in ceph_cols:
            total += cc.calculateTotal()

        return String(total)
