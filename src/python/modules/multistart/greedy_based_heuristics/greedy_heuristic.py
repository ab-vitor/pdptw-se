import math

from modules.data import InstanceData
from modules.solutions import Solution, print_detail_melo_formulation_solution
from modules.parameters import ParameterData

from .init_solution import init_solution, tightest_time_windows
from .check_insertion import check_insertion
from .entities_greedy_heur import InsertionData
from .update_solution import update_solution, update_machines_indexes


def get_insertion_with_less_increase_in_comp_time(
    inst: InstanceData, sol: Solution, pJob: int, dJob: int
) -> InsertionData:
    best_ins_data = InsertionData(
        is_feasible=False,
        cost=math.inf,
        pPos=0,
        dPos=0,
        pJob=0,
        dJob=0,
        k=0,
        machine_travels=[],
    )

    for k in inst.K:
        vehicle_route = sol.vehicles[k]
        for pPos in range(1, len(vehicle_route)):
            for dPos in range(pPos, len(vehicle_route)):
                print("Analyzing: ", k, " ", pPos, " ", dPos, " ", pJob, " ", dJob, sep="")
                check_ins_data = check_insertion(sol, k, pPos, dPos, pJob, dJob, inst)
                print(check_ins_data)
                if check_ins_data.feasible:
                    if check_ins_data.cost < best_ins_data.cost:
                        best_ins_data = InsertionData(
                            is_feasible=check_ins_data.feasible,
                            cost=check_ins_data.cost,
                            pPos=pPos,
                            dPos=dPos,
                            pJob=pJob,
                            dJob=dJob,
                            k=k,
                            machine_travels=check_ins_data.possibleMachineTravels,
                        )
    
    print()
    print()
    print()
    print()
    print()
    print()
    return best_ins_data

# ! Not working yet
def greedy_heuristic(inst: InstanceData, params: ParameterData) -> Solution:
    sol = init_solution(inst)
    non_serviced_reqs = tightest_time_windows(inst).copy()
    idx_req_to_serve = 0
    req_not_inserted = False

    print([non_serviced_reqs[i] + 1 for i in range(len(non_serviced_reqs))])

    while idx_req_to_serve < len(non_serviced_reqs) and not req_not_inserted:
        pJob = non_serviced_reqs[idx_req_to_serve]
        dJob = pJob + inst.n
        print(pJob, dJob)

        best_ins_data = get_insertion_with_less_increase_in_comp_time(
            inst, sol, pJob, dJob
        )

        if best_ins_data.is_feasible:
            print()
            sol = update_solution(sol, best_ins_data, inst)
            print("PRINT ROUTES")
            for k in inst.K:
                print("k:", k, "-", sol.vehicles[k][-1].servST)
            print()
            
            if idx_req_to_serve == 10:
                break
                exit(0)
        else:
            req_not_inserted = True
        print()
        print("Solution value: ",sol.value)
        idx_req_to_serve += 1

    update_machines_indexes(sol)
    sol.is_feasible = not req_not_inserted
    print_detail_melo_formulation_solution(inst, sol)
    exit(0)

    # Optional validation
    # if validateSolution(inst, sol, params):
    #     sol.feasible = True
    # else:
    #     sol.feasible = False

    return sol
