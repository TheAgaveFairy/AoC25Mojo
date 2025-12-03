from sys import stderr
from solution import Solution
from sys.info import simd_byte_width, simd_width_of #, num_logical_cores
from utils.static_tuple import StaticTuple
from algorithm.functional import vectorize, parallelize

comptime nelts = 4 # hand-tune #simd_width_of[uint16]()

fn findMax(line: String) -> Int:
    var highest: Int = 0
    var idx = -1
    comptime guesstimate = (100 // nelts) + (100 % nelts) # lines are 100 long originally, could skip
    var highs = List[Byte](capacity = guesstimate) # gets one from each chunk


    var bytes = line.as_bytes().unsafe_ptr()

    fn getHighests[width: Int](i: Int) unified {mut}:
        var vec = bytes.load[width = width](i)
        var vec_highest = vec.reduce_max()
        highs.append(vec_highest)

    # don't check last element
    # its not useful if its bigger as it could only be in the ones position
    vectorize[nelts](len(line) - 1, getHighests)

    for i in range(len(highs)):
        highest = max(highest, Int(highs[i]))

    for i in range(len(line)):
        if bytes[i] == highest:
            idx = i
            break # only need the first one

    var tens = highest

    # clear things and check the rest of the line for the largest "ones" possible
    highest = 0
    highs.clear()
    bytes += idx + 1

    vectorize[nelts](len(line) - idx, getHighests)
    
    for i in range(len(highs)):
        highest = max(highest, Int(highs[i]))

    var ones = highest

    #print(line, chr(highest), String(chr(tens)), String(chr(ones)))
    return (tens - ord('0')) * 10 + (ones - ord('0'))

@fieldwise_init
struct Solution03(Solution):
    
    fn partOne(self, input_file: String) -> String:
        print("nelts", String(nelts))
        var lines = input_file.split("\n")
        var total = 0
        for line in lines:
            if not len(line):
                break
            var hi = findMax(String(line))
            total += hi

        return String(total)

    fn partTwo(self, input_file: String) -> String:
        return "0"
