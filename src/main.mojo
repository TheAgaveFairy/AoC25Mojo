import sys # argv, stderr

from solution import Solution, Result, DaySummary#, MODE_BOTH, MODE_TEST, MODE_FULL
from aocparser import AoCParser, ModeEnum
import day01, day02, day03, day04, day05, day06, day07, day08, day09, day10, day11, day12

fn runSoln(day: Int, mode: String) -> DaySummary:
    """
    No pattern matching yet. If day == 0, run all.
    """
        if day == 0 or day == 1:
            var soln = day01.Solution01()
            return soln.run(mode)
        if day == 0 or day == 2:
            var soln = day02.Solution02()
            return soln.run(mode)
        if day == 0 or day == 3:
            var soln = day03.Solution03()
            return soln.run(mode)
        if day == 0 or day == 4:
            var soln = day04.Solution04()
            return soln.run(mode)
        if day == 0 or day == 5:
            var soln = day05.Solution05()
            return soln.run(mode)
        if day == 0 or day == 6:
            var soln = day06.Solution06()
            return soln.run(mode)
        if day == 0 or day == 7:
            var soln = day07.Solution07()
            return soln.run(mode)
        if day == 0 or day == 8:
            var soln = day08.Solution08()
            return soln.run(mode)
        if day == 0 or day == 9:
            var soln = day09.Solution09()
            return soln.run(mode)
        if day == 0 or day == 10:
            var soln = day10.Solution10()
            return soln.run(mode)
        if day == 0 or day == 11:
            var soln = day11.Solution11()
            return soln.run(mode)
        if day == 0 or day == 12:
            var soln = day12.Solution12()
            return soln.run(mode)
        else: # could raise instead
            return DaySummary("-1", "FAILURE", Result.FAILURE, Result.FAILURE)

fn run(days: List[Int], mode: String) -> List[DaySummary]:
    var results: List[DaySummary] = []
    
    for day in days:

        if mode == ModeEnum.BOTH:
            results.append(runSoln(day, ModeEnum.TEST))
            results.append(runSoln(day, ModeEnum.FULL))
        elif mode == ModeEnum.TEST:
            results.append(runSoln(day, ModeEnum.TEST))
        else:
            results.append(runSoln(day, ModeEnum.FULL))

    return results.copy()

fn main():
    _ = """
    var args = sys.argv()
    var argc = len(args)
    var days: List[Int] = materialize[ALL_DAYS]()
    var mode = MODE_FULL

    if argc > 1:
        if args[1] == "--help":
            print("./main -d -m, -d is the day[s] you want (separated by commas e.g. 1,2,3), and the mode is either 'test' or 'full' or 'both'")
            return
        else:    
            days = parseDays(args[1])
        if argc > 2:
            mode = String(args[2]).lower()
    """
    var parser = AoCParser()
    if parser.had_error:
        print("Errors detected, aborting.", file = sys.stderr)
        return

    # TODO : implement custom filename handling and runs
    var summaries = run(parser.days, parser.mode)

    for summary in summaries:
        print(summary.__str__())
