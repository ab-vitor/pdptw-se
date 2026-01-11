from typing import List

from modules.data import InstanceData
from modules.parameters import ParameterData
from modules.solutions import Solution

from .update_solution import update_machines_indexes, update_solution
from .choose_candidate import choose_candidate
from .init_solution import get_service_order, init_solution
from .entities_greedy_heur import InsertionData
from .check_insertion import check_insertion


def get_candidate_list_by_increase_in_comp_time(
    inst: InstanceData, sol: Solution, p_job: int, d_job: int
) -> List[InsertionData]:
    cand_list = []

    for k in inst.K:
        for p_pos in range(2, len(sol.vehicles[k])):
            for d_pos in range(p_pos, len(sol.vehicles[k])):
                check_ins_data = check_insertion(
                    sol, k, p_pos, d_pos, p_job, d_job, inst
                )
                if not check_ins_data.feasible:
                    continue

                cand = InsertionData(
                    is_feasible=True,
                    cost=check_ins_data.cost,
                    pPos=p_pos,
                    dPos=d_pos,
                    pJob=p_job,
                    dJob=d_job,
                    vehicle=k,
                    possibleMachineTravels=check_ins_data.possibleMachineTravels,
                )
                cand_list.append(cand)

    return cand_list


def semi_greedy_heuristic(inst: InstanceData, params: ParameterData) -> Solution:
    sol = init_solution(inst)
    non_serviced_reqs = get_service_order(inst, params)
    idx_req_to_serve = 0
    jumped_request = False

    while idx_req_to_serve < len(non_serviced_reqs):
        p_job = non_serviced_reqs[idx_req_to_serve]
        d_job = p_job + inst.n

        cand_list = get_candidate_list_by_increase_in_comp_time(inst, sol, p_job, d_job)
        chosen = choose_candidate(cand_list, params)

        if chosen.is_feasible:
            sol = update_solution(sol, chosen, inst)
        else:
            jumped_request = True
            break  # Jumped request means stop

        idx_req_to_serve += 1

    update_machines_indexes(sol)

    sol.is_feasible = not jumped_request

    # Optional: add post-validation here if needed
    # sol.feasible = validate_solution(inst, sol, params)

    return sol
