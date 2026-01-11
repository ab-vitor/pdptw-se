from dataclasses import dataclass
from typing import List, Optional
from hexaly.optimizer import HexalyOptimizer, HxModel, HxExpression


@dataclass
class BarloHxRoutingVars:
    def __init__(
        self,
        routes: List[HxExpression],
        routes_array: HxExpression,
        demands: HxExpression,
        routes_loads: List[Optional[HxExpression]],
        trajectories: List[HxExpression],
        trajectories_array: HxExpression,
        idx_A_m: HxExpression,
        origins_A_m: HxExpression,
        destinies_A_m: HxExpression,
        diff_region: HxExpression,
    ):
        self.routes = routes
        self.routes_array = routes_array
        self.demands = demands
        self.trajectories = trajectories
        self.trajectories_array = trajectories_array
        self.idx_A_m = idx_A_m
        self.origins_A_m = origins_A_m
        self.destinies_A_m = destinies_A_m
        self.diff_region = diff_region
        self.routes_loads = routes_loads


@dataclass
class BarloHxSchedulingVars:
    def __init__(
        self,
        tstart: List[HxExpression],
        tstart_array: HxExpression,
        tfinal: List[HxExpression],
        tfinal_array: HxExpression,
        t: List[HxExpression],
        t_array: HxExpression,
        alpha: List[HxExpression],
        alpha_array: HxExpression,
        C: List[HxExpression],
        earliest: HxExpression,
        latest: HxExpression,
        d_matrix: HxExpression,
        service_time: HxExpression,
        service_start_times: List[Optional[HxExpression]], # ! delete if v0 is deleted
        machine_travels_start_times: List[Optional[HxExpression]], # ! delete if v0 is deleted
        d_bar_matrix: HxExpression,
        O_matrix: HxExpression,
        f_matrix: HxExpression,
    ):
        self.tstart = tstart
        self.tstart_array = tstart_array
        self.tfinal = tfinal
        self.tfinal_array = tfinal_array
        self.alpha = alpha
        self.alpha_array = alpha_array
        self.t = t
        self.t_array = t_array
        self.C = C
        self.earliest = earliest
        self.latest = latest
        self.d_matrix = d_matrix
        self.service_time = service_time
        self.service_start_times = service_start_times # ! delete if v0 is deleted
        self.machine_travels_start_times = machine_travels_start_times # ! delete if v0 is deleted
        self.d_bar_matrix = d_bar_matrix
        self.O_matrix = O_matrix
        self.f_matrix = f_matrix


@dataclass
class BarloHxModel:
    def __init__(
        self,
        optimizer: HexalyOptimizer,
        model: HxModel,
        rtvars: BarloHxRoutingVars,
        schvars: BarloHxSchedulingVars,
    ):
        self.optimizer = optimizer
        self.model = model
        self.rtvars = rtvars
        self.schvars = schvars
