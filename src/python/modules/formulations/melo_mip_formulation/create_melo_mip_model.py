import os
from gurobipy import Model, Env
from typing import Optional
import multiprocessing


from modules.parameters import ParameterData
from modules.data import InstanceData
from modules.print_utils import get_time_now

from .entities import MIPModel
from .vars_melo_mip_model import (
    melo_routing_variables,
    melo_scheduling_variables,
    get_mip_model_stats,
    print_model_stats_summary,
)
from .constraints_melo_mip_model import (
    melo_routing_constraints,
    melo_scheduling_constraints,
    melo_valid_inequalities,
)
from .objective_melo_mip_model import melo_objective_function

def create_melo_mip_model(
    env: Optional[Env], inst: InstanceData, params: ParameterData
) -> MIPModel:
    """Create Melo MIP model with Gurobi."""
    print(f"\n[{get_time_now()}] Creating Melo MIP model...")

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
        model.setParam("Heuristics", params.mip_heuristics)

    model.setParam("TimeLimit", params.mip_max_time)
    model.setParam("Presolve", params.mip_presolve)
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
    rtvars = melo_routing_variables(inst, model)

    # Scheduling variables
    schvars = melo_scheduling_variables(inst, model)

    # Summary - Model variables
    stats = get_mip_model_stats(model)
    print_model_stats_summary(stats)

    # === Routing Constraints ===
    print(f"\n[{get_time_now()}] Adding routing constraints")
    melo_routing_constraints(inst, params, model, rtvars)

    # === Scheduling Constraints ===
    print(f"[{get_time_now()}] Adding scheduling constraints")
    melo_scheduling_constraints(inst, model, params, rtvars, schvars)

    # === Valid inequalities ===
    print(f"[{get_time_now()}] Adding valid inequalities")
    melo_valid_inequalities(inst, model, params, rtvars, schvars)

    # === Objective Function ===
    print(f"[{get_time_now()}] Adding objective function")
    melo_objective_function(model, schvars.C)

    return MIPModel(model=model, rtvars=rtvars, schvars=schvars, stats=stats)
