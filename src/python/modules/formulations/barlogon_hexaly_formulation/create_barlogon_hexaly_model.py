import datetime
from hexaly.optimizer import HexalyOptimizer, HxModel

from modules.parameters import ParameterData
from modules.data import InstanceData
from .entities_barlogon_hexaly_formulation import (
    BarlogonHxModel,
    BarlogonHxRoutingVars,
    BarlogonHxSchedulingVars,
)
from .vars_barlogon_hexaly_model import (
    barlogon_hexaly_routing_variables,
    barlogon_hexaly_scheduling_variables,
)

from .constraints_barlogon_hexaly_model import (
    barlogon_hexaly_routing_constraints,
    barlogon_hexaly_scheduling_constraints,
)
from .objective_barlogon_hexaly_model import barlogon_hexaly_objective_function


def create_barlogon_hexaly_model(inst: InstanceData, params: ParameterData) -> BarlogonHxModel:
    optimizer = HexalyOptimizer()
    model: HxModel = optimizer.model

    rtvars: BarlogonHxRoutingVars = barlogon_hexaly_routing_variables(inst, model)
    schvars: BarlogonHxSchedulingVars = barlogon_hexaly_scheduling_variables(inst, model)

    # === Routing Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"\n[{now}] Adding routing constraints")
    barlogon_hexaly_routing_constraints(inst, params, model, rtvars)

    # === Scheduling Constraints ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding scheduling constraints")
    barlogon_hexaly_scheduling_constraints(inst, model, rtvars, schvars, params)

    # === Objective Function ===
    now: str = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] Adding objective function")
    barlogon_hexaly_objective_function(model, inst, schvars)

    meloHxModel: BarlogonHxModel = BarlogonHxModel(optimizer, model, rtvars, schvars)
    return meloHxModel
