from pathlib import Path
from builtin._location import __call_location
from sys import stderr
from time import perf_counter_ns

# sum types :()
comptime MODE_BOTH = "both"
comptime MODE_TEST = "test"
comptime MODE_FULL = "full"

comptime COLOR_RESET =  "\x1b[0m"
comptime COLOR_WHITE =  "\x1b[37"
comptime COLOR_GREEN =  "\x1b[32m"
comptime COLOR_RED =    "\x1b[31m"
comptime COLOR_BLUE =   "\x1b[34m"
comptime COLOR_YELLOW = "\x1b[33m"
comptime COLOR_PURPLE = "\x1b[35m"

fn coloredString(str: String, color: String = COLOR_YELLOW) -> String:
    return String(color + str + COLOR_RESET)

@fieldwise_init
struct Result(Copyable & Movable & ImplicitlyCopyable):
    var results: String
    var time_ns: UInt

    comptime FAILURE = Self("error", 0)
    comptime UnitMS = "ms"
    comptime UnitUS = "us"
    comptime UnitNS = "ns"

    fn asFormattedString(self, unit: String = Self.UnitNS) -> String
        var base = "Result: " + coloredString(self.results, COLOR_PURPLE)
        var time = self.time_ns
        if unit == Result.UnitMS:
            time /= 1_000_000
        if unit == Result.UnitUS:
            time /= 1_000
        if unit == Result.UnitNS:
            continue
        var add_time = " took " + coloredString(String(time), COLOR_PURPLE) + " " + unit
        return base + add_time

    fn __str__(self) -> String:
        var base = "Result: " + coloredString(self.results, COLOR_PURPLE)
        var add_time = " took " + coloredString(String(self.time_ns // 1_000), COLOR_PURPLE) + " us"
        return base + add_time

struct DaySummary(Copyable & Movable & ImplicitlyCopyable):
    var day_str: String
    var mode: String
    var part_one: Result
    var part_two: Result

    fn __init__(out self, day_str: String, mode: String, part_one: Result, part_two: Result):
        self.day_str = day_str
        self.mode = mode
        self.part_one = part_one
        self.part_two = part_two

    fn __str__(self) -> String:
        var tab = "  "
        var header = coloredString("Day") + " " + self.day_str + \
            " " + coloredString("Mode: ") + self.mode
        
        var str_one = coloredString("Part One:\n" + (tab * 2), COLOR_BLUE) + self.part_one.__str__()
        var str_two = coloredString("Part Two:\n" + (tab * 2), COLOR_BLUE) + self.part_two.__str__()

        return header + "\n" + tab + str_one + "\n" + tab + str_two
    
    fn __copyinit_(self, other: Result):
        self.day_str = other.day_str
        self.mode = other.mode
        self.part_one = other.part_one
        self.part_two = other.part_two
    
    fn __moveinit__(out self, deinit existing: Self):
        self.day_str = existing.day_str
        self.mode = existing.mode
        self.part_one = existing.part_one
        self.part_two = existing.part_two

trait Solution:
    @staticmethod
    @always_inline
    fn getDayString() -> String:
        var this_path = __call_location().file_name
        var this_filename = Path(this_path).name()
        var day_str = this_filename[3:5]
        return String(day_str) # day__.mojo

    fn run(self, mode: String) -> DaySummary:
        #print(self.getDayString() + " running")
        try:
            var input_string = self.getFile(mode)

            var start_time = perf_counter_ns()
            var part_one = self.partOne(input_string)
            var mid_time = perf_counter_ns()
            var part_two = self.partTwo(input_string)
            var end_time = perf_counter_ns()
            
            var elapsed_one = mid_time - start_time
            var elapsed_two = end_time - mid_time

            var result_one = Result(part_one, elapsed_one)
            var result_two = Result(part_two, elapsed_two)
            
            var day_summary = DaySummary(self.getDayString(), mode, result_one, result_two)
            return day_summary

        except e: # TODO: error handle each part individually
            print(e, file = stderr)
            var part_one = Result.FAILURE
            var part_two = Result.FAILURE
            return DaySummary(self.getDayString(), mode, part_one, part_two)

    fn getFile(self, mode: String) raises -> String:
        var filename = mode + self.getDayString() + ".txt"
        try:
            var file = open("../inputs/" + filename, "r")
            var contents = file.read()
            file.close()
            return contents
        except e:
            #print(e)
            var err_str = coloredString("error getting input file: " + filename, COLOR_RED)
            raise Error(err_str)
        
    # implement these two
    fn partOne(self, input_file: String) -> String: ...
    fn partTwo(self, input_file: String) -> String: ...
