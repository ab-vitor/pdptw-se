from gurobipy import Model, GRB, tupledict
from modules.data import InstanceData, is_precede_possible
from .entities import MIPGrbRoutingVariables, MIPGrbSchedulingVariables, MIPGrbModelStats


def mip_gurobi_routing_variables(
    inst: InstanceData, model: Model
) -> tuple[tupledict, tupledict]:
    """
    Create routing variables:
      x[i,j,k]  binary for whether arc (i,j) is used by vehicle k
      z[i,k]    continuous: weight of vehicle k after leaving node i
    """
    x = model.addVars(
        [
            (i, j, k)
            for i in inst.Vprime
            for j in inst.Vprime
            for k in inst.K
            if inst.in_A[i,j]
        ],
        vtype=GRB.BINARY,
        name="x",
    )

    z = model.addVars(
        [(i, k) for i in inst.Vprime for k in inst.K],
        lb=0,
        vtype=GRB.CONTINUOUS,
        name="z",
    )

    model._x = x
    model._z = z

    return MIPGrbRoutingVariables(x, z)


def mip_gurobi_scheduling_variables(
    inst: InstanceData, model: Model
) -> tuple[tupledict, tupledict, tupledict, tupledict, tupledict, tupledict, tupledict]:
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

    # Upper bound for all times is the common lateness limit
    Le = inst.l[inst.depot_begin]
    Lb = inst.e[inst.depot_begin]

    t = model.addVars(inst.V_p_d, lb=Lb, ub=Le, vtype=GRB.CONTINUOUS, name="t")

    tstart = model.addVars(inst.K, lb=Lb, ub=Le, vtype=GRB.CONTINUOUS, name="tstart")
    tfinal = model.addVars(inst.K, lb=Lb, ub=Le, vtype=GRB.CONTINUOUS, name="tfinal")
    C = model.addVars(inst.K, lb=Lb, ub=Le, vtype=GRB.CONTINUOUS, name="C")

    phi = model.addVars(
        [(i, j, h) for (i, j) in inst.A_m for h in inst.H_e[i][j]],
        vtype=GRB.BINARY,
        name="phi",
    )

    gamma = model.addVars(
        [
            (i, j, ip, jp, h)
            for (i, j) in inst.A_m
            for (ip, jp) in inst.A_m
            for h in set(inst.H_e[i][j]).intersection(inst.H_e[ip][jp])
            if is_precede_possible(i, j, ip, jp, h, inst)
        ],
        vtype=GRB.BINARY,
        name="gamma",
    )

    alpha = model.addVars(
        [(i, j, h) for (i, j) in inst.A_m for h in inst.H_e[i][j]],
        lb=Lb,
        ub=Le,
        vtype=GRB.CONTINUOUS,
        name="alpha",
    )

    model._t = t
    model._tstart = tstart
    model._tfinal = tfinal
    model._C = C
    model._phi = phi
    model._gamma  = gamma
    model._alpha  = alpha

    return MIPGrbSchedulingVariables(t, tstart, tfinal, C, phi, gamma, alpha)


def get_mip_model_stats(model: Model) -> MIPGrbModelStats:
    model.update()  # mandatory

    vars = model.getVars()
    n_vars = model.NumVars
    n_bin_vars = model.NumBinVars
    n_x_vars = sum(1 for v in vars if "x[" in v.VarName)
    n_z_vars = sum(1 for v in vars if "z[" in v.VarName)
    n_t_vars = sum(1 for v in vars if "t[" in v.VarName)
    n_tstart_vars = sum(1 for v in vars if "tstart[" in v.VarName)
    n_tfinal_vars = sum(1 for v in vars if "tfinal[" in v.VarName)
    n_phi_vars = sum(1 for v in vars if "phi[" in v.VarName)
    n_alpha_vars = sum(1 for v in vars if "alpha[" in v.VarName)
    n_gamma_vars = sum(1 for v in vars if "gamma[" in v.VarName)

    return MIPGrbModelStats(
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


def print_model_stats_summary(stats: MIPGrbModelStats) -> None:
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
