from gurobipy import Model, quicksum
from itertools import combinations, permutations

from modules.data import (
    InstanceData,
    is_min_t_arrival_infeasible,
    is_min_t_arrival_infeasible_k,
    valid_path,
    valid_path_m,
    is_precede_possible,
)
from modules.parameters import ParameterData
from modules.print_utils import indent_prints
from ..entities import MIPRoutingVariables, MIPSchedulingVariables


@indent_prints
def melo_valid_inequalities(
    inst: InstanceData,
    model: Model,
    params: ParameterData,
    rtvars: MIPRoutingVariables,
    schvars: MIPSchedulingVariables,
) -> None:
    x = rtvars.x
    z = rtvars.z
    t = schvars.t
    tstart = schvars.tstart
    tfinal = schvars.tfinal
    alpha = schvars.alpha
    phi = schvars.phi
    gamma = schvars.gamma
    C = schvars.C

    # c35
    if params.constraints_used_mip[35]:
        count = 0
        for k in inst.K:
            for i in inst.V_p_d:
                count += 1
                model.addConstr(
                    x[inst.depot_begin, inst.depot_end, k]
                    + quicksum(x[j, i, k] for j in inst.V if inst.in_A[j, i])
                    <= 1,
                    name=f"c35_{i}_{k}",
                )

        print(f"Number of c35 constraints added: {count}")

    # c36
    if params.constraints_used_mip[36]:
        count = 0
        for i, j in combinations(inst.V_p_d, 2):
            if inst.in_A[i, j] and inst.in_A[j, i]:
                count += 1
                sum1 = quicksum(x[i, j, k] for k in inst.K)
                sum2 = quicksum(x[j, i, k] for k in inst.K)
                model.addConstr(sum1 + sum2 <= 1, name=f"c36_{i}_{j}")

        print(f"Number of c36 constraints added: {count}")

    # c37
    if params.constraints_used_mip[37]:
        count = 0
        for i, j in combinations(inst.V_p_d, 2):
            if inst.in_A_m[i, j] and inst.in_A_m[j, i]:
                count += 1
                sum1 = quicksum(phi[i, j, h] for h in inst.H_e[i][j])
                sum2 = quicksum(phi[j, i, h] for h in inst.H_e[j][i])
                model.addConstr(sum1 + sum2 <= 1, name=f"c37_{i}_{j}")

        print(f"Number of c37 constraints added: {count}")

    # c38
    if params.constraints_used_mip[38]:
        count = 0
        if inst.n > 20:
            for (i, j), (iprime, jprime) in combinations(inst.A_m, 2):
                # intersect the relevant h's directly
                common_H = set(inst.H_e[i][j]).intersection(inst.H_e[iprime][jprime])
                for h in common_H:
                    if is_precede_possible(
                        inst, i, j, iprime, jprime, h
                    ) and is_precede_possible(inst, iprime, jprime, i, j, h):
                        count += 1
                        model.addConstr(
                            gamma[i, j, iprime, jprime, h]
                            + gamma[iprime, jprime, i, j, h]
                            <= 1,
                            name=f"c38_{i}_{j}_{iprime}_{jprime}_{h}",
                        )
        else:
            for (i, j), (iprime, jprime) in combinations(inst.A_m, 2):
                # intersect the relevant h's directly
                common_H = inst.H_eprime[i][j][iprime][jprime]
                for h in common_H:
                    if (
                        inst.feas_gamma[i, j, iprime, jprime, h]
                        and inst.feas_gamma[iprime, jprime, i, j, h]
                    ):
                        count += 1
                        model.addConstr(
                            gamma[i, j, iprime, jprime, h] + gamma[iprime, jprime, i, j, h]
                            <= 1,
                            name=f"c38_{i}_{j}_{iprime}_{jprime}_{h}",
                        )

        print(f"Number of c38 constraints added: {count}")

    # c39
    if params.constraints_used_mip[39]:
        max_w = 2
        count = 0
        for k in inst.K:
            for w in range(2, max_w + 1):
                for nodes in permutations(inst.Vprime, w + 1):
                    if valid_path(nodes, inst, w) and is_min_t_arrival_infeasible_k(
                        nodes, inst, k
                    ):
                        count += 1
                        model.addConstr(
                            quicksum(
                                x[nodes[idx], nodes[idx + 1], k] for idx in range(w)
                            )
                            <= w - 1,
                            name=f"c39_{'_'.join(str(n) for n in nodes)}_{k}",
                        )

        print(f"Number of c39 constraints added: {count}")

    # c40
    if params.constraints_used_mip[40]:
        max_w = 2
        count = 0
        for w in range(2, max_w + 1):
            for nodes in permutations(inst.Vprime, w + 1):
                if valid_path_m(nodes, inst, w) and is_min_t_arrival_infeasible(
                    nodes, inst
                ):
                    count += 1
                    model.addConstr(
                        quicksum(
                            quicksum(
                                phi[nodes[idx], nodes[idx + 1], h]
                                for h in inst.H_e[nodes[idx]][nodes[idx + 1]]
                            )
                            for idx in range(w)
                        )
                        <= w - 1,
                        name=f"c40_{'_'.join(str(n) for n in nodes)}",
                    )
        print(f"Number of c40 constraints added: {count}")

    # c41
    if params.constraints_used_mip[41]:
        count = 0
        for j in inst.V_p_d:
            count += 1
            model.addConstr(
                t[j]
                >= quicksum(
                    x[i, j, k] * (inst.eprime[i] + inst.s[i] + inst.d[i, j, k])
                    for k in inst.K
                    for i in inst.Vprime
                    if inst.in_A[i, j]
                ),
                name=f"c41_{j}",
            )

        print(f"Number of c41 constraints added: {count}")

    # c42
    if params.constraints_used_mip[42]:
        count = 0
        for i, j in inst.A_m:
            for h in inst.H_e[i][j]:
                count += 1
                model.addConstr(
                    alpha[i, j, h] >= inst.eprime[i] + inst.s[i] + inst.d_bar_min[i, h],
                    name=f"c42_{i}_{j}_{h}",
                )

        print(f"Number of c42 constraints added: {count}")

    # c43
    if params.constraints_used_mip[43]:
        count = 0
        for i, j in inst.A_m:
            for h in inst.H_e[i][j]:
                count += 1
                model.addConstr(
                    alpha[i, j, h]
                    <= inst.lprime[j]
                    - inst.d_bar_min[j, h]
                    - inst.O[inst.f[i][h], inst.f[j][h], h],
                    name=f"c43_{i}_{j}_{h}",
                )

        print(f"Number of c43 constraints added: {count}")

    # c44
    if params.constraints_used_mip[44]:
        count = 0
        for i, j in inst.A_m:
            for h in inst.H_e[i][j]:
                count += 1
                model.addConstr(
                    alpha[i, j, h]
                    >= inst.eprime[i]
                    + inst.s[i]
                    + quicksum(x[i, j, k] * inst.d_bar[i, h, k] for k in inst.K),
                    name=f"c44_{i}_{j}_{h}",
                )

        print(f"Number of c44 constraints added: {count}")

    # c45
    if params.constraints_used_mip[45]:
        count = 0
        for i, j in inst.A_m:
            for h in inst.H_e[i][j]:
                count += 1
                model.addConstr(
                    alpha[i, j, h]
                    <= inst.lprime[j]
                    - quicksum(
                        x[i, j, k]
                        * (inst.d_bar[j, h, k] + inst.O[inst.f[i][h], inst.f[j][h], h])
                        for k in inst.K
                    ),
                    name=f"c45_{i}_{j}_{h}",
                )

        print(f"Number of c45 constraints added: {count}")

    # c46
    if params.constraints_used_mip[46]:
        count = 0
        for i, j in inst.A_m:
            for iprime, jprime in inst.A_m:
                if (i, j) != (iprime, jprime):
                    for h in inst.H_eprime[i][j][iprime][jprime]:
                        arrival_time_at_f_h_iprime = (
                            inst.eprime[iprime]
                            + inst.s[iprime]
                            + inst.d_bar_min[iprime, h]
                        )
                        arrival_machine_at_f_h_iprime = (
                            inst.lprime[j]
                            - inst.d_bar_min[j, h]
                            + inst.O[inst.f[j][h], inst.f[iprime][h], h]
                        )
                        ij_must_precede_iprime_jprime = (
                            arrival_time_at_f_h_iprime >= arrival_machine_at_f_h_iprime
                        )
                        if ij_must_precede_iprime_jprime:
                            count += 1
                            model.addConstr(
                                alpha[iprime, jprime, h]
                                >= alpha[i, j, h]
                                + inst.O[inst.f[i][h], inst.f[j][h], h]
                                + inst.O[inst.f[j][h], inst.f[iprime][h], h],
                                name=f"c46_{i}_{j}_{iprime}_{jprime}_{h}",
                            )

        print(f"Number of c46 constraints added: {count}")
