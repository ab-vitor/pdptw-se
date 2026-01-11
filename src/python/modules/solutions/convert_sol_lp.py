from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_mip_sol import LPSolution
from .entities_sol import Solution
from .print_detailed import print_detail_melo_formulation_solution

def update_sol_from_lp_sol(
    sol: Solution, lp_sol: LPSolution, inst: InstanceData, params: ParameterData
) -> None:
    for k in inst.K:
        rt = sol.vehicles[k]
        if len(rt) > 2:
            rt[0].servST = lp_sol.tstart[k]
            for stop in rt[1:-1]:
                stop.servST = lp_sol.t[stop.node]
            rt[-1].servST = lp_sol.tfinal[k]
        sol.completion_times[k] = lp_sol.C[k]

    for h in inst.H:
        mach = sol.machines[h]
        for mtrv in mach:
            mtrv.st = lp_sol.alpha[mtrv.orig, mtrv.dest, h]

    sol.is_feasible = True
    sol.value = lp_sol.objValue
    return None
