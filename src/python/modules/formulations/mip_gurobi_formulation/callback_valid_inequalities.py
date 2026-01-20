from itertools import permutations
from gurobipy import Model, GRB, tupledict
from statistics import mean, stdev

from modules.data import InstanceData, is_min_t_arrival_infeasible_k, is_min_t_arrival_infeasible, valid_path, valid_path_m

from .entities import MIPGrbModelStats


def check_c35(inst: InstanceData, x: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 35
    for k in inst.K:
        for i in inst.V_p_d:
            lhs = x[inst.depot_begin, inst.depot_end, k] + sum(
                x[j, i, k] for j in inst.Vprime[:-1] if i != j and inst.in_A[j, i]
            )
            rhs = 1
            if lhs > rhs + epsilon:
                violation = lhs - rhs
                stats.cuts["c" + str(cid)].append(violation)


def check_c36(inst: InstanceData, x: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 36
    for i in inst.Vprime[:-1]:
        for j in inst.Vprime[i:]:
            if inst.in_A[i, j] and inst.in_A[j, i]:
                sum1 = sum(x[i, j, k] for k in inst.K)
                sum2 = sum(x[j, i, k] for k in inst.K)
                lhs = sum1 + sum2
                rhs = 1
                if lhs > rhs + epsilon:
                    violation = lhs - rhs
                    stats.cuts["c" + str(cid)].append(violation)


def check_c37(inst: InstanceData, phi: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 37
    """Check and count violations for constraint c37."""
    for i in inst.Vprime[:-1]:
        for j in inst.Vprime[i:]:
            if inst.in_A_m[i, j] and inst.in_A_m[j, i]:
                sum1 = sum(phi[i, j, h] for h in inst.H_e[i][j])
                sum2 = sum(phi[j, i, h] for h in inst.H_e[j][i])
                lhs = sum1 + sum2
                rhs = 1
                if lhs > rhs + epsilon:
                    violation = lhs - rhs
                    stats.cuts["c" + str(cid)].append(violation)


def check_c38(inst: InstanceData, gamma: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 38
    """Check and count violations for constraint c38."""
    for i, j in inst.A_m:
        for iprime, jprime in inst.A_m:
            for h in inst.H_eprime[i][j][iprime][jprime]:
                if (
                    inst.feas_gamma[i, j, iprime, jprime, h]
                    and inst.feas_gamma[iprime, jprime, i, j, h]
                    and (i, j) < (iprime, jprime)
                ):
                    lhs = (
                        gamma[i, j, iprime, jprime, h] + gamma[iprime, jprime, i, j, h]
                    )
                    rhs = 1
                    if lhs > rhs + epsilon:
                        violation = lhs - rhs
                        stats.cuts["c" + str(cid)].append(violation)


def check_c39(inst: InstanceData, x: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 39
    """Check and count violations for constraint c39."""
    max_w = 2  # Maximum path length to check
    for k in inst.K:
        for w in range(2, max_w + 1):
            for nodes in permutations(inst.Vprime, w + 1):
                if valid_path(nodes, inst, w) and is_min_t_arrival_infeasible_k(nodes, inst, k):
                    lhs = sum(x[nodes[idx], nodes[idx + 1], k] for idx in range(w))
                    rhs = w - 1
                    if lhs > rhs + epsilon:
                        violation = lhs - rhs
                        stats.cuts["c" + str(cid)].append(violation)


def check_c40(inst: InstanceData, phi: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 40
    """Check and count violations for constraint c40."""
    max_w = 2  # Maximum path length to check
    for w in range(2, max_w + 1):
        for nodes in permutations(inst.Vprime, w + 1):
            if valid_path_m(nodes, inst, w) and is_min_t_arrival_infeasible(nodes, inst):
                lhs = sum(
                    sum(
                        phi[nodes[idx], nodes[idx + 1], h]
                        for h in inst.H_e[nodes[idx]][nodes[idx + 1]]
                    )
                    for idx in range(w)
                )
                rhs = w - 1
                if lhs > rhs + epsilon:
                    violation = lhs - rhs
                    stats.cuts["c" + str(cid)].append(violation)


def check_c41(inst: InstanceData, x: tupledict, t: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 41
    """Check and count violations for constraint c41."""
    for j in inst.V_p_d:
        lhs = t[j]
        rhs = sum(
            x[i, j, k] * (inst.eprime[i] + inst.s[i] + inst.d[i, j, k])
            for k in inst.K
            for i in inst.Vprime
            if inst.in_A[i, j]
        )
        if lhs + epsilon < rhs:
            violation = rhs - lhs
            stats.cuts["c" + str(cid)].append(violation)


def check_c42(inst: InstanceData, alpha: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 42
    """Check and count violations for constraint c42."""
    for i, j in inst.A_m:
        for h in inst.H_e[i][j]:
            lhs = alpha[i, j, h]
            rhs = inst.eprime[i] + inst.s[i] + inst.d_bar_min[i, h]
            if lhs + epsilon < rhs:
                violation = rhs - lhs
                stats.cuts["c" + str(cid)].append(violation)


def check_c43(inst: InstanceData, alpha: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 43
    """Check and count violations for constraint c43."""
    for i, j in inst.A_m:
        for h in inst.H_e[i][j]:
            lhs = alpha[i, j, h]
            rhs = inst.lprime[j] - inst.d_bar_min[j, h]
            if lhs > rhs + epsilon:
                violation = lhs - rhs
                stats.cuts["c" + str(cid)].append(violation)


def check_c44(inst: InstanceData, alpha: tupledict, x: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 44
    """Check and count violations for constraint c44."""
    for i, j in inst.A_m:
        for h in inst.H_e[i][j]:
            lhs = alpha[i, j, h]
            rhs = (
                inst.eprime[i]
                + inst.s[i]
                + sum(x[i, j, k] * inst.d_bar[i, h, k] for k in inst.K)
            )
            if lhs + epsilon < rhs:
                violation = rhs - lhs
                stats.cuts["c" + str(cid)].append(violation)


def check_c45(inst: InstanceData, alpha: tupledict, x: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 45
    """Check and count violations for constraint c45."""
    for i, j in inst.A_m:
        for h in inst.H_e[i][j]:
            lhs = alpha[i, j, h]
            rhs = inst.lprime[j] - sum(x[i, j, k] * inst.d_bar[j, h, k] for k in inst.K)
            if lhs > rhs + epsilon:
                violation = lhs - rhs
                stats.cuts["c" + str(cid)].append(violation)


def check_c46(inst: InstanceData, alpha: tupledict, stats: MIPGrbModelStats):
    epsilon = 1e-6
    cid = 46
    for i, j in inst.A_m:
        for iprime, jprime in inst.A_m:
            if (i, j) != (iprime, jprime):
                for h in inst.H_eprime[i][j][iprime][jprime]:
                    arrival_time_at_f_h_iprime = (
                        inst.eprime[iprime] + inst.s[iprime] + inst.d_bar_min[iprime, h]
                    )
                    arrival_machine_at_f_h_iprime = (
                        inst.lprime[j]
                        - inst.d_bar_min[j, h]
                        + inst.O[inst.f[j][h], inst.f[iprime][h], h]
                    )
                    ij_must_precede_iprime_jprime = (
                        arrival_time_at_f_h_iprime > arrival_machine_at_f_h_iprime
                    )
                    if ij_must_precede_iprime_jprime:
                        lhs = alpha[iprime, jprime, h]
                        rhs = (
                            alpha[i, j, h]
                            + inst.O[inst.f[i][h], inst.f[j][h], h]
                            + inst.O[inst.f[j][h], inst.f[iprime][h], h]
                        )
                        if lhs + epsilon < rhs:
                            violation = rhs - lhs
                            stats.cuts["c" + str(cid)].append(violation)



def cb_analyze_valid_inequalities(
    model: Model, where, inst: InstanceData, stats: MIPGrbModelStats
):
    if where == GRB.Callback.MIPNODE:
        status = model.cbGet(GRB.Callback.MIPNODE_STATUS)
        if status == GRB.OPTIMAL:
            x = model.cbGetNodeRel(model._x)
            t = model.cbGetNodeRel(model._t)
            alpha = model.cbGetNodeRel(model._alpha)
            gamma = model.cbGetNodeRel(model._gamma)
            phi = model.cbGetNodeRel(model._phi)

            check_c35(inst, x, stats)
            check_c36(inst, x, stats)
            check_c37(inst, phi, stats)
            check_c38(inst, gamma, stats)
            check_c39(inst, x, stats)
            check_c40(inst, phi, stats)
            check_c41(inst, x, t, stats)
            check_c42(inst, alpha, stats)
            check_c43(inst, alpha, stats)
            check_c44(inst, alpha, x, stats)
            check_c45(inst, alpha, x, stats)
            check_c46(inst, alpha, stats)

            # print(stats.cuts)


def compute_stats_violation_for_each_constraint(stats: MIPGrbModelStats) -> float:
    for cid in range(35, 48):
        cut = f"c{cid}"
        compute_cut = cut in stats.cuts.keys() and len(stats.cuts[cut]) > 0
        stats.cuts[cut + "_meanv"] = mean(stats.cuts[cut]) if compute_cut else 0
        stats.cuts[cut + "_sdv"] = stdev(stats.cuts[cut]) if compute_cut and len(stats.cuts[cut]) > 2 else 0
        stats.cuts[cut + "_countv"] = len(stats.cuts[cut]) if compute_cut else 0
        stats.cuts[cut + "_maxv"] = max(stats.cuts[cut]) if compute_cut else 0


def print_valid_inequalities_summary(stats: MIPGrbModelStats) -> None:
    print("\n### Valid Inequalities Summary ###")
    for cid in range(35, 48):
        cut = f"c{cid}"
        if cut in stats.cuts:
            print(f"{cut}:")
            print(f"\tmean violation = {stats.cuts[cut+'_meanv']:.4f}, ")
            print(f"\tstd dev = {stats.cuts.get(cut + '_sdv', 0):.4f}, ")
            print(f"\tcount = {stats.cuts.get(cut + '_countv', 0)}, ")
            print(f"\tmax violation = {stats.cuts.get(cut + '_maxv', 0):.4f}")


def delete_cut_list(stats: MIPGrbModelStats) -> None:
    for cid in range(35, 48):
        cut = f"c{cid}"
        stats.cuts.pop(cut)
