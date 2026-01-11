import math
from typing import List

from modules.parameters import ParameterData
from .entities_greedy_heur import InsertionData


def choose_candidate(
    cand_list: List[InsertionData], params: ParameterData
) -> InsertionData:
    """
    cand_list: list of InsertionData objects
    params: object with attributes `alpha` (float) and `rng` (random.Random or compatible)
    """

    if len(cand_list) == 0:
        # Return an 'empty' InsertionData-like object
        # Assuming you have a constructor or factory for this; adjust accordingly
        return InsertionData(
            is_feasible=False,
            cost=math.inf,
            pPos=0,
            dPos=0,
            pJob=0,
            dJob=0,
            k=0,
            machine_travels=[],
        )

    c_min = min(c.cost for c in cand_list)
    c_max = max(c.cost for c in cand_list)
    max_cost_allowed = c_min + params.alpha * (c_max - c_min)

    # Restricted candidate list: candidates with cost <= max_cost_allowed
    rcl = [c for c in cand_list if c.cost <= max_cost_allowed]

    k = len(rcl)
    idx_cand = params.rng.randint(0, k - 1)  # zero-based index
    chosen = rcl[idx_cand]

    return chosen
