from sys import stderr
from solution import Solution

@fieldwise_init
struct Instruction(Copyable & Movable):
    comptime LEFT = "l"
    comptime RIGHT = "r"
    var direction: String
    var count: Int

    @staticmethod
    fn fromLine(line: String) raises -> Self:
        var direction = line[0].lower()
        if direction != Self.LEFT and direction != Self.RIGHT:
            raise Error("Direction parsing error: " + direction)
        
        try:
            var count = Int(line[1:])
            return Self(direction, count)
        except e:
            raise e

struct Lock():
    var pos: Int
    comptime size = 100

    fn __init__(out self):
        self.pos = 50

    fn runInstructions(mut self, instructions: List[Instruction], part: Int) -> Int:
        var answer = 0
        for instr in instructions:
            if part == 1:
                answer += self.spinOne(instr)
            elif part == 2:
                answer += self.spinTwo(instr)
        return answer

    fn spinOne(mut self, instr: Instruction) -> Int:
        if instr.direction == Instruction.RIGHT:
            self.pos = (self.pos + instr.count) % self.size
        else:
            self.pos = (self.pos + self.size - instr.count) % self.size
        return 1 if self.pos == 0 else 0

    fn spinTwo(mut self, instr: Instruction) -> Int:
        var old = self.pos
        if instr.direction == Instruction.RIGHT:
            self.pos = (self.pos + instr.count) % self.size
            var extra = instr.count // Self.size
            var zero_pass = 1 if self.pos < old else 0
            return zero_pass + extra
        else:
            self.pos = (self.pos + self.size - instr.count) % self.size
            var extra = instr.count // Self.size
            var zero_pass = 1 if self.pos > old else 0
            return zero_pass + extra

@fieldwise_init
struct Solution01(Solution):
    
    fn partOne(self, input_file: String) -> String:
        var lock = Lock()

        var lines = input_file.split()
        var instructions: List[Instruction] = []
        for line in lines:
            try:
                instructions.append(Instruction.fromLine(String(line)))
            except e:
                print(e)
                return "ERROR"

        var times_hit_zero = lock.runInstructions(instructions, 1)

        return String(times_hit_zero)

    fn partTwo(self, input_file: String) -> String:
        var lock = Lock()

        var lines = input_file.split()
        var instructions: List[Instruction] = []
        for line in lines:
            try:
                instructions.append(Instruction.fromLine(String(line)))
            except e:
                print(e)
                return "ERROR"

        var times_hit_zero = lock.runInstructions(instructions, 2)

        return String(times_hit_zero)