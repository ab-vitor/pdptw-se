import datetime
from hexaly.optimizer import HexalyOptimizer, HxModel

from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_mip_hexaly_formulation import (
    MIPHxModel,
    MIPHxRoutingVars,
    MIPHxSchedulingVars,
)
from .vars_mip_hexaly_model import (
    get_mip_hx_model_stats,
    mip_hexaly_routing_variables,
    mip_hexaly_scheduling_variables,
    print_model_stats_summary,
)

from .constraints_mip_hexaly_model import (
    mip_hexaly_routing_constraints,
    mip_hexaly_scheduling_constraints,
)
from .objective_mip_hexaly_model import mip_hexaly_objective_function


def create_mip_hexaly_model(inst: InstanceData, params: ParameterData) -> MIPHxModel:
    optimizer = HexalyOptimizer()
    model: HxModel = optimizer.model

    rtvars: MIPHxRoutingVars = mip_hexaly_routing_variables(inst, model)
    schvars: MIPHxSchedulingVars = mip_hexaly_scheduling_variables(inst, model)

    stats = get_mip_hx_model_stats(model=model, rtvars=rtvars, schvars=schvars)
    print_model_stats_summary(stats)
    
    # === Routing Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"\n[{now}] Adding routing constraints")
    mip_hexaly_routing_constraints(inst, params, model, rtvars)

    # === Scheduling Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding scheduling constraints")
    mip_hexaly_scheduling_constraints(inst, model, rtvars, schvars, params)

    # === Objective Function ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding objective function")
    mip_hexaly_objective_function(model, inst, schvars.C)

    mipHxModel: MIPHxModel = MIPHxModel(optimizer, model, rtvars, schvars, stats)
    return mipHxModel
