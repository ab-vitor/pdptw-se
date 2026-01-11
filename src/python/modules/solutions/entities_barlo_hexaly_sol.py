from dataclasses import dataclass, field
from typing import Optional
import numpy as np
from hexaly.optimizer import HxSolutionStatus


@dataclass
class BarloHxVarsSolution:
    routes: Optional[np.ndarray] = None
    routes_loads: Optional[np.ndarray] = None
    trajectories: Optional[np.ndarray] = None
    machine_travels_start_times: Optional[np.ndarray] = None
    service_start_times: Optional[np.ndarray] = None
    tstart: Optional[np.ndarray] = None
    tfinal: Optional[np.ndarray] = None
    C: Optional[np.ndarray] = None


@dataclass
class BarloHxStats:
    status: int = field(default_factory=lambda: HxSolutionStatus.INFEASIBLE)
    optimal: int = 0
    tle: int = 0
    obj_value: float = float("inf")
    best_bound: float = 0.0
    iterations: int = 0
    time: float = 0.0
    gap: float = 0.0


@dataclass
class BarloHxSolution:
    vars: BarloHxVarsSolution = field(default_factory=BarloHxVarsSolution)
    stats: BarloHxStats = field(default_factory=BarloHxStats)
