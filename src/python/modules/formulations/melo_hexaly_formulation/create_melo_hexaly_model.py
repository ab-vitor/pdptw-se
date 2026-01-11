import datetime
from hexaly.optimizer import HexalyOptimizer, HxModel

from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_melo_hexaly_formulation import (
    MeloHxModel,
    MeloHxRoutingVars,
    MeloHxSchedulingVars,
)
from .vars_melo_hexaly_model import (
    get_melo_hx_model_stats,
    melo_hexaly_routing_variables,
    melo_hexaly_scheduling_variables,
    print_model_stats_summary,
)

from .constraints_melo_hexaly_model import (
    melo_hexaly_routing_constraints,
    melo_hexaly_scheduling_constraints,
)
from .objective_melo_hexaly_model import melo_hexaly_objective_function


def create_melo_hexaly_model(inst: InstanceData, params: ParameterData) -> MeloHxModel:
    optimizer = HexalyOptimizer()
    model: HxModel = optimizer.model

    rtvars: MeloHxRoutingVars = melo_hexaly_routing_variables(inst, model)
    schvars: MeloHxSchedulingVars = melo_hexaly_scheduling_variables(inst, model)

    stats = get_melo_hx_model_stats(model=model, rtvars=rtvars, schvars=schvars)
    print_model_stats_summary(stats)
    
    # === Routing Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"\n[{now}] Adding routing constraints")
    melo_hexaly_routing_constraints(inst, params, model, rtvars)

    # === Scheduling Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding scheduling constraints")
    melo_hexaly_scheduling_constraints(inst, model, rtvars, schvars, params)

    # === Objective Function ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding objective function")
    melo_hexaly_objective_function(model, inst, schvars.C)

    meloHxModel: MeloHxModel = MeloHxModel(optimizer, model, rtvars, schvars, stats)
    return meloHxModel
