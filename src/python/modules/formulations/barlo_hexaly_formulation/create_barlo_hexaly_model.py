import datetime
from hexaly.optimizer import HexalyOptimizer, HxModel

from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_barlo_hexaly_formulation import (
    BarloHxModel,
    BarloHxRoutingVars,
    BarloHxSchedulingVars,
)
from .vars_barlo_hexaly_model import (
    barlo_hexaly_routing_variables,
    barlo_hexaly_scheduling_variables,
)

from .constraints_barlo_hexaly_model_v1 import (
    barlo_hexaly_routing_constraints,
    barlo_hexaly_scheduling_constraints,
)
from .objective_barlo_hexaly_model import barlo_hexaly_objective_function


def create_barlo_hexaly_model(inst: InstanceData, params: ParameterData) -> BarloHxModel:
    optimizer = HexalyOptimizer()
    model: HxModel = optimizer.model

    rtvars: BarloHxRoutingVars = barlo_hexaly_routing_variables(inst, model)
    schvars: BarloHxSchedulingVars = barlo_hexaly_scheduling_variables(inst, model)

    # === Routing Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"\n[{now}] Adding routing constraints")
    barlo_hexaly_routing_constraints(inst, params, model, rtvars)

    # === Scheduling Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding scheduling constraints")
    barlo_hexaly_scheduling_constraints(inst, model, rtvars, schvars, params)

    # === Objective Function ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding objective function")
    barlo_hexaly_objective_function(model, inst, schvars.C)

    meloHxModel: BarloHxModel = BarloHxModel(optimizer, model, rtvars, schvars)
    return meloHxModel
