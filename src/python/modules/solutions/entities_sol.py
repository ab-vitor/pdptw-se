from dataclasses import dataclass, field
from typing import List
import copy

from modules.data import Job


@dataclass
class VehicleStop:
    node: int  # node id in inst.Vprime
    job: Job  # reference to a Job object
    servST: float  # arrival time at this job
    mach: int  # machine used
    mach_ind: int  # index in machine's travel vector
    load: float  # vehicle load

    def copy(self):
        return copy.deepcopy(self)


@dataclass
class MachineTravel:
    vehicle: int = 0  # which vehicle is being transported
    vehicle_ind: int = 0  # index in vehicle's stop vector
    orig: int = 0  # origin node ID
    dest: int = 0  # destination node ID
    st: float = 0.0  # start time of machine's travel
    active: bool = False  # whether this machine travel is active

    def copy(self):
        return copy.deepcopy(self)


@dataclass
class SolutionStats:
    n_vehicles_used: float = 0.0
    n_machines_used: float = 0.0
    max_max_load_all_vehicles: float = 0.0
    min_max_load_all_vehicles: float = 0.0
    mean_max_load_all_vehicles: float = 0.0
    min_completion_time: float = 0.0
    max_completion_time: float = 0.0
    mean_completion_time: float = 0.0
    machines_travel_times_with_vehicle: List[float] = field(default_factory=list)
    machines_travel_times_no_vehicle: List[float] = field(default_factory=list)
    max_load_vehicle: List[float] = field(default_factory=list)
    avrg_machines_travel_time_with_vehicle: float = 0.0
    avrg_machines_travel_time_only_with_vehicle: float = 0.0
    avrg_machines_travel_time_no_vehicle: float = 0.0
    avrg_vehicles_waiting_time_for_a_machine_travel: float = 0.0
    avrg_vehicles_waiting_time_for_a_service: float = 0.0

    def __str__(self):
        scalars = {
            "Vehicles used": self.n_vehicles_used,
            "Machines used": self.n_machines_used,
            "Max load (vehicles)": self.max_max_load_all_vehicles,
            "Min load (vehicles)": self.min_max_load_all_vehicles,
            "Mean load (vehicles)": self.mean_max_load_all_vehicles,
            "Min completion time": self.min_completion_time,
            "Max completion time": self.max_completion_time,
            "Mean completion time": self.mean_completion_time,
            "Avrg travel time (with vehicle)": self.avrg_machines_travel_time_with_vehicle,
            "Avrg travel time (only with vehicle)": self.avrg_machines_travel_time_only_with_vehicle,
            "Avrg travel time (no vehicle)": self.avrg_machines_travel_time_no_vehicle,
            "Avrg waiting time (machine travel)": self.avrg_vehicles_waiting_time_for_a_machine_travel,
            "Avrg waiting time (service)": self.avrg_vehicles_waiting_time_for_a_service,
        }

        lists = {
            "Machines travel times (with vehicle)": self.machines_travel_times_with_vehicle,
            "Machines travel times (no vehicle)": self.machines_travel_times_no_vehicle,
            "Max load per vehicle": self.max_load_vehicle,
        }

        s = []
        for k, v in scalars.items():
            s.append(f"    {k:<40}: {round(100 * v, ndigits=4)}")
        for k, v in lists.items():
            s.append(
                f"    {k:<40}: {[round(100 * e, ndigits=4) for e in v] if v else '[]'}"
            )
        return "\n".join(s)


@dataclass
class Solution:
    vehicles: List[List[VehicleStop]]
    machines: List[List[MachineTravel]]
    completion_times: List[float]
    is_feasible: bool
    value: float
    stats: SolutionStats
