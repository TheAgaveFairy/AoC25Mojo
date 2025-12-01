from pathlib import Path
from builtin._location import __call_location
from sys import stderr

# sum types :()
comptime MODE_BOTH = "both"
comptime MODE_TEST = "test"
comptime MODE_FULL = "full"

comptime COLOR_RESET =  "\x1b[0m"
comptime COLOR_WHITE =  "\x1b[37"
comptime COLOR_GREEN =  "\x1b[32m"
comptime COLOR_RED =    "\x1b[31m"
comptime COLOR_YELLOW = "\x1b[33m"
comptime COLOR_PURPLE = "\x1b[35m"

fn coloredString(str: String, color: String = COLOR_YELLOW) -> String:
    return String(color + str + COLOR_RESET)

struct Result(Copyable & Movable & ImplicitlyCopyable):
    var day_str: String
    var mode: String
    var results: InlineArray[String, 2]

    fn __init__(out self, day_str: String, mode: String, part_one: String, part_two: String):
        self.day_str = day_str
        self.mode = mode
        self.results = InlineArray[String, 2](uninitialized = True)
        self.results[0] = part_one
        self.results[1] = part_two

    fn __str__(self) -> String:
        var header = coloredString("Day") + " " + self.day_str + \
            " " + coloredString("Mode: ") + self.mode

        var part_one = "Part One: " + coloredString(self.results[0], COLOR_PURPLE)
        var part_two = "Part Two: " + coloredString(self.results[1], COLOR_PURPLE)

        return header + "\n\t" + part_one + "\n\t" + part_two
    
    fn __copyinit_(self, other: Result):
        self.day_str = other.day_str
        self.mode = other.mode
        self.results = other.results
    
    fn __moveinit__(out self, deinit existing: Self):
        self.day_str = existing.day_str
        self.mode = existing.mode
        self.results = existing.results

trait Solution:
    @staticmethod
    @always_inline
    fn getDayString() -> String:
        var this_path = __call_location().file_name
        var this_filename = Path(this_path).name()
        var day_str = this_filename[3:5]
        return String(day_str) # longpath/day__.mojo

    fn run(self, mode: String) -> Result:
        #print(self.getDayString() + " running")
        try:
            var input_string = self.getFile(mode)
            var result = Result(self.getDayString(), mode, self.partOne(input_string), self.partTwo(input_string))
            return result
        except e:
            print(e, file = stderr)
            return Result(self.getDayString(), mode, "error", "error")

    fn getFile(self, mode: String) raises -> String:
        var filename = mode + self.getDayString() + ".txt"
        try:
            var file = open("../inputs/" + filename, "r")
            var contents = file.read()
            file.close()
            return contents
        except e:
            #print(e)
            raise Error("error getting input file: " + filename)
        
    # implement these two
    fn partOne(self, input_file: String) -> String: ...
    fn partTwo(self, input_file: String) -> String: ...
