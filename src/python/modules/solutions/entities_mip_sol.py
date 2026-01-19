from dataclasses import dataclass, field
from typing import Optional
import numpy as np
import scipy.sparse as sp
from gurobipy import GRB


@dataclass
class MIPVarsSolution:
    x: Optional[sp.spmatrix] = None
    z: Optional[np.ndarray] = None
    t: Optional[np.ndarray] = None
    tstart: Optional[np.ndarray] = None
    tfinal: Optional[np.ndarray] = None
    C: Optional[np.ndarray] = None
    phi: Optional[sp.spmatrix] = None
    gamma: Optional[sp.spmatrix] = None
    alpha: Optional[sp.spmatrix] = None


@dataclass
class MIPStats:
    status: int = field(default_factory=lambda: GRB.INFEASIBLE)
    optimal: int = 0
    tle_feas: int = 0
    tle_not_feas: int = 0
    obj_value: float = float('inf')
    bestbound: float = 0.0
    numnodes: int = 0
    time: float = 0.0
    gap: float = 0.0


@dataclass
class MIPSolution:
    vars: MIPVarsSolution = field(default_factory=MIPVarsSolution)
    stats: MIPStats = field(default_factory=MIPStats)


@dataclass
class LPSolution:
    t: np.ndarray
    tstart: np.ndarray
    tfinal: np.ndarray
    C: np.ndarray
    alpha: sp.spmatrix
    status: int
    optimal: int
    tle: int
    objValue: float
    bestbound: float
    numnodes: int
    time: float
    gap: float
