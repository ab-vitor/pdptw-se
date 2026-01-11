from dataclasses import dataclass
from typing import List, Optional
from hexaly.optimizer import HexalyOptimizer, HxModel, HxExpression


@dataclass
class MeloHxRoutingVars:
    def __init__(
        self,
        routes: List[HxExpression],
        routes_array: HxExpression,
        demands: HxExpression,
        vehicles_used: List[HxExpression],
        nb_vehicles_used: HxExpression,
    ):
        self.routes = routes
        self.routes_array = routes_array
        self.demands = demands
        self.vehicles_used = vehicles_used
        self.nb_vehicles_used = nb_vehicles_used


@dataclass
class MeloHxSchedulingVars:
    def __init__(
        self,
        tstart: dict[tuple, HxExpression],
        tfinal: dict[tuple, HxExpression],
        C: dict[tuple, HxExpression],
        earliest: HxExpression,
        latest: HxExpression,
        d_matrix: HxExpression,
        service_time: HxExpression,
        service_start_time: List[Optional[HxExpression]],
        depot_lateness: List[Optional[HxExpression]],
        lateness: List[Optional[HxExpression]],
    ):
        self.tstart = tstart
        self.tfinal = tfinal
        self.C = C
        self.earliest = earliest
        self.latest = latest
        self.d_matrix = d_matrix
        self.service_time = service_time
        self.service_start_time = service_start_time
        self.depot_lateness = depot_lateness
        self.lateness = lateness


@dataclass
class MeloHxModel:
    def __init__(
        self,
        optimizer: HexalyOptimizer,
        model: HxModel,
        rtvars: MeloHxRoutingVars,
        schvars: MeloHxSchedulingVars,
    ):
        self.optimizer = optimizer
        self.model = model
        self.rtvars = rtvars
        self.schvars = schvars
