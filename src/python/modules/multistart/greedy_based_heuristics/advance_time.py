from typing import List
from modules.data import InstanceData
from modules.solutions import VehicleStop, MachineTravel
from .machine_travel import get_best_machine_travel_time
from .entities_greedy_heur import PossibleMachineTravel


def advance_best_time(
    time: float,
    prev_stop: VehicleStop,
    curr_stop: VehicleStop,
    k: int,
    inst: InstanceData,
    machines: List[List[MachineTravel]],
    possible_machine_travels: List[List[PossibleMachineTravel]],
    vehicle_ind: int,
    p_pos: int,
) -> float:
    time += inst.s[prev_stop.node]
    if prev_stop.job.point.z == curr_stop.job.point.z:
        time += inst.d[prev_stop.node, curr_stop.node, k]
    else:
        print(time)
        time += get_best_machine_travel_time(
            prev_stop,
            curr_stop,
            k,
            time,
            inst,
            machines,
            possible_machine_travels,
            vehicle_ind,
            p_pos,
        )
    print(time)
    time = max(time, curr_stop.job.earl)
    return time


def advance_time(
    time: float,
    prev_stop: VehicleStop,
    curr_stop: VehicleStop,
    k: int,
    inst: InstanceData,
    machine_travels: List[PossibleMachineTravel],
    last_mach_trv: List[int],
) -> float:
    time += inst.s[prev_stop.node]

    if prev_stop.job.point.z == curr_stop.job.point.z:
        curr_stop.mach = 0
        time += inst.d[prev_stop.node, curr_stop.node, k]
    else:
        mach_trv = machine_travels[last_mach_trv[0]]
        curr_stop.mach = mach_trv.h
        last_mach_trv[0] += 1
        time += mach_trv.deltaT

    time = max(time, curr_stop.job.earl)
    return time
