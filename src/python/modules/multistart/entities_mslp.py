from dataclasses import dataclass
from gurobipy import Env

from modules.solutions import Solution
from modules.parameters import ParameterData
from modules.enumerations import StopRule

@dataclass
class StopParams:
    rule: StopRule
    argument: float
    maximum_time: int


@dataclass
class AllParams:
    general: ParameterData
    stop: StopParams


@dataclass
class ExternalMSLPData:
    best_sol: Solution = None
    curr_sol: Solution = None
    last_semi_greedy_sol: Solution = None

    env: Env = None
    start_time: float = 0.0
    iteration: int = 0

    time_to_best: float = 0.0
    iteration_to_best: int = 0
    largest_update_offset: int = 0

    lp_runs: int = 0
    lp_impr: int = 0
    sum_lp_impr_percentage: float = 0.0
    infeasible_sol: int = 0
    total_time_elapsed: float = 0.0
    percentage_infeasible_sol: float = 0.0
    percentage_lp_impr: float = 0.0
    mean_lp_impr_percentage: float = 0.0


def load_stop_params(params: ParameterData) -> StopParams:
    stop_rule = StopRule.parse(params.mslp_r)
    if stop_rule == StopRule.TARGET:
        stop_argument = float(params.mslp_a)
    else:
        stop_argument = int(params.mslp_a)

    maximum_time = params.max_time
    if maximum_time <= 0:
        raise ValueError(f"Maximum time must be larger than 0.0. Given {maximum_time}.")

    return StopParams(stop_rule, stop_argument, maximum_time)
