from typing import List, Optional
import numpy as np

from modules.data import InstanceData
from modules.solutions import VehicleStop, MachineTravel, Solution, StatsSolution
from modules.parameters import ParameterData


def tightest_time_windows(inst: InstanceData) -> List[int]:
    reqs = inst.V_p.copy()
    reqs.sort(key=lambda i: inst.l[i] - inst.e[i])
    return reqs


def earliest_time_windows(inst: InstanceData) -> List[int]:
    reqs = inst.V_p.copy()
    reqs.sort(key=lambda i: inst.l[i])
    return reqs


def random_order_nodes(inst: InstanceData, params: ParameterData) -> List[int]:
    rkvector = [params.rng.random() for _ in range(inst.n)]
    order_nodes = list(np.argsort(rkvector) + 1)
    return order_nodes


def init_vehicle_routes(inst: InstanceData) -> List[List[VehicleStop]]:
    first_vehicle_stop = VehicleStop(inst.depot_begin, inst.jobs[inst.refs[inst.depot_begin]], 0, 0, 0, 0)
    last_vehicle_stop = VehicleStop(
        inst.depot_end, inst.jobs[inst.refs[inst.depot_end]], 0, 0, 0, 0
    )
    vehicle_routes = [[first_vehicle_stop.copy(), last_vehicle_stop.copy()] for _ in inst.K]
    return vehicle_routes


def init_machine_travels(inst: InstanceData) -> List[List[Optional[MachineTravel]]]:
    return [[] for _ in inst.H]


def get_service_order(inst: InstanceData, params: ParameterData):
    if params.greedy_service_order == "tightest_tw":
        return tightest_time_windows(inst)
    elif params.greedy_service_order == "earliest_tw":
        return earliest_time_windows(inst)
    elif params.greedy_service_order == "random":
        return random_order_nodes(inst, params)

    return inst.V_p  # fallback


def init_solution(inst):
    initial_vehicle_routes = init_vehicle_routes(inst)
    initial_machine_travels = init_machine_travels(inst)
    initial_completion_times = [0.0 for _ in inst.K]
    initial_stats = StatsSolution()

    return Solution(
        vehicles=initial_vehicle_routes,
        machines=initial_machine_travels,
        completion_times=initial_completion_times,
        is_feasible=False,
        value=0.0,
        stats=initial_stats,
    )
