from hexaly.optimizer import HxModel, HxExpression
from modules.data import InstanceData, is_precede_possible
from .entities_mip_hexaly_formulation import (
    MIPHxModelStats,
    MIPHxRoutingVars,
    MIPHxSchedulingVars,
)


def mip_hexaly_routing_variables(
    inst: InstanceData, model: HxModel
) -> MIPHxRoutingVars:
    """
    Create routing variables:
      x[i,j,k]  binary for whether arc (i,j) is used by vehicle k
      z[i,k]    continuous: weight of vehicle k after leaving node i
    """
    x: dict[tuple, HxExpression] = {
        (i, j, k): model.bool()
        for i in inst.Vprime
        for j in inst.Vprime
        for k in inst.K
        if inst.in_A[i, j]
    }

    z: dict[tuple, HxExpression] = {
        (i, k): model.float(0, inst.Q[k]) for i in inst.Vprime for k in inst.K
    }

    return MIPHxRoutingVars(x, z)


def mip_hexaly_scheduling_variables(
    inst: InstanceData, model: HxModel
) -> MIPHxSchedulingVars:
    """
    Create scheduling variables:
      t[i]                  continuous: starting time to serve node i
      tstart[k]             continuous: departing time of vehicle k from depot
      tfinal[k]             continuous: arrival time of vehicle k at the depot
      C[k]                  continuous: completion time of vehicle k (tfinal[k] - tstart[k])
      phi[i,j,h]            binary for whether the machine h is used to traverse arc (i,j)
      gamma[i,j,ip,jp,h]    binary for whether arc (i,j) precedes arc (ip, jp) for machine h
      alpha[i,j,h]          continuous: time to start machine travel
    """
    
    Le = inst.l[inst.depot_begin]
    Lb = inst.e[inst.depot_begin]

    t: dict[tuple, HxExpression] = {i: model.float(Lb, Le) for i in inst.V_p_d}

    tstart: dict[tuple, HxExpression] = {k: model.float(Lb, Le) for k in inst.K}
    tfinal: dict[tuple, HxExpression] = {k: model.float(Lb, Le) for k in inst.K}

    C: dict[tuple, HxExpression] = {k: model.float(Lb, Le) for k in inst.K}

    phi: dict[tuple, HxExpression] = {
        (i, j, h): model.bool() for (i, j) in inst.A_m for h in inst.H_e[i][j]
    }

    gamma: dict[tuple, HxExpression] = {
        (i, j, ip, jp, h): model.bool()
        for (i, j) in inst.A_m
        for (ip, jp) in inst.A_m
        if (i, j) != (ip, jp)
        for h in set(inst.H_e[i][j]).intersection(inst.H_e[ip][jp])
        if is_precede_possible(i, j, ip, jp, h, inst)
    }

    alpha: dict[tuple, HxExpression] = {
        (i, j, h): model.float(Lb, Le) for (i, j) in inst.A_m for h in inst.H_e[i][j]
    }

    return MIPHxSchedulingVars(t, tstart, tfinal, C, phi, gamma, alpha)


def get_mip_hx_model_stats(
    model: HxModel, rtvars: MIPHxRoutingVars, schvars: MIPHxSchedulingVars
) -> MIPHxModelStats:
    n_x_vars = len(rtvars.x)
    n_z_vars = len(rtvars.z)
    n_t_vars = len(schvars.t)
    n_tstart_vars = len(schvars.tstart)
    n_tfinal_vars = len(schvars.tfinal)
    n_phi_vars = len(schvars.phi)
    n_alpha_vars = len(schvars.alpha)
    n_gamma_vars = len(schvars.gamma)
    n_bin_vars = n_x_vars + n_z_vars + n_phi_vars + n_gamma_vars
    n_vars = (
        n_x_vars
        + n_z_vars
        + n_t_vars
        + n_tstart_vars
        + n_tfinal_vars
        + n_phi_vars
        + n_alpha_vars
        + n_gamma_vars
    )

    return MIPHxModelStats(
        n_vars=n_vars,
        n_bin_vars=n_bin_vars,
        n_x_vars=n_x_vars,
        n_z_vars=n_z_vars,
        n_t_vars=n_t_vars,
        n_tstart_vars=n_tstart_vars,
        n_tfinal_vars=n_tfinal_vars,
        n_phi_vars=n_phi_vars,
        n_alpha_vars=n_alpha_vars,
        n_gamma_vars=n_gamma_vars,
    )


def print_model_stats_summary(stats: MIPHxModelStats) -> None:
    print()
    print("### Model variables summary ###")

    print(f"\t-> Total number of variables: {stats.n_vars}")
    print(f"\t\t- x: {stats.n_x_vars}")
    print(f"\t\t- z: {stats.n_z_vars}")
    print(f"\t\t- t: {stats.n_t_vars}")
    print(f"\t\t- tstart: {stats.n_tstart_vars}")
    print(f"\t\t- tfinal: {stats.n_tfinal_vars}")
    print(f"\t\t- phi: {stats.n_phi_vars}")
    print(f"\t\t- alpha: {stats.n_alpha_vars}")
    print(f"\t\t- gamma: {stats.n_gamma_vars}")

    print(f"\t-> Number of binary variables: {stats.n_bin_vars}")
    print()

    return None
