from typing import List


from modules.data import InstanceData
from modules.print_utils.indent_stream import indent_prints
from .entities_sol import VehicleStop, MachineTravel, Solution

@indent_prints
def aux_function(stop: VehicleStop) -> None:
    print(f"node: {stop.node}")
    print(f"(x, y, z): ({stop.job.point.x}, {stop.job.point.y}, {stop.job.point.z})")
    print(f"dem: {stop.job.dem}")
    print(f"earl: {stop.job.earl}")
    print(f"lat: {stop.job.lat}")
    print(f"servt: {stop.job.servt}")
    print(f"pid: {stop.job.pid}")
    print(f"did: {stop.job.did}")
    print(f"servST: {stop.servST}")
    print(f"(h, h_ind): ({stop.mach}, {stop.mach_ind})")
    print(f"load: {stop.load}\n")
    return None

def print_stop_detail(stop: VehicleStop) -> None:
    aux_function(stop)
    return None


def print_stop_detail_with_job_id(stop: VehicleStop) -> None:
    print(f"id: {stop.job.id}")
    print_stop_detail(stop)
    return None

@indent_prints
def print_machine_arc_traversal(sol: Solution, inst:InstanceData, vehicle: List[VehicleStop], i: int, h: int, k: int, timer: list[float]) -> None:
    print(
        f"Task {vehicle[i-1].job.id} -> Machine {inst.machines[h].id} (Station {inst.f[vehicle[i-1].node, h]}):",
        f"{inst.d_bar[vehicle[i-1].node, h, k]}",
    )
    timer[0] += inst.d_bar[vehicle[i - 1].node, h, k]
    print(f"Vehicle arrival at machine station: {timer[0]}")
    print(
        "Waiting time until machine travel:",
        round(sol.machines[h][vehicle[i].mach_ind].st - timer[0], 2),
    )
    timer[0] = sol.machines[h][vehicle[i].mach_ind].st
    print(f"Machine travel start time: {timer[0]}")
    print(
        f"Region {vehicle[i-1].job.point.z} -> Region {vehicle[i].job.point.z}:",
        f"{inst.O[(inst.f[vehicle[i-1].node, h], inst.f[vehicle[i].node, h], h)]}",
    )
    timer[0] += inst.O[
        (inst.f[vehicle[i - 1].node, h], inst.f[vehicle[i].node, h], h)
    ]
    print(f"Machine arrival at machine station: {timer[0]}\n")
    print(
        f"Machine {inst.machines[h].id} (Station {inst.f[vehicle[i].node, h]})-> Task {vehicle[i].job.id}: {inst.d_bar[vehicle[i].node, h, k]}"
    )
    timer[0] += inst.d_bar[vehicle[i].node, h, k]
    print(f"Vehicle arrival at task: {timer[0]}")
    print(
        f"Waiting time until service start time: {round(vehicle[i].servST - timer[0], 2)}\n"
    )
    return None

def print_machine_arc_traversal_with_machine_id(sol:Solution, inst: InstanceData, vehicle: List[VehicleStop], i: int, k: int, timer: list[float]) -> None:
    h = vehicle[i].mach
    print(f"Using Machine: {inst.machines[h].id}")
    print_machine_arc_traversal(sol, inst, vehicle, i, h, k, timer)
    

def print_vehicle_arc_traversal(inst:InstanceData, vehicle:List[VehicleStop], i:int, k: int, timer: list[float]) -> None:
    print(
        f"Task {vehicle[i-1].job.id} -> Task {vehicle[i].job.id}: {inst.d[vehicle[i-1].node, vehicle[i].node, k]}"
    )
    timer[0] += inst.d[vehicle[i - 1].node, vehicle[i].node, k]
    print(f"Vehicle arrival at task: {timer[0]}")
    print(
        f"Waiting time until service start time: {round(vehicle[i].servST - timer[0], 2)}\n"
    )

@indent_prints
def print_vehicle_detail(inst: InstanceData, sol: Solution, k: int) -> None:
    vehicle = sol.vehicles[k]
    print_stop_detail_with_job_id(vehicle[0])
    timer = [vehicle[0].servST]
    for i in range(1, len(vehicle)):
        timer[0] += vehicle[i - 1].job.servt
        print(f"Finished service at time: {timer[0]}\n")
        if vehicle[i-1].job.point.z != vehicle[i].job.point.z:
            print_machine_arc_traversal_with_machine_id(sol, inst, vehicle, i, k, timer)
            print_stop_detail_with_job_id(vehicle[i])
        else:
            print_vehicle_arc_traversal(inst, vehicle, i, k, timer)
            print_stop_detail_with_job_id(vehicle[i])
        timer[0] = vehicle[i].servST


def print_travel_detail(inst: InstanceData, travel: MachineTravel, h: int) -> None:
    print(f"vehicle: {travel.vehicle}")
    print(f"vehicleInd: {travel.vehicle_ind}")
    print(f"(orig, dest): ({travel.orig}, {travel.dest})")
    print(
        f"(origID, destID): ({inst.jobs[inst.refs[travel.orig]].id}, {inst.jobs[inst.refs[travel.dest]].id})"
    )
    print(
        f"(origRegion, destRegion): ({inst.jobs[inst.refs[travel.orig]].point.z}, {inst.jobs[inst.refs[travel.dest]].point.z})"
    )
    print(f"st: {travel.st}")
    print(f"duration: {inst.O[(inst.f[travel.orig, h], inst.f[travel.dest, h], h)]}")


@indent_prints
def print_machine_detail(inst: InstanceData, machine: List[MachineTravel], h) -> None:
    previous_f = inst.initial_station
    for travel in machine:
        print(f"setup duration: {inst.O[(previous_f, inst.f[travel.orig, h], h)]}")
        previous_f = inst.f[travel.dest, h]
        print()
        print_travel_detail(inst, travel, h)
        print()


def print_timeline_solution(inst: InstanceData, sol: Solution) -> None:
    print("---------------------| VEHICLES |---------------------\n")
    for k in inst.K:
        if len(sol.vehicles[k]) > 2:
            print(f"Vehicle {inst.vehicles[k].id} :")
            print_vehicle_detail(inst, sol, k)
            print()
    print("---------------------| MACHINES |---------------------\n")
    for h in inst.H:
        if len(sol.machines[h]) > 0:
            print(f"Machine {inst.machines[h].id} :")
            print_machine_detail(inst, sol.machines[h], h)
            print()
    print("-------------------| COMPL. TIMES |-------------------\n")
    for k in inst.K:
        print(f"Vehicle {inst.vehicles[k].id} : {sol.completion_times[k]}")
        
    print("-------------------| STATISTICS |-------------------\n")
    
    print(sol.stats)
    
    print("----------------------------------------------------\n")
    print(f"TOTAL: {sum(sol.completion_times)}\n")


