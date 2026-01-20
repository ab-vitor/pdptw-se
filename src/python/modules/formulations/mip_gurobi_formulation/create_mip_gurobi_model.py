import os
from gurobipy import Model, Env
from typing import Optional
import multiprocessing


from modules.parameters import ParameterData
from modules.data import InstanceData
from modules.print_utils import get_time_now

from .entities import MIPGrbModel
from .vars_mip_gurobi_model import (
    mip_gurobi_routing_variables,
    mip_gurobi_scheduling_variables,
    get_mip_model_stats,
    print_model_stats_summary,
)
from .constraints_mip_gurobi_model import (
    mip_gurobi_routing_constraints,
    mip_gurobi_scheduling_constraints,
    mip_gurobi_valid_inequalities,
)
from .objective_mip_gurobi_model import mip_gurobi_objective_function

def create_mip_gurobi_model(
    env: Optional[Env], inst: InstanceData, params: ParameterData
) -> MIPGrbModel:
    """Create MIP model with Gurobi."""
    print(f"\n[{get_time_now()}] Creating MIP model...")

    if params.solver != "Gurobi":
        print("No solver selected")
        return None

    # Instantiate Gurobi model
    model = Model(env=env)

    # Configure solver parameters
    if params.method_type == "heur" and params.method_code == "lmns":
        if params.output_flag_grb_lmns == 0:
            model.setParam("OutputFlag", 0)
        else:
            model.setParam("OutputFlag", params.output_flag_grb_lmns)
        model.setParam("MIPFocus", params.lmns_mip_focus)
        model.setParam("Threads", 1)
    else:
        if params.output_flag_grb_mip == 0:
            model.setParam("OutputFlag", 0)
        else:
            model.setParam("OutputFlag", params.output_flag_grb_mip)
        max_num_threads = max(1, multiprocessing.cpu_count() // 2)
        num_threads = min(params.threads, max_num_threads)
        model.setParam("Threads", num_threads)
        model.setParam("Heuristics", params.mip_grb_heuristics)

    model.setParam("TimeLimit", params.mip_grb_max_time)
    model.setParam("Presolve", params.mip_grb_presolve)
    model.setParam("Cuts", params.gurobi_cuts)

    if params.max_nodes >= 0:
        model.setParam("NodeLimit", params.max_nodes)

    # Ensure log-file directory exists
    log_dir = os.path.dirname(params.grb_file_name)
    if log_dir and not os.path.isdir(log_dir):
        os.makedirs(log_dir, exist_ok=True)
    model.setParam("LogFile", params.grb_file_name)

    model.setParam("Seed", params.seed)

    # === Defining variables ===
    # Routing variables
    rtvars = mip_gurobi_routing_variables(inst, model)

    # Scheduling variables
    schvars = mip_gurobi_scheduling_variables(inst, model)

    # Summary - Model variables
    stats = get_mip_model_stats(model)
    print_model_stats_summary(stats)

    # === Routing Constraints ===
    print(f"\n[{get_time_now()}] Adding routing constraints")
    mip_gurobi_routing_constraints(inst, params, model, rtvars)

    # === Scheduling Constraints ===
    print(f"[{get_time_now()}] Adding scheduling constraints")
    mip_gurobi_scheduling_constraints(inst, model, params, rtvars, schvars)

    # === Valid inequalities ===
    print(f"[{get_time_now()}] Adding valid inequalities")
    mip_gurobi_valid_inequalities(inst, model, params, rtvars, schvars)

    # === Objective Function ===
    print(f"[{get_time_now()}] Adding objective function")
    mip_gurobi_objective_function(model, schvars.C)

    return MIPGrbModel(model=model, rtvars=rtvars, schvars=schvars, stats=stats)
