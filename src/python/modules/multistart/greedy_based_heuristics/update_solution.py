from typing import List

from modules.data import InstanceData
from modules.solutions import Solution, VehicleStop, MachineTravel
from .advance_time import advance_time
from .entities_greedy_heur import InsertionData, PossibleMachineTravel

def deactivate_machine_travels(k: int, sol: Solution, p_pos: int):
    for h in range(len(sol.machines)):
        for i in reversed(range(len(sol.machines[h]))):
            trv = sol.machines[h][i]
            if trv.vehicle == k and trv.vehicle_ind >= p_pos:
                trv.active = False

def insert_machine_travels(sol: Solution, machine_travels: List[PossibleMachineTravel], k: int):
    active = True
    for i in reversed(range(len(machine_travels))):
        mach_trv = machine_travels[i]
        sol.machines[mach_trv.h].insert(
            mach_trv.h_pos,
            MachineTravel(
                vehicle=k,
                vehicle_ind=mach_trv.vehicle_ind,
                orig=mach_trv.orig,
                dest=mach_trv.dest,
                st=mach_trv.st,
                active=active,
            )
        )

def remove_deactivated_travels(sol: Solution):
    for h in range(len(sol.machines)):
        # Iterate backwards to safely remove elements
        for i in reversed(range(len(sol.machines[h]))):
            if not sol.machines[h][i].active:
                sol.machines[h].pop(i)



def flat_chronologically(
    possible_machine_travels: List[List[PossibleMachineTravel]],
) -> List[PossibleMachineTravel]:
    machine_travels = [mtrv for sublist in possible_machine_travels for mtrv in sublist]
    machine_travels.sort(key=lambda x: x.st)
    return machine_travels


def update_solution(sol: Solution, ins_data: InsertionData, inst: InstanceData)->Solution:
    print(ins_data)
    k = ins_data.k
    p_pos = ins_data.pPos
    d_pos = ins_data.dPos
    p_job = ins_data.pJob
    d_job = ins_data.dJob
    machine_travels = flat_chronologically(ins_data.machine_travels)

    deactivate_machine_travels(k, sol, p_pos)

    last_mach_trv = [0]  # use List as a mutable ref

    prev = p_pos - 1
    curr = p_pos
    prev_stop = sol.vehicles[k][prev]
    pickup_stop = VehicleStop(p_job, inst.jobs[inst.refs[p_job]], 0, -1, -1, 0)

    time = prev_stop.servST
    time = advance_time(
        time, prev_stop, pickup_stop, k, inst, machine_travels, last_mach_trv
    )
    load = prev_stop.load + pickup_stop.job.dem

    pickup_stop.servST = time
    pickup_stop.load = load

    prev_stop = pickup_stop

    if p_pos != d_pos:
        curr_stop = sol.vehicles[k][curr]
        time = advance_time(
            time, prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv
        )
        load += curr_stop.job.dem

        curr_stop.servST = time
        curr_stop.load = load

        prev += 1
        curr += 1

        while curr < d_pos:
            prev_stop = sol.vehicles[k][prev]
            curr_stop = sol.vehicles[k][curr]
            time = advance_time(
                time, prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv
            )
            load += curr_stop.job.dem

            curr_stop.servST = time
            curr_stop.load = load

            prev += 1
            curr += 1

        prev_stop = sol.vehicles[k][prev]

    delivery_stop = VehicleStop(d_job, inst.jobs[inst.refs[d_job]], 0, -1, -1, 0)
    time = advance_time(
        time, prev_stop, delivery_stop, k, inst, machine_travels, last_mach_trv
    )
    load += delivery_stop.job.dem

    delivery_stop.servST = time
    delivery_stop.load = load

    prev_stop = delivery_stop
    curr_stop = sol.vehicles[k][curr]
    time = advance_time(
        time, prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv
    )
    load += curr_stop.job.dem

    curr_stop.servST = time

    prev += 1
    curr += 1
    while curr < len(sol.vehicles[k]):
        prev_stop = sol.vehicles[k][prev]
        curr_stop = sol.vehicles[k][curr]
        time = advance_time(
            time, prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv
        )
        curr_stop.servST = time
        prev += 1
        curr += 1

    sol.vehicles[k].insert(d_pos, delivery_stop)
    sol.vehicles[k].insert(p_pos, pickup_stop)
    insert_machine_travels(sol, machine_travels, k)
    remove_deactivated_travels(sol)
    sol.completion_times[k] = sol.vehicles[k][-1].servST
    print(sol.value)
    sol.value += ins_data.cost
    print(sol.value)

    return sol

def update_machines_indexes(sol: Solution):
    for h in range(len(sol.machines)):
        for i in range(len(sol.machines[h])):
            mach_trv = sol.machines[h][i]
            sol.vehicles[mach_trv.vehicle][mach_trv.vehicle_ind].mach_ind = i
