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

fn findMaxOne[origin: ImmutOrigin](line: StringSlice[origin]) -> Int:
    var tens = 0
    var ones = 0

    comptime ord_zero = ord('0')

    @always_inline
    fn charToInt(char: Byte) -> Int: # unsafe and fast :)
        return Int(char) - ord('0')

    var bytes = line.as_bytes()

    for i in range(len(line) - 1):
        var j = charToInt(bytes[i])
        if j > tens:
            tens = j
            ones = 0
        elif j > ones:
            ones = j

    ones = max(ones, charToInt(bytes[-1]))
    return tens * 10 + ones

@deprecated # slow, complicated
fn findMaxOneVectorized(line: String) -> Int:
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

fn findMaxTwo[origin: ImmutOrigin](line: StringSlice[origin]) -> Int:
    var highest: Int = 0 # actually logically holds an ascii "Byte", but Int type means less casting
    var idx = 0 # keeps track of how far down we are from the start
    var highs = List[Byte](capacity = guesstimate)
    var total: Int = 0 # out arg

    comptime num_batteries = 12

    var bytes_start = line.as_bytes().unsafe_ptr()
    var bytes = bytes_start

    # extracts local maxes in a window of width "nelts" using SIMD
    fn getHighests[width: Int](i: Int) unified {mut}:
        var vec = bytes.load[width = width](i)
        var vec_highest = vec.reduce_max()
        highs.append(vec_highest)

    # loop to extract max valid digit iteratively => O( num_batteries * len(line))
    for d in range(num_batteries,0,-1):
        total *= 10
        # need to start at the right place and leave the last "d - 1" digits unsearched
        var num_elems_to_check = len(line) - (d - 1) - idx

        # generate list of local maxes using SIMD for speed
        vectorize[nelts](num_elems_to_check, getHighests)
        
        # get the global max from the list of local maxes
        for i in range(len(highs)):
            highest = max(highest, Int(highs[i]))

        for i in range(num_elems_to_check):
            if bytes[i] == highest:
                idx += i + 1
                break # greedy
        
        total += (highest - ord('0'))
        
        highs.clear()
        highest = 0
        bytes = bytes_start.offset(idx)

    return total

@fieldwise_init
struct Solution03(Solution):
    
    fn partOne(self, input_file: String) -> String:
        #print("nelts", String(nelts)) # parallelizing, vectorizing, all were slower than iterative
        var lines = input_file.split("\n")
        var total = 0
        for line in lines:
            if not len(line):
                break
            var hi = findMaxOne(line)
            total += hi
        return String(total)

    fn partTwo(self, input_file: String) -> String:
        var lines = input_file.split("\n")
        var total = 0
        for line in lines:
            if not len(line):
                break
            var hi = findMaxTwo(line)
            total += hi

        return String(total)
