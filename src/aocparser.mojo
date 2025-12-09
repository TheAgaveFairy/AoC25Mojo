from sys import stderr, argv
from subprocess import run as subprocessRun

@fieldwise_init
struct ModeEnum():
    comptime TEST = "test"
    comptime FULL = "full"
    comptime BOTH = "both"

struct AoCParser(Copyable, Movable, ImplicitlyCopyable, Writable, Representable):
    comptime FLAG_HELP = "--help"
    comptime FLAG_HELP_SHORT = Self.FLAG_HELP[1:3] # -h
    comptime FLAG_MODE = "--mode"
    comptime FLAG_MODE_SHORT = Self.FLAG_MODE[1:3] # -m
    comptime FLAG_FILENAME = "--filename"
    comptime FLAG_FILENAME_SHORT = Self.FLAG_FILENAME[1:3] # -f
    comptime FLAG_DAYS = "--days"
    comptime FLAG_DAYS_SHORT = Self.FLAG_DAYS[1:3] # -d
    comptime FLAG_RUNS = "--runs"
    comptime FLAG_RUNS_SHORT = Self.FLAG_RUNS[1:3] # -r

    comptime ALL_DAYS = [1,2,3,4,5,6,7,8,9,10,11,12]

    var days: List[Int]
    var mode: String # enums next year
    var filename: Optional[String] # for a file without the standard name
    var runs: Int # for benchmarking # TODO
    var had_error: Bool

    fn __init__(out self):
        var args = argv()
        # defaults
        self.mode = ModeEnum.FULL
        self.filename = type_of(self.filename)(None)
        self.runs = 1
        self.had_error = False
        try:
            self.days = Self._defaultDays()
        except e:
            print("default days error:", e, file = stderr)
            self.days = materialize[Self.ALL_DAYS]()
            self.had_error = True

        var i = 1 # skip argv[0] / program name
        while i < len(args):
            arg = args[i]
            if arg == materialize[Self.FLAG_HELP]() or arg == materialize[Self.FLAG_HELP_SHORT]():
                Self.printHelp()
                break
            elif arg == materialize[Self.FLAG_MODE]() or arg == materialize[Self.FLAG_MODE_SHORT]():
                self._parseMode(args[i + 1])
                i += 2 # consume
            elif arg == materialize[Self.FLAG_FILENAME]() or arg == materialize[Self.FLAG_FILENAME_SHORT]():
                self._parseFilename(args[i + 1])
                i += 2
            elif arg == materialize[Self.FLAG_DAYS]() or arg == materialize[Self.FLAG_DAYS_SHORT]():
                self._parseDays(args[i + 1])
                i += 2
            elif arg == materialize[Self.FLAG_RUNS]() or arg == materialize[Self.FLAG_RUNS_SHORT]():
                self._parseRuns(args[i + 1])
                i += 2
            else:
                print("unknown flag: " + arg, file = stderr)
                i += 1
                self.had_error = True

    #fn _match[o: ImmutOrigin](self, arg: StringSlice, *flags: List[StringSlice[mut = False, o]]) -> Bool:
    #    for flag in flags:
    #        if arg == materialize[flag]():
    #            return True
    #    return False
    
    @staticmethod
    fn printHelp():
        var help_str = "Usage: main [OPTIONS]...\n" + \
                "\t-m, --mode MODE\tMODE is 'full', 'test', or 'both'. case-insensitive. default = 'full'\n" + \
                "\t-f, --filename FILENAME\ta custom input file for use with a single day. default = None and uses 'mode' implication\n" + \
                "\t-d, --days DAYS\twhere DAYS is csv. e.g. '1', '1,2,3', '7,6,9'. defaults to AoC schedule using 'date' during event or all days otherwise\n" + \
                "\t-r, --runs RUNS\tthe number of runs to run for benchmarking. default = 1.\n" + \
                "\n\tEXAMPLE: 'main -m both -d 7,8 -r 100' would run both test and full inputs for days 7 and 8 100 times each (400 total runs)"
        print(help_str)


    fn _parseMode(mut self, mode: StringSlice):
        var mode_lower = mode.lower()
        if mode_lower == ModeEnum.TEST:
            self.mode = ModeEnum.TEST
        elif mode_lower == ModeEnum.FULL:
            self.mode = ModeEnum.FULL
        elif mode_lower == ModeEnum.BOTH:
            self.mode = ModeEnum.BOTH
        else:
            print("invalid 'mode' arg:" + mode, file = stderr)
            self.had_error = True
            self.mode = ModeEnum.FULL
            
    fn _parseFilename(mut self, filename: StringSlice):
        if filename[:2] == "--":
            print("please include the filename", file = stderr)
            self.had_error = True
        else:
            self.filename = String(filename)

    fn _parseDays(mut self, days_str: StringSlice):
        var days_strs = days_str.split(",")
        self.days.clear()
        for day_str in days_strs:
            try:
                if day_str:
                    var day_int = Int(day_str)
                    if day_int < 1 or day_int > 12:
                        print("day out of range:", day_str, file = stderr)
                        self.had_error = True
                    self.days.append(day_int)
            except e:
                self.had_error = True
                print("day parsing error", e, file = stderr)

    fn _parseRuns(mut self, runs_str: StringSlice):
        try:
            self.runs = Int(runs_str)
        except e:
            print(e, file = stderr)
            self.had_error = True

    @staticmethod
    fn _defaultDays() raises -> List[Int]:
        var default_days = materialize[Self.ALL_DAYS]()
        try:
            var datetime = subprocessRun("TZ=\"America/New_York\" date +'%d %Y'")
            #print(datetime)
            var parts = datetime.split()
            var day = Int(parts[0])
            var year = parts[1]

            if year == "2025":
                if day < 12:
                    default_days.clear()
                    for i in range(1, day + 1):
                        default_days.append(i)
        except e:
            raise e
        return default_days^

    fn __copyinit__(out self, other: Self):
        self.days = other.days.copy()
        self.mode = other.mode
        self.filename = other.filename
        self.runs = other.runs
        self.had_error = other.had_error

    fn __moveinit__(out self, deinit existing: Self):
        self.days = existing.days^
        self.mode = existing.mode^
        self.filename = existing.filename^
        self.runs = existing.runs
        self.had_error = existing.had_error

    fn __str__(self) -> String:
        return "CLIParser:" + \
                "\nDays: " + String(self.days) + \
                "\nMode: " + self.mode + \
                "\nFilename: " + String(self.filename) + \
                "\nRuns: " + String(self.runs) + \
                "\nHad Error: " + String(self.had_error)
    fn __repr__(self) -> String:
        return self.__str__()
    fn write_to(self, mut writer: Some[Writer]):
        writer.write_bytes(self.__str__().as_bytes())

fn main():
    var parser = CLIParser()
    print(parser)
