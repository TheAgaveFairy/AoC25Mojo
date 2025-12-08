from sys import stderr, argv

struct CLIParser(Copyable, Movable, ImplicitlyCopyable, Writable, Representable):
    comptime FLAG_MODE = "--mode"
    comptime FLAG_MODE_SHORT = Self.FLAG_MODE[1:3] # -m
    comptime FLAG_FILENAME = "--filename"
    comptime FLAG_FILENAME_SHORT = Self.FLAG_FILENAME[1:3] # -f
    comptime FLAG_DAYS = "--days"
    comptime FLAG_DAYS_SHORT = Self.FLAG_DAYS[1:3] # -d

    comptime ALL_DAYS = [1,2,3,4,5,6,7,8,9,10,11,12]

    var args: List[String] # don't really need an extra copy
    var days: List[Int]
    var mode: String # enums next year
    var filename: Optional[String] # for a file without the standard name

    fn __init__(out self):
        for arg in argv():
            print(arg)
        self.args = []
        self.days = []
        self.mode = "both"
        self.filename = None

    fn __copyinit__(out self, other: Self):
        self.args = other.args.copy()
        self.days = other.days.copy()
        self.mode = other.mode
        self.filename = other.filename

    fn __moveinit__(out self, deinit existing: Self):
        self.args = existing.args^
        self.days = existing.days^
        self.mode = existing.mode^
        self.filename = existing.filename^

    fn __str__(self) -> String:
        return "__str__"
    fn __repr__(self) -> String:
        return self.__str__()
    fn write_to(self, mut writer: Some[Writer]):
        writer.write_bytes(self.__str__().as_bytes())

fn main():
    # test
    var args = argv()

    var parser = CLIParser()
