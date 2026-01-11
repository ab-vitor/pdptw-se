from typing import List
from modules.solutions.entities_sol import MachineTravel, VehicleStop
from modules.data import InstanceData
from .entities_greedy_heur import PossibleMachineTravel


def find_active_machine_travel(
    machine: List[MachineTravel], pos_ref: List[int], k: int, p_pos: int, i: int = 1
) -> MachineTravel:
    """
    Finds the next active machine travel starting from a position.

    Parameters:
        machine (List[MachineTravel]): The list of machine travels.
        pos_ref (List[int]): A single-element list used to simulate a reference to an int.
        k (int): Vehicle index.
        p_pos (int): Position in the vehicle route.
        i (int): Direction of search (1 by default).

    Returns:
        MachineTravel: The next relevant MachineTravel.
    """
    if pos_ref[0] >= len(machine):
        return MachineTravel(k, p_pos)

    trv: MachineTravel = machine[pos_ref[0]]
    while (
        trv.vehicle == k and trv.vehicle_ind >= p_pos and pos_ref[0] < len(machine) - 1
    ):
        pos_ref[0] += i
        trv = machine[pos_ref[0]]

    return trv


def find_feas_mtrv_to_insert_in_machine(
    machine: List[MachineTravel],
    h: int,
    start_h_pos: int,
    k: int,
    p_pos: int,
    dep_time: float,
    lb_new_trv_end: float,
    prev_stop: VehicleStop,
    curr_stop: VehicleStop,
    vehicle_ind: int,
    inst: InstanceData,
) -> PossibleMachineTravel:
    dummy_mtrv = PossibleMachineTravel(False, 0, 0, 0, 0, 0, 0, 0)
    prev_active_mtrv_pos = start_h_pos - 1

    # Iterate from start_h_pos to end of machine list
    for pos_to_insert in range(start_h_pos, len(machine)):
        trv = machine[pos_to_insert]
        if trv.vehicle != k or trv.vehicle_ind < p_pos:
            if (
                lb_new_trv_end
                + inst.O[(inst.f[curr_stop.node, h], inst.f[trv.orig, h], h)]
                <= trv.st
            ):
                if prev_active_mtrv_pos == -1:
                    init_station_dep_time = inst.e[inst.depot_begin]
                    h_arr = (
                        init_station_dep_time
                        + inst.O[(inst.initial_station, inst.f[prev_stop.node, h], h)]
                    )
                else:
                    prev_act_trv: MachineTravel = machine[prev_active_mtrv_pos]
                    prev_act_trv_end: float = (
                        prev_act_trv.st
                        + inst.O[
                            (
                                inst.f[prev_act_trv.orig, h],
                                inst.f[prev_act_trv.dest, h],
                                h,
                            )
                        ]
                    )
                    h_arr = (
                        prev_act_trv_end
                        + inst.O[
                            (inst.f[prev_act_trv.dest, h], inst.f[prev_stop.node, h], h)
                        ]
                    )

                k_arr = dep_time + inst.d_bar[prev_stop.node, h, k]
                new_trv_end = (
                    max(h_arr, k_arr)
                    + inst.O[(inst.f[prev_stop.node, h], inst.f[curr_stop.node, h], h)]
                )
                k_arr_at_curr_node = new_trv_end + inst.d_bar[curr_stop.node, h, k]

                if k_arr_at_curr_node > curr_stop.job.lat:
                    return dummy_mtrv
                elif (
                    new_trv_end
                    + inst.O[(inst.f[curr_stop.node, h], inst.f[trv.orig, h], h)]
                    <= trv.st
                ):
                    delta_t = k_arr_at_curr_node - dep_time
                    # print(f"1 delta_t: {delta_t}")
                    return PossibleMachineTravel(
                        True,
                        delta_t,
                        h,
                        pos_to_insert + 1,
                        max(h_arr, k_arr),
                        prev_stop.node,
                        curr_stop.node,
                        vehicle_ind,
                    )
            prev_active_mtrv_pos = pos_to_insert

    # If no previous active machine travel found
    if prev_active_mtrv_pos == -1:
        pos_to_insert = 0
        init_station_dep_time = inst.e[inst.depot_begin]
        h_arr = (
            init_station_dep_time
            + inst.O[(inst.initial_station, inst.f[prev_stop.node, h], h)]
        )
        k_arr = dep_time + inst.d_bar[prev_stop.node, h, k]
        new_trv_end = (
            max(h_arr, k_arr)
            + inst.O[(inst.f[prev_stop.node, h], inst.f[curr_stop.node, h], h)]
        )
        k_arr_at_curr_node = new_trv_end + inst.d_bar[curr_stop.node, h, k]

        if k_arr_at_curr_node > curr_stop.job.lat:
            return dummy_mtrv
        else:
            delta_t = k_arr_at_curr_node - dep_time
            # print(f"2 delta_t: {delta_t}")
            return PossibleMachineTravel(
                True,
                delta_t,
                h,
                pos_to_insert + 1,
                max(h_arr, k_arr),
                prev_stop.node,
                curr_stop.node,
                vehicle_ind,
            )

    # Insert at the end of the machine travels list
    pos_to_insert = len(machine)
    prev_act_trv = machine[prev_active_mtrv_pos]
    prev_act_trv_end = (
        prev_act_trv.st
        + inst.O[(inst.f[prev_act_trv.orig, h], inst.f[prev_act_trv.dest, h], h)]
    )
    h_arr = (
        prev_act_trv_end
        + inst.O[(inst.f[prev_act_trv.dest, h], inst.f[prev_stop.node, h], h)]
    )
    k_arr = dep_time + inst.d_bar[prev_stop.node, h, k]
    new_trv_end = (
        max(h_arr, k_arr)
        + inst.O[(inst.f[prev_stop.node, h], inst.f[curr_stop.node, h], h)]
    )
    k_arr_at_curr_node = new_trv_end + inst.d_bar[curr_stop.node, h, k]

    if k_arr_at_curr_node > curr_stop.job.lat:
        return dummy_mtrv

    delta_t = k_arr_at_curr_node - dep_time
    # print(f"3 delta_t: {delta_t}")
    return PossibleMachineTravel(
        True,
        delta_t,
        h,
        pos_to_insert + 1,
        max(h_arr, k_arr),
        prev_stop.node,
        curr_stop.node,
        vehicle_ind,
    )


def analyse_possible_machine_travel_from_last_computed_possible_machine_travel(
    prev_stop: VehicleStop,
    curr_stop: VehicleStop,
    k: int,
    curr_time: float,
    inst: InstanceData,
    machine: List[MachineTravel],
    possible_machine_travels: List[List[PossibleMachineTravel]],
    h: int,
    best_possible_machine_travel: PossibleMachineTravel,
    start_h_pos: List[int],
    vehicle_ind: int,
    p_pos: int,
) -> bool:
    last_pmtrv = possible_machine_travels[h][-1]
    start_h_pos[0] = last_pmtrv.h_pos
    last_pmtrv_end = (
        last_pmtrv.st
        + inst.O[(inst.f[last_pmtrv.orig, h], inst.f[last_pmtrv.dest, h], h)]
    )

    h_arr = (
        last_pmtrv_end
        + inst.O[(inst.f[last_pmtrv.dest, h], inst.f[prev_stop.node, h], h)]
    )
    k_arr = curr_time + inst.d_bar[prev_stop.node, h, k]

    new_trv_end = (
        max(h_arr, k_arr)
        + inst.O[(inst.f[prev_stop.node, h], inst.f[curr_stop.node, h], h)]
    )
    k_arr_at_curr_node = new_trv_end + inst.d_bar[curr_stop.node, h, k]
    # print("k_arr_at_curr_node:", k_arr_at_curr_node)
    if k_arr_at_curr_node > curr_stop.job.lat:
        # print("oi here")
        return True

    next_trv = find_active_machine_travel(machine, start_h_pos, k, p_pos)

    if not (next_trv.vehicle == k and next_trv.vehicle_ind >= p_pos):
        if (
            new_trv_end
            + inst.O[(inst.f[curr_stop.node, h], inst.f[next_trv.orig, h], h)]
            <= next_trv.st
        ):
            delta_t = k_arr_at_curr_node - curr_time
            if delta_t < best_possible_machine_travel.deltaT:
                best_possible_machine_travel.found = True
                best_possible_machine_travel.deltaT = delta_t
                best_possible_machine_travel.h = h
                best_possible_machine_travel.h_pos = start_h_pos[0]
                best_possible_machine_travel.st = max(h_arr, k_arr)
                best_possible_machine_travel.orig = prev_stop.node
                best_possible_machine_travel.dest = curr_stop.node
                best_possible_machine_travel.vehicle_ind = vehicle_ind

            # print("crrraaaaaaaazyyy")
            return True
        return False
    else:
        delta_t = k_arr_at_curr_node - curr_time
        if delta_t < best_possible_machine_travel.deltaT:
            best_possible_machine_travel.found = True
            best_possible_machine_travel.deltaT = delta_t
            best_possible_machine_travel.h = h
            best_possible_machine_travel.h_pos = start_h_pos[0]
            best_possible_machine_travel.st = max(h_arr, k_arr)
            best_possible_machine_travel.orig = prev_stop.node
            best_possible_machine_travel.dest = curr_stop.node
            best_possible_machine_travel.vehicle_ind = vehicle_ind
        # print(delta_t)
        # print("alcaraaaaaaz")
        return True


def get_best_machine_travel_time(
    prev_stop: VehicleStop,
    curr_stop: VehicleStop,
    k: int,
    dep_time: float,
    inst: InstanceData,
    machines: List[List[MachineTravel]],
    possible_machine_travels: List[List[PossibleMachineTravel]],
    vehicle_ind: int,
    p_pos: int,
) -> float:
    best_possible_machine_travel = PossibleMachineTravel(
        found=False,
        deltaT=float("inf"),
        h=0,
        h_pos=0,
        st=0.0,
        orig=0,
        dest=0,
        vehicle_ind=0,
    )

    for h in inst.H_e[prev_stop.node][curr_stop.node]:
        lb_new_trv_end = (
            dep_time
            + inst.d_bar[prev_stop.node, h, k]
            + inst.O[(inst.f[prev_stop.node, h], inst.f[curr_stop.node, h], h)]
        )
        if lb_new_trv_end + inst.d_bar[curr_stop.node, h, k] > curr_stop.job.lat:
            continue

        start_h_pos = [0]

        if len(
            possible_machine_travels[h]
        ) > 0 and analyse_possible_machine_travel_from_last_computed_possible_machine_travel(
            prev_stop,
            curr_stop,
            k,
            dep_time,
            inst,
            machines[h],
            possible_machine_travels,
            h,
            best_possible_machine_travel,
            start_h_pos,
            vehicle_ind,
            p_pos,
        ):
            # print(
            #     f"{h} best_possible_machine_travel.deltaT:",
            #     best_possible_machine_travel.deltaT,
            # )
            continue

        mtrv = find_feas_mtrv_to_insert_in_machine(
            machines[h],
            h,
            start_h_pos[0],
            k,
            p_pos,
            dep_time,
            lb_new_trv_end,
            prev_stop,
            curr_stop,
            vehicle_ind,
            inst,
        )

        if mtrv.found and mtrv.deltaT < best_possible_machine_travel.deltaT:
            # print(f"deltaT: {mtrv.deltaT}")
            best_possible_machine_travel = mtrv

    # print("oi")
    if not best_possible_machine_travel.found:
        return float("inf")

    possible_machine_travels[best_possible_machine_travel.h].append(
        best_possible_machine_travel
    )

    return best_possible_machine_travel.deltaT
