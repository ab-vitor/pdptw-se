from dataclasses import dataclass
from typing import List, Tuple, Dict

import numpy as np


@dataclass
class Vehicle:
    id: int
    cap: int

    @staticmethod
    def from_list(values: List[str]) -> "Vehicle":
        return Vehicle(id=int(values[0]), cap=int(values[1]))


@dataclass
class Point:
    x: int
    y: int
    z: int

    @staticmethod
    def from_list(values: List[str]) -> "Point":
        return Point(x=int(values[0]), y=int(values[1]), z=int(values[2]))


@dataclass
class Job:
    id: int
    point: Point
    dem: int
    earl: int
    lat: int
    servt: int
    pid: int
    did: int

    @staticmethod
    def from_list(values: List[str]) -> "Job":
        return Job(
            id=int(values[0]),
            point=Point.from_list(values[1:4]),
            dem=int(values[4]),
            earl=int(values[5]),
            lat=int(values[6]),
            servt=int(values[7]),
            pid=int(values[8]),
            did=int(values[9]),
        )


@dataclass
class Machine:
    id: int
    points: List[Point]
    spd: float

    @staticmethod
    def from_list(values: List[str]) -> "Machine":
        return Machine(id=int(values[0]), points=[Point.from_list(values[1:4])], spd=float(values[4]))

class PreprocessingData:
    def __init__(
        self,
        arcs: int = 0,
        arc_removals: int = 0,
        arc_removals_is_loop: int = 0,
        arc_removals_is_delivery_to_pickup: int = 0,
        arc_removals_is_depot_begin_to_delivery: int = 0,
        arc_removals_is_pickup_to_depot_end: int = 0,
        arc_removals_is_dest_depot_begin: int = 0,
        arc_removals_is_orig_depot_end: int = 0,
        arc_removals_is_capacity_violated: int = 0,
        arc_removals_is_time_window_limited: int = 0,
        arc_removals_is_time_window_pairing_limited: int = 0,
        arc_removals_is_indirect_request_attendance_impossible: int = 0,
        gamma_vars: int = 0,
        feas_gamma_vars: int = 0,
        infeas_gamma_vars_is_next_mtrv_unreachable: int = 0,
        infeas_gamma_vars_is_iprime_jprime_eq_i_j: int = 0,
        machine_removal_for_an_arc: int = 0,
    ):
        self.arcs = arcs
        self.arc_removals = arc_removals
        self.arc_removals_is_loop = arc_removals_is_loop
        self.arc_removals_is_delivery_to_pickup = arc_removals_is_delivery_to_pickup
        self.arc_removals_is_depot_begin_to_delivery = arc_removals_is_depot_begin_to_delivery
        self.arc_removals_is_pickup_to_depot_end = arc_removals_is_pickup_to_depot_end
        self.arc_removals_is_dest_depot_begin = arc_removals_is_dest_depot_begin
        self.arc_removals_is_orig_depot_end = arc_removals_is_orig_depot_end
        self.arc_removals_is_capacity_violated = arc_removals_is_capacity_violated
        self.arc_removals_is_time_window_limited = arc_removals_is_time_window_limited
        self.arc_removals_is_time_window_pairing_limited = arc_removals_is_time_window_pairing_limited
        self.arc_removals_is_indirect_request_service_impossible = arc_removals_is_indirect_request_attendance_impossible
        self.gamma_vars = gamma_vars
        self.feas_gamma_vars = feas_gamma_vars
        self.infeas_gamma_vars_is_next_mtrv_unreachable = infeas_gamma_vars_is_next_mtrv_unreachable
        self.infeas_gamma_vars_is_iprime_jprime_eq_i_j = infeas_gamma_vars_is_iprime_jprime_eq_i_j
        self.machine_removal_for_an_arc = machine_removal_for_an_arc

@dataclass
class InstanceData:
    name: str
    group: str
    type: str
    full_name: str

    vehicles: List[Vehicle]
    vehicle_types: List[Vehicle]
    jobs: List[Job]
    machines: List[Machine]

    refs: List[int]
    V: List[int]
    V_p: List[int]
    V_d: List[int]
    V_p_d: List[int]
    Vprime: List[int]

    diff_region: List[List[bool]]
    q: List[int]
    max_q: int
    K: List[int]
    Q: List[int]
    max_Q: int

    d: np.ndarray
    dmax_vehicle: np.ndarray
    dmin_vehicle: np.ndarray
    max_d: float
    d_bar: np.ndarray
    d_bar_min: np.ndarray
    d_bar_max: np.ndarray

    e: List[int]
    l: List[int]  # noqa: E741
    eprime: List[int]
    lprime: List[int]

    A: List[Tuple[int, int]]
    A_m: List[Tuple[int, int]]
    A_s: List[Tuple[int, int]]
    in_A: np.ndarray
    in_A_m: np.ndarray
    in_A_s: np.ndarray
    feas_gamma: np.ndarray

    idx_A_m: List[List[int]]
    origins_A_m: List[int]
    destinies_A_m: List[int]

    H: List[int]
    H_e: List[List[List[int]]]
    H_eprime: List[List[List[List[List[int]]]]]
    f: List[List[int]]
    O: Dict[Tuple[int, int, int], float]  # noqa: E741
    O_matrix: np.ndarray

    n: int
    s: List[int]
    max_s: int
    M: List[int]

    depot_begin: int
    depot_end: int
    initial_station: int
    first_pickup: int
    last_pickup: int
    first_delivery: int
    last_delivery: int
    
    ppd: PreprocessingData

    def __init__(
        self,
        name: str = "",
        group: str = "",
        type: str = "",
        full_name: str = "",
        vehicles: List[Vehicle] = None,
        vehicle_types: List[Vehicle] = None,
        jobs: List[Job] = None,
        machines: List[Machine] = None,
        refs: List[int] = None,
        V: List[int] = None,
        V_p: List[int] = None,
        V_d: List[int] = None,
        V_p_d: List[int] = None,
        Vprime: List[int] = None,
        diff_region: List[List[bool]] = None,
        q: List[int] = None,
        max_q: int = 0,
        K: List[int] = None,
        Q: List[int] = None,
        max_Q: int = 0,
        d: np.ndarray = None,
        dmax_vehicle: np.ndarray = None,
        dmin_vehicle: np.ndarray = None,
        max_d: float = 0.0,
        d_bar: np.ndarray = None,
        d_bar_min: np.ndarray = None,
        d_bar_max: np.ndarray = None,
        e: List[int] = None,
        l: List[int] = None,  # noqa: E741
        eprime: List[int] = None,
        lprime: List[int] = None,
        A: List[Tuple[int, int]] = None,
        A_m: List[Tuple[int, int]] = None,
        A_s: List[Tuple[int, int]] = None,
        in_A: np.ndarray = None,
        in_A_m: np.ndarray = None,
        in_A_s: np.ndarray = None,
        idx_A_m: List[List[int]] = None,
        origins_A_m: List[int] = None,
        destinies_A_m: List[int] = None,
        H: List[int] = None,
        H_e: List[List[List[int]]] = None,
        H_eprime: List[List[List[List[List[int]]]]] = None,
        f: List[List[int]] = None,
        O: Dict[Tuple[int, int, int], float] = None,  # noqa: E741
        O_matrix: np.ndarray = None,
        n: int = 0,
        s: List[int] = None,
        max_s: int = 0,
        M: List[int] = None,
        depot_begin: int = 0,
        depot_end: int = 0,
        initial_station: int = 0,
        first_pickup: int = 0,
        last_pickup: int = 0,
        first_delivery: int = 0,
        last_delivery: int = 0,
        ppd: PreprocessingData = None,
    ):
        self.name = name
        self.group = group
        self.type = type
        self.full_name = full_name
        self.vehicles = vehicles if vehicles is not None else []
        self.vehicle_types = vehicle_types if vehicle_types is not None else []
        self.jobs = jobs if jobs is not None else []
        self.machines = machines if machines is not None else []
        self.refs = refs if refs is not None else []
        self.V = V if V is not None else []
        self.V_p = V_p if V_p is not None else []
        self.V_d = V_d if V_d is not None else []
        self.V_p_d = V_p_d if V_p_d is not None else []
        self.Vprime = Vprime if Vprime is not None else []
        self.diff_region = diff_region if diff_region is not None else []
        self.q = q if q is not None else []
        self.max_q = max_q
        self.K = K if K is not None else []
        self.Q = Q if Q is not None else []
        self.max_Q = max_Q
        self.d = d if d is not None else np.array([])
        self.dmax_vehicle = dmax_vehicle if dmax_vehicle is not None else np.array([])
        self.dmin_vehicle = dmin_vehicle if dmin_vehicle is not None else np.array([])
        self.max_d = max_d
        self.d_bar = d_bar if d_bar is not None else np.array([])
        self.d_bar_min = d_bar_min if d_bar_min is not None else np.array([])
        self.d_bar_max = d_bar_max if d_bar_max is not None else np.array([])
        self.e = e if e is not None else []
        self.l = l if l is not None else []
        self.eprime = eprime if eprime is not None else []
        self.lprime = lprime if lprime is not None else []
        self.A = A if A is not None else []
        self.A_m = A_m if A_m is not None else []
        self.A_s = A_s if A_s is not None else []
        self.in_A = in_A if in_A is not None else []
        self.in_A_m = in_A_m if in_A_m is not None else []
        self.in_A_s = in_A_s if in_A_s is not None else []
        self.idx_A_m = idx_A_m if idx_A_m is not None else []
        self.origins_A_m = origins_A_m if origins_A_m is not None else []
        self.destinies_A_m = destinies_A_m if destinies_A_m is not None else []
        self.H = H if H is not None else []
        self.H_e = H_e if H_e is not None else []
        self.H_eprime = H_eprime if H_eprime is not None else []
        self.f = f if f is not None else []
        self.O = O if O is not None else {}
        self.O_matrix = O_matrix if O_matrix is not None else np.array([])
        self.n = n
        self.s = s if s is not None else []
        self.max_s = max_s
        self.M = M if M is not None else []
        self.depot_begin = depot_begin
        self.depot_end = depot_end
        self.initial_station = initial_station
        self.first_pickup = first_pickup
        self.last_pickup = last_pickup
        self.first_delivery = first_delivery
        self.last_delivery = last_delivery
        self.ppd = ppd if ppd is not None else PreprocessingData()