from enum import Enum


class StopRule(Enum):
    GENERATIONS = 0
    TARGET = 1
    MAXTIME = 2
    ITERATIONS = 3
    FEASIBILITY = 4

    @staticmethod
    def parse(value: str) -> 'StopRule':
        """
        Parse a string into a StopRule.
        G -> GENERATIONS
        T -> TARGET
        M -> MAXTIME
        I -> ITERATIONS
        F -> FEASIBILITY
        """
        local_value = value.strip().upper()[0]
        if local_value == 'G':
            return StopRule.GENERATIONS
        elif local_value == 'T':
            return StopRule.TARGET
        elif local_value == 'M':
            return StopRule.MAXTIME
        elif local_value == 'I':
            return StopRule.ITERATIONS
        elif local_value == 'F':
            return StopRule.FEASIBILITY
        else:
            raise ValueError(f"Cannot parse '{value}' as StopRule.")
