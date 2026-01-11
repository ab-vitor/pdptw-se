import datetime
from hexaly.optimizer import HexalyOptimizer, HxModel

from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_hexaly_no_machine_formulation import (
    MeloHxModel,
    MeloHxRoutingVars,
    MeloHxSchedulingVars,
)
from .vars_hexaly_no_machine_model import (
    melo_hexaly_routing_variables,
    melo_hexaly_scheduling_variables,
)

# from .constraints_melo_hexaly_model import (
from .constraints_hexaly_no_machine_model import (
    melo_hexaly_routing_constraints,
    melo_hexaly_scheduling_constraints,
)
from .objective_hexaly_no_machine_model import melo_hexaly_objective_function


def create_melo_hexaly_model(inst: InstanceData, params: ParameterData) -> MeloHxModel:
    optimizer = HexalyOptimizer()
    model: HxModel = optimizer.model

    rtvars: MeloHxRoutingVars = melo_hexaly_routing_variables(inst, model)
    schvars: MeloHxSchedulingVars = melo_hexaly_scheduling_variables(inst, model)

    # === Routing Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"\n[{now}] Adding routing constraints")
    melo_hexaly_routing_constraints(inst, params, model, rtvars)

    # === Scheduling Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding scheduling constraints")
    melo_hexaly_scheduling_constraints(inst, model, rtvars, schvars)

    # === Objective Function ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding objective function")
    melo_hexaly_objective_function(model, inst, schvars.C)

    meloHxModel: MeloHxModel = MeloHxModel(optimizer, model, rtvars, schvars)
    return meloHxModel
