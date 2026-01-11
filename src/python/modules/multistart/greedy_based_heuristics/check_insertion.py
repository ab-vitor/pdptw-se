from modules.data import InstanceData
from modules.solutions import VehicleStop, Solution
from .advance_time import advance_best_time

from .entities_greedy_heur import CheckInsertionData


def check_insertion(
    sol: Solution,
    k: int,
    pPos: int,
    dPos: int,
    pJob: int,
    dJob: int,
    inst: InstanceData,
) -> CheckInsertionData:
    print("[1] HEEEEEY:", sol.vehicles[k][-1].servST)
    # Initialize possible machine travels for each machine in inst.H
    possible_machine_travels = [[] for _ in inst.H]

    prev = pPos - 1  # adjusting for 0-based index
    curr = pPos
    prev_stop = sol.vehicles[k][prev]

    # Create VehicleStop for pickup job
    curr_stop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, -1, -1, 0)

    time = prev_stop.servST
    time = advance_best_time(
        time,
        prev_stop,
        curr_stop,
        k,
        inst,
        sol.machines,
        possible_machine_travels,
        curr,
        pPos,
    )
    load = prev_stop.load + curr_stop.job.dem
    print(f"1 {time}")
    if time > curr_stop.job.lat or load > inst.Q[k]:
        return CheckInsertionData(False, 0, possible_machine_travels)

    print("[2] HEEEEEY:", sol.vehicles[k][-1].servST)
    prev_stop = curr_stop

    if pPos != dPos:
        curr_stop = sol.vehicles[k][curr]
        time = advance_best_time(
            time,
            prev_stop,
            curr_stop,
            k,
            inst,
            sol.machines,
            possible_machine_travels,
            curr + 1,
            pPos,
        )
        load += curr_stop.job.dem
        print(f"2 {time}")
        if time > curr_stop.job.lat or load > inst.Q[k]:
            return CheckInsertionData(False, 0, possible_machine_travels)

        prev += 1
        curr += 1

        while curr < dPos:
            prev_stop = sol.vehicles[k][prev]
            curr_stop = sol.vehicles[k][curr]
            time = advance_best_time(
                time,
                prev_stop,
                curr_stop,
                k,
                inst,
                sol.machines,
                possible_machine_travels,
                curr + 1,
                pPos,
            )
            load += curr_stop.job.dem
            print(f"3 {time} ")
            if time > curr_stop.job.lat or load > inst.Q[k]:
                return CheckInsertionData(False, 0, possible_machine_travels)
            prev += 1
            curr += 1

        prev_stop = sol.vehicles[k][prev]

    # Delivery job VehicleStop
    curr_stop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, -1, -1, 0)
    time = advance_best_time(
        time,
        prev_stop,
        curr_stop,
        k,
        inst,
        sol.machines,
        possible_machine_travels,
        curr + 1,
        pPos,
    )
    load += curr_stop.job.dem
    print(f"4 {time}")
    if time > curr_stop.job.lat:
        return CheckInsertionData(False, 0, possible_machine_travels)

    print("[3] HEEEEEY:", sol.vehicles[k][-1].servST)
    prev_stop = curr_stop
    curr_stop = sol.vehicles[k][curr]
    time = advance_best_time(
        time,
        prev_stop,
        curr_stop,
        k,
        inst,
        sol.machines,
        possible_machine_travels,
        curr + 2,
        pPos,
    )
    load += curr_stop.job.dem
    print(f"5 {time}")
    if time > curr_stop.job.lat:
        return CheckInsertionData(False, 0, possible_machine_travels)

    print("[4] HEEEEEY:", sol.vehicles[k][-1].servST)
    prev += 1
    curr += 1

    while curr < len(sol.vehicles[k]):
        prev_stop = sol.vehicles[k][prev]
        curr_stop = sol.vehicles[k][curr]
        time = advance_best_time(
            time,
            prev_stop,
            curr_stop,
            k,
            inst,
            sol.machines,
            possible_machine_travels,
            curr + 2,
            pPos,
        )
        print(f"6 {time}")
        if time > curr_stop.job.lat:
            return CheckInsertionData(False, 0, possible_machine_travels)
        print("[5] HEEEEEY:", sol.vehicles[k][-1].servST)
        prev += 1
        curr += 1

    cost = time - sol.vehicles[k][-1].servST
    print(time)
    print(sol.vehicles[k][-1].node)
    print(sol.vehicles[k][-1].servST)
    print(cost)
    return CheckInsertionData(True, cost, possible_machine_travels)
