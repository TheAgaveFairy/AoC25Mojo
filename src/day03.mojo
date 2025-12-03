from sys import stderr
from solution import Solution
from sys.info import simd_byte_width, simd_width_of #, num_logical_cores
from utils.static_tuple import StaticTuple
from algorithm.functional import vectorize, parallelize

comptime nelts = 16 # hand-tune #simd_width_of[Byte]() is 64 = too big for "short" lines!
comptime guesstimate = (100 // nelts) + (100 % nelts) # lines are 100 long originally, could skip

@always_inline
fn byteToString(byte: Byte) -> String:
    return String(chr(Int(byte)))

fn findMax(line: String) -> Int:
    var highest: Int = 0
    var idx = -1
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

fn findMaxTwo(line: String) -> Int:
    var highest: Int = 0 # actually an ascii "Byte", but Int type means less casting
    var idx = 0 # keeps track of how far down we are for each digit
    var highs = List[Byte](capacity = guesstimate) # gets one from each nelts chunk
    var total: Int = 0 # out arg

    comptime num_batteries = 12

    var bytes_start = line.as_bytes().unsafe_ptr()
    var bytes = bytes_start

    fn getHighests[width: Int](i: Int) unified {mut}:
        var vec = bytes.load[width = width](i)
        var vec_highest = vec.reduce_max()
        highs.append(vec_highest)

    _ = """
    # print the buffer im searching, leaving in for sharing / learning / debugging
    fn getFakeSlice(d: Int) capturing -> String:
        var result = ""
        #print("\tslice elems idx", String(d), String(idx))
        for i in range(d):
            result += byteToString(bytes[i]) + ", "
        return result
    """

    # loop to extract max valid digit iteratively => O( num_batteries * len(line)) => linear time
    for d in range(num_batteries,0,-1):
        total *= 10
        var num_elems_to_check = len(line) - (d - 1) - idx

        # generate list of local maxes using SIMD for speed
        vectorize[nelts](num_elems_to_check, getHighests)
        
        # get the global max from the list of local maxes
        for i in range(len(highs)):
            highest = max(highest, Int(highs[i]))

        for i in range(num_elems_to_check):
            # greedy
            if bytes[i] == highest:
                idx += i + 1
                break # only need the first one
        
        total += (highest - ord('0'))
        
        highs.clear()
        highest = 0
        bytes = bytes_start.offset(idx) # possibly i should use UnsafePointer's "offset()" method
    return total

@fieldwise_init
struct Solution03(Solution):
    
    fn partOne(self, input_file: String) -> String:
        #print("nelts", String(nelts))
        var lines = input_file.split("\n")
        var total = 0
        for line in lines:
            if not len(line):
                break
            var hi = findMax(String(line))
            total += hi

        return String(total)

    fn partTwo(self, input_file: String) -> String:
        var lines = input_file.split("\n")
        var total = 0
        for line in lines:
            if not len(line):
                break
            var hi = findMaxTwo(String(line))
            total += hi

        return String(total)
