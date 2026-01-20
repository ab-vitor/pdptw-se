import numpy as np
import scipy.sparse as sp
from gurobipy import Model


class MIPGrbRoutingVariables:
    def __init__(self, x: sp.spmatrix, z: np.ndarray):
        self.x = x  # Binary routing variables
        self.z = z  # Continuous routing variables


class MIPGrbSchedulingVariables:
    def __init__(
        self,
        t: np.ndarray,
        tstart: np.ndarray,
        tfinal: np.ndarray,
        C: np.ndarray,
        phi: sp.spmatrix,
        gamma: sp.spmatrix,
        alpha: sp.spmatrix,
    ):
        self.t = t  # Continuous scheduling variables for nodes
        self.tstart = tstart  # Departure times for vehicles
        self.tfinal = tfinal  # Arrival times at depot
        self.C = C  # Completion times of vehicles
        self.phi = phi  # Binary variables for machine usage on arcs
        self.gamma = gamma  # Binary precedence constraints for arcs
        self.alpha = alpha  # Continuous variables for machine travel start times


class MIPGrbModelStats:
    def __init__(
        self,
        n_vars=0,
        n_bin_vars=0,
        n_x_vars=0,
        n_z_vars=0,
        n_t_vars=0,
        n_tstart_vars=0,
        n_tfinal_vars=0,
        n_phi_vars=0,
        n_alpha_vars=0,
        n_gamma_vars=0,
        cuts=None,
    ):
        self.n_vars = n_vars
        self.n_bin_vars = n_bin_vars
        self.n_x_vars = n_x_vars
        self.n_z_vars = n_z_vars
        self.n_t_vars = n_t_vars
        self.n_tstart_vars = n_tstart_vars
        self.n_tfinal_vars = n_tfinal_vars
        self.n_phi_vars = n_phi_vars
        self.n_alpha_vars = n_alpha_vars
        self.n_gamma_vars = n_gamma_vars
        cuts = cuts if cuts is not None else {}
        for cid in range(35, 48):
            cuts["c"+str(cid)] = []
        self.cuts = cuts


class MIPGrbModel:
    def __init__(
        self,
        model: Model,
        rtvars: MIPGrbRoutingVariables,
        schvars: MIPGrbSchedulingVariables,
        stats: MIPGrbModelStats,
    ):
        self.model = model
        self.rtvars = rtvars
        self.schvars = schvars
        self.stats = stats
