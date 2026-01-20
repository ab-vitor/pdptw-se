from dataclasses import dataclass
from hexaly.optimizer import HexalyOptimizer, HxModel, HxExpression


@dataclass
class MIPHxRoutingVars:
    def __init__(
        self,
        x: dict[tuple, HxExpression],
        z: dict[tuple, HxExpression],
    ):
        self.x = x
        self.z = z


@dataclass
class MIPHxSchedulingVars:
    def __init__(
        self,
        t: dict[tuple, HxExpression],
        tstart: dict[tuple, HxExpression],
        tfinal: dict[tuple, HxExpression],
        C: dict[tuple, HxExpression],
        phi: dict[tuple, HxExpression],
        gamma: dict[tuple, HxExpression],
        alpha: dict[tuple, HxExpression],
    ):
        self.t = t
        self.tstart = tstart
        self.tfinal = tfinal
        self.C = C
        self.phi = phi
        self.gamma = gamma
        self.alpha = alpha


@dataclass
class MIPHxModelStats:
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
        
@dataclass
class MIPHxModel:
    def __init__(
        self,
        optimizer: HexalyOptimizer,
        model: HxModel,
        rtvars: MIPHxRoutingVars,
        schvars: MIPHxSchedulingVars,
        stats: MIPHxModelStats
    ):
        self.optimizer = optimizer
        self.model = model
        self.rtvars = rtvars
        self.schvars = schvars
        self.stats = stats
