import os
from hexaly.optimizer import (
    HexalyOptimizer,
    HxParam,
    HxSolution,
    HxSolutionStatus,
    HxStatistics,
)

from modules.parameters import ParameterData
from modules.data import InstanceData
from modules.solutions import (
    save_solution_to_file,
    save_solution_timeline,
    Solution,
    MIPHxSolution,
    MIPHxStats,
    MIPHxVarsSolution,
    create_solution_mip_hexaly,
)
from modules.csv_utils.csv_utils import write_csv_with_flock
from modules.print_utils.date_now import get_time_now

from .create_mip_hexaly_model import create_mip_hexaly_model
from .csv_results import get_csv_results


def mip_hexaly_formulation(inst: InstanceData, params: ParameterData) -> Solution:

    mip_hx_model = create_mip_hexaly_model(inst, params)

    mip_hx_model.model.close()

    hxparams: HxParam = mip_hx_model.optimizer.param
    hxparams.time_limit = int(params.mip_hx_max_time)
    hxparams.set_verbosity(1)
    num_threads = min(os.cpu_count(), params.threads)
    hxparams.set_nb_threads(num_threads)
    hxparams.set_seed(params.seed)

    mip_hx_model.optimizer.solve()

    optimizer: HexalyOptimizer = mip_hx_model.optimizer
    hxsol: HxSolution = optimizer.get_solution()
    status: HxSolutionStatus = hxsol.get_status()
    is_optimal = status == HxSolutionStatus.OPTIMAL
    is_feas = status == HxSolutionStatus.FEASIBLE
    is_infeas = status == HxSolutionStatus.INFEASIBLE
    

    if is_optimal:
        print("Solution is optimal")
    elif is_feas:
        print("Time limit reached, but a feasible solution is available")
    else:
        print(f"Model failed (status {status})")

    sol_stats: HxStatistics = optimizer.get_statistics()
    obj_val = hxsol.get_value(mip_hx_model.model.get_objective(0))
    best_bound = hxsol.get_objective_bound(0)
    iterations = sol_stats.get_nb_iterations()
    solve_time = sol_stats.get_running_time()
    gap = hxsol.get_objective_gap(0)*100

    print(f"  objective value = {obj_val}")
    print(
        f"  status = {status}, iterations = {iterations}, time = {solve_time:.2f}s, gap = {gap:.2f}%"
    )

    mip_hx_stats = MIPHxStats(
        status,
        int(is_optimal),
        int(is_feas),
        int(is_infeas),
        obj_val,
        best_bound,
        iterations,
        solve_time,
        gap,
    )

    sol = None
    if is_optimal or is_feas:
        x_sol = {idx: hxsol.get_value(var) for idx, var in mip_hx_model.rtvars.x.items()}
        z_sol = {idx: hxsol.get_value(var) for idx, var in mip_hx_model.rtvars.z.items()}
        t_sol = {i: hxsol.get_value(var) for i, var in mip_hx_model.schvars.t.items()}
        tstart_sol = {
            k: hxsol.get_value(var) for k, var in mip_hx_model.schvars.tstart.items()
        }
        tfinal_sol = {
            k: hxsol.get_value(var) for k, var in mip_hx_model.schvars.tfinal.items()
        }
        C_sol = {k: hxsol.get_value(var) for k, var in mip_hx_model.schvars.C.items()}
        phi_sol = {
            idx: hxsol.get_value(var) for idx, var in mip_hx_model.schvars.phi.items()
        }
        gamma_sol = {
            idx: hxsol.get_value(var) for idx, var in mip_hx_model.schvars.gamma.items()
        }
        alpha_sol = {
            idx: hxsol.get_value(var) for idx, var in mip_hx_model.schvars.alpha.items()
        }

        mip_hx_vars_sol = MIPHxVarsSolution(
            x_sol,
            z_sol,
            t_sol,
            tstart_sol,
            tfinal_sol,
            C_sol,
            phi_sol,
            gamma_sol,
            alpha_sol,
        )

        mip_hx_sol = MIPHxSolution(mip_hx_vars_sol, mip_hx_stats)

        sol = create_solution_mip_hexaly(inst, mip_hx_sol, params)

        save_solution_to_file(sol, inst, params)
        save_solution_timeline(sol, inst, params)

    print(f"\n[{get_time_now()}] Writing results to CSV: {params.csv_file_name}")
    row = get_csv_results(inst=inst, params=params, sol=sol, mip_hx_stats=mip_hx_stats, mip_hx_model_stats=mip_hx_model.stats)
    write_csv_with_flock(params.csv_file_name, row)
    
    return sol
