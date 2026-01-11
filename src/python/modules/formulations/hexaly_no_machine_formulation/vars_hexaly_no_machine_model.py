from typing import List, Optional
from hexaly.optimizer import HxModel, HxExpression
from modules.data import InstanceData
from .entities_hexaly_no_machine_formulation import (
    MeloHxRoutingVars,
    MeloHxSchedulingVars,
)


def melo_hexaly_routing_variables(
    inst: InstanceData, model: HxModel
) -> MeloHxRoutingVars:
    nb_customers = 2 * inst.n
    routes: List[HxExpression] = [model.list(nb_customers) for _ in inst.K]
    routes_array: HxExpression = model.array(routes)
    demands: HxExpression = model.array(inst.q)
    vehicles_used: List[HxExpression] = [
        (model.count(routes[k]) > 0) for k in range(len(inst.K))
    ]
    nb_vehicles_used: HxExpression = model.sum(vehicles_used)

    return MeloHxRoutingVars(
        routes=routes,
        routes_array=routes_array,
        demands=demands,
        vehicles_used=vehicles_used,
        nb_vehicles_used=nb_vehicles_used,
    )


def melo_hexaly_scheduling_variables(
    inst: InstanceData, model: HxModel
) -> MeloHxSchedulingVars:
    Lb = inst.e[inst.depot_begin]
    Le = inst.l[inst.depot_begin]

    tstart: dict[tuple, HxExpression] = {k: model.float(Lb, Le) for k in inst.K}
    tfinal: dict[tuple, HxExpression] = {k: model.float(Lb, Le) for k in inst.K}

    C: dict[tuple, HxExpression] = {k: model.float(Lb, Le) for k in inst.K}

    earliest: HxExpression = model.array(inst.e)
    latest: HxExpression = model.array(inst.l)
    d_matrix: HxExpression = model.array(inst.d)
    service_time: HxExpression = model.array(inst.s)
    service_start_time: List[Optional[HxExpression]] = [None] * len(inst.K)
    depot_lateness: List[Optional[HxExpression]] = [None] * len(inst.K)
    lateness: List[Optional[HxExpression]] = [None] * len(inst.K)

    return MeloHxSchedulingVars(
        tstart,
        tfinal,
        C,
        earliest,
        latest,
        d_matrix,
        service_time,
        service_start_time,
        depot_lateness,
        lateness,
    )
