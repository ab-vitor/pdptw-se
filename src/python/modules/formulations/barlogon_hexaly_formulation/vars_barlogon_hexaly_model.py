from typing import List, Optional
from hexaly.optimizer import HxModel, HxExpression
from modules.data import InstanceData
from .entities_barlogon_hexaly_formulation import (
    BarlogonHxRoutingVars,
    BarlogonHxSchedulingVars,
)


def barlogon_hexaly_routing_variables(
    inst: InstanceData, model: HxModel
) -> BarlogonHxRoutingVars:
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

    return BarlogonHxRoutingVars(
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


def barlogon_hexaly_scheduling_variables(
    inst: InstanceData, model: HxModel
) -> BarlogonHxSchedulingVars:
    Le = inst.e[inst.depot_begin]
    Ll = inst.l[inst.depot_begin]

    tstart: List[HxExpression] = [model.float(Le, Ll) for _ in inst.K]
    tstart_array: HxExpression = model.array(tstart)
    tfinal: List[HxExpression] = [model.float(Le, Ll) for _ in inst.K]
    tfinal_array: HxExpression = model.array(tfinal)

    C: List[HxExpression] = [model.float(Le, Ll) for _ in inst.K]

    waiting_times: List[HxExpression] = [model.float(Le, Ll) for _ in inst.A_m]
    waiting_times_array: List[HxExpression] = model.array(waiting_times)
    waiting_times_used: List[Optional[HxExpression]] = [None] * len(inst.H)
    
    

    services_start_times: List[Optional[HxExpression]] = [None] * len(inst.K)
    machine_travels_start_times: List[Optional[HxExpression]] = [None] * len(inst.H)

    earliest: HxExpression = model.array(inst.e)
    latest: HxExpression = model.array(inst.l)
    d_matrix: HxExpression = model.array(inst.d)
    service_time: HxExpression = model.array(inst.s)
    d_bar_matrix: HxExpression = model.array(inst.d_bar)
    O_matrix: HxExpression = model.array(inst.O_matrix)
    f_matrix: HxExpression = model.array(inst.f)

    return BarlogonHxSchedulingVars(
        tstart=tstart,
        tstart_array=tstart_array,
        tfinal=tfinal,
        tfinal_array=tfinal_array,
        C=C,
        earliest=earliest,
        latest=latest,
        d_matrix=d_matrix,
        service_time=service_time,
        waiting_times=waiting_times,
        waiting_times_array=waiting_times_array,
        waiting_times_used=waiting_times_used,
        services_start_times=services_start_times,
        machine_travels_start_times=machine_travels_start_times,
        d_bar_matrix=d_bar_matrix,
        O_matrix=O_matrix,
        f_matrix=f_matrix,
    )
