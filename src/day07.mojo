from sys import stderr
from solution import Solution
from cli import CLIParser

comptime SPLIT = ord('^')

@fieldwise_init
struct Solution07(Solution):
    
    fn partOne(self, input_file: String) -> String:
        var lines = input_file.split("\n")
        if not len(lines[-1]):
            _ = lines.pop()

        #var m = len(lines)
        var n = len(lines[0])

        var state = List[Int](length = n, fill = 0)

        for i, char in enumerate(lines[0].as_bytes()):
            if Int(char) == ord('S'):
                state[i] = 1
                break
        #print(state)

        var splits = 0
        for line in lines[1:]:
            for i, char in enumerate(line.as_bytes()):
                if Int(char) == SPLIT:
                    if state[i] > 0:
                        splits += 1
                        state[i - 1] = 1#state[i] + 1
                        state[i + 1] = 1#state[i] + 1
                        state[i] = 0
                #print(line, state)
        return String(splits)

    fn partTwo(self, input_file: String) -> String:
        #var parser = CLIParser()
        var lines = input_file.split("\n")
        if not len(lines[-1]):
            _ = lines.pop()

        #var m = len(lines)
        var n = len(lines[0])

        var state = List[Int](length = n, fill = 0)

        for i, char in enumerate(lines[0].as_bytes()):
            if Int(char) == ord('S'):
                state[i] = 1
                break

        var splits = 0
        for line in lines[2::2]:
            for i, char in enumerate(line.as_bytes()):
                if Int(char) == SPLIT:
                    if state[i] > 0:
                        state[i - 1] = state[i] + state[i - 1] #+ 1
                        state[i + 1] = state[i] + state[i + 1] #+ 1
                        state[i] = 0
            #print(line, state)
        for s in state:
            splits += s
        return String(splits)
