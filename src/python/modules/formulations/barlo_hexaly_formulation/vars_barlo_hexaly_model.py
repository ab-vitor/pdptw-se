from typing import List, Optional
from hexaly.optimizer import HxModel, HxExpression
from modules.data import InstanceData
from .entities_barlo_hexaly_formulation import (
    BarloHxRoutingVars,
    BarloHxSchedulingVars,
)


def barlo_hexaly_routing_variables(
    inst: InstanceData, model: HxModel
) -> BarloHxRoutingVars:
    nb_customers = 2 * inst.n
    routes: List[HxExpression] = [model.list(nb_customers) for _ in inst.K]
    routes_array: HxExpression = model.array(routes)
    demands: HxExpression = model.array(inst.q)

    route_loads: List[Optional[HxExpression]] = [None] * len(inst.K)

    nb_arcs_machines = len(inst.A_m)
    trajectories: List[HxExpression] = [model.list(nb_arcs_machines) for _ in inst.H]
    trajectories_array: HxExpression = model.array(trajectories)

    idx_A_m: HxExpression = model.array(inst.idx_A_m)
    origins_A_m: HxExpression = model.array(inst.origins_A_m)
    destinies_A_m: HxExpression = model.array(inst.destinies_A_m)
    diff_region: HxExpression = model.array(inst.diff_region)

    return BarloHxRoutingVars(
        routes=routes,
        routes_array=routes_array,
        demands=demands,
        routes_loads=route_loads,
        trajectories=trajectories,
        trajectories_array=trajectories_array,
        idx_A_m=idx_A_m,
        origins_A_m=origins_A_m,
        destinies_A_m=destinies_A_m,
        diff_region=diff_region,
    )


def barlo_hexaly_scheduling_variables(
    inst: InstanceData, model: HxModel
) -> BarloHxSchedulingVars:
    Le = inst.e[inst.depot_begin]
    Ll = inst.l[inst.depot_begin]

    tstart: List[HxExpression] = [model.float(Le, Ll) for _ in inst.K]
    tstart_array: HxExpression = model.array(tstart)
    tfinal: List[HxExpression] = [model.float(Le, Ll) for _ in inst.K]
    tfinal_array: HxExpression = model.array(tfinal)

    C: List[HxExpression] = [model.float(Le, Ll) for _ in inst.K]

    t: List[HxExpression] = [model.float(Le, Ll) for _ in inst.V_p_d]
    t_array: List[HxExpression] = model.array(t)
    alpha: List[HxExpression] = [model.float(Le, Ll) for _ in inst.A_m]
    alpha_array: List[HxExpression] = model.array(alpha)

    service_start_times: List[Optional[HxExpression]] = [None] * len(inst.K)

    machine_travels_start_times: List[Optional[HxExpression]] = [None] * len(inst.H)

    earliest: HxExpression = model.array(inst.e)
    latest: HxExpression = model.array(inst.l)
    d_matrix: HxExpression = model.array(inst.d)
    service_time: HxExpression = model.array(inst.s)
    d_bar_matrix: HxExpression = model.array(inst.d_bar)
    O_matrix: HxExpression = model.array(inst.O_matrix)
    f_matrix: HxExpression = model.array(inst.f)

    return BarloHxSchedulingVars(
        tstart=tstart,
        tstart_array=tstart_array,
        tfinal=tfinal,
        tfinal_array=tfinal_array,
        C=C,
        earliest=earliest,
        latest=latest,
        d_matrix=d_matrix,
        service_time=service_time,
        t=t,
        t_array=t_array,
        alpha=alpha,
        alpha_array=alpha_array,
        service_start_times=service_start_times, # ! delete if v0 is deleted
        machine_travels_start_times=machine_travels_start_times, # ! delete if v0 is deleted
        d_bar_matrix=d_bar_matrix,
        O_matrix=O_matrix,
        f_matrix=f_matrix,
    )
