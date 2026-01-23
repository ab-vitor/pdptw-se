from gurobipy import Env, GRB, Var, Model, tupledict
from typing import Optional

from modules.parameters import ParameterData
from modules.data import InstanceData
from modules.solutions import (
    MIPGrbVarsSolution,
    MIPGrbStats,
    MIPGrbSolution,
    create_solution_mip_gurobi,
    save_solution_to_file,
    save_solution_timeline,
    Solution,
)
from modules.csv_utils.csv_utils import write_csv_with_flock
from modules.print_utils import get_time_now

from .entities import MIPGrbModel
from .csv_results import get_csv_results
from .create_mip_gurobi_model import create_mip_gurobi_model
from .callback_valid_inequalities import cb_analyze_valid_inequalities, compute_stats_violation_for_each_constraint, delete_cut_list, print_valid_inequalities_summary


def extract_relaxed_values(orig_var_dict: tupledict, relaxed_model: Model) -> dict:
    relaxed_sol = {}
    for idx in orig_var_dict:
        var: Var = orig_var_dict[idx]
        var_name = var.VarName  # e.g., "x[1,2,3]"
        relaxed_var = relaxed_model.getVarByName(var_name)
        if relaxed_var is not None:
            relaxed_sol[idx] = relaxed_var.X
    return relaxed_sol


def mip_gurobi_formulation(
    env: Optional[Env], inst: InstanceData, params: ParameterData
) -> Solution:
    print(f"\n[{get_time_now()}] Running mip_gurobi_formulation")

    mip_model: MIPGrbModel = create_mip_gurobi_model(env, inst, params)
    model = mip_model.model


    if params.run_callback_mip_gurobi:
        def callback_function(model, where):
            return cb_analyze_valid_inequalities(
                    model, where, inst, mip_model.stats
                )
        model.optimize(callback_function)
    else:
        model.optimize()

    if params.run_callback_mip_gurobi: 
        compute_stats_violation_for_each_constraint(mip_model.stats)
        print_valid_inequalities_summary(mip_model.stats)
        delete_cut_list(mip_model.stats)

    status = model.Status

    is_optimal = status == GRB.OPTIMAL
    is_tle_feas = status == GRB.TIME_LIMIT and model.SolCount > 0
    is_tle_no_sol = status == GRB.TIME_LIMIT and model.SolCount == 0
    is_node_limit_feasible_sol = status == GRB.NODE_LIMIT and model.SolCount > 0
    is_node_limit = status == GRB.NODE_LIMIT
    is_infeasible = status == GRB.INFEASIBLE
    if is_optimal:
        print("Solution is optimal")
    elif is_tle_feas:
        print("Time limit reached, but a feasible solution is available")
    elif is_tle_no_sol:
        print("Time limit reached and no feasible solution found.")
    elif is_node_limit_feasible_sol:
        print("Node limit reached, but a feasible solution is available")
    elif is_node_limit:
        print("Node limit reached and no feasible solution found.")
    elif is_infeasible:
        print("Model is infeasible")
    else:
        print(f"Model failed (status {status})")

    obj_val = model.ObjVal or 0
    best_bound = model.ObjBound or 0
    nodes = model.NodeCount or 0
    solve_time = model.Runtime or 0
    gap = 100.0 * (obj_val - best_bound) / obj_val if obj_val != 0 else 0.0

    print(f"  objective value = {obj_val}")
    print(
        f"  status = {status}, nodes = {nodes}, time = {solve_time:.2f}s, gap = {gap:.2f}%, bound = {best_bound:.2f}"
    )

    mip_sol_stats = MIPGrbStats(
        status,
        int(is_optimal),
        int(is_tle_feas),
        int(is_tle_no_sol),
        obj_val,
        best_bound,
        nodes,
        solve_time,
        gap,
    )

    mip_sol = None
    sol = None
    if model.SolCount > 0:
        x_sol = {idx: v.X for idx, v in mip_model.rtvars.x.items()}
        z_sol = {idx: v.X for idx, v in mip_model.rtvars.z.items()}
        t_sol = {i: v.X for i, v in mip_model.schvars.t.items()}
        tstart_sol = {k: v.X for k, v in mip_model.schvars.tstart.items()}
        tfinal_sol = {k: v.X for k, v in mip_model.schvars.tfinal.items()}
        C_sol = {k: v.X for k, v in mip_model.schvars.C.items()}
        phi_sol = {idx: v.X for idx, v in mip_model.schvars.phi.items()}
        gamma_sol = {idx: v.X for idx, v in mip_model.schvars.gamma.items()}
        alpha_sol = {idx: v.X for idx, v in mip_model.schvars.alpha.items()}

        mip_vars_sol = MIPGrbVarsSolution(
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

        mip_sol = MIPGrbSolution(mip_vars_sol, mip_sol_stats)

        sol = create_solution_mip_gurobi(inst, mip_sol, params)

        save_solution_to_file(sol, inst, params)
        save_solution_timeline(sol, inst, params)

    print(f"\n[{get_time_now()}] Writing results to CSV: {params.csv_file_name}")
    row = get_csv_results(inst=inst, params=params, sol=sol, mip_sol_stats=mip_sol_stats, mip_model_stats=mip_model.stats)
    write_csv_with_flock(params.csv_file_name, row)

    

    return sol
