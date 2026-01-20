from modules.data import InstanceData, is_precede_possible
from modules.parameters import ParameterData
from hexaly.optimizer import HxModel
from .entities_mip_hexaly_formulation import (
    MeloHxRoutingVars,
    MeloHxSchedulingVars,
)


def mip_hexaly_routing_constraints(
    inst: InstanceData, params: ParameterData, model: HxModel, rtvars: MeloHxRoutingVars
) -> None:
    """
    Add the routing constraints c1–c10 to `model`.
    """
    x = rtvars.x
    z = rtvars.z

    # c1
    if params.constraints_used_mip[1]:
        for k in inst.K:
            sumX = model.sum(
                [x[inst.depot_begin, j, k] for j in inst.V_p]
                + [x[inst.depot_begin, inst.depot_end, k]],
            )
            model.constraint(sumX == 1)

    # c2
    if params.constraints_used_mip[2]:
        for k in inst.K:
            for i in inst.V_p_d:
                sum1 = model.sum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                sum2 = model.sum(x[i, j, k] for j in inst.Vprime if inst.in_A[i, j])
                model.constraint(sum1 - sum2 == 0)

    # c3
    if params.constraints_used_mip[3]:
        for k in inst.K:
            sumX = model.sum(
                [x[j, inst.depot_end, k] for j in inst.V_d]
                + [x[inst.depot_begin, inst.depot_end, k]],
            )
            model.constraint(sumX == 1)

    # c4
    if params.constraints_used_mip[4]:
        for i in inst.V_p_d:
            sumX = model.sum(x[j, i, k] for k in inst.K for j in inst.Vprime if inst.in_A[j, i])
            model.constraint(sumX == 1)

    # c5
    if params.constraints_used_mip[5]:
        for k in inst.K:
            for i in inst.V_p:
                sum1 = model.sum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                sum2 = model.sum(
                    x[j, inst.n + i, k] for j in inst.Vprime if inst.in_A[j, i + inst.n]
                )
                model.constraint(sum1 == sum2)

    # c6
    if params.constraints_used_mip[6]:
        for k in inst.K:
            model.constraint(z[inst.depot_begin, k] == 0)

    # c7
    if params.constraints_used_mip[7]:
        for k in inst.K:
            for i, j in inst.A:
                model.constraint(
                    z[j, k] >= z[i, k] + inst.q[j] - inst.M[1] * (1 - x[i, j, k])
                )

    # c8
    if params.constraints_used_mip[8]:
        for k in inst.K:
            for i, j in inst.A:
                model.constraint(
                    z[j, k] <= z[i, k] + inst.q[j] + inst.M[1] * (1 - x[i, j, k])
                )

    # c9
    if params.constraints_used_mip[9]:
        for k in inst.K:
            for i in inst.V_p_d:
                sumX = model.sum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                rhs = min(inst.Q[k], max(0, inst.Q[k] + inst.q[i])) * sumX
                model.constraint(z[i, k] <= rhs)

    # c10
    if params.constraints_used_mip[10]:
        for k in inst.K:
            for i in inst.V_p:
                sumX = model.sum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                model.constraint(z[i, k] >= inst.q[i] * sumX)


def mip_hexaly_scheduling_constraints(
    inst: InstanceData,
    model: HxModel,
    rtvars: MeloHxRoutingVars,
    schvars: MeloHxSchedulingVars,
    params: ParameterData
) -> None:

    x = rtvars.x
    t = schvars.t
    tstart = schvars.tstart
    tfinal = schvars.tfinal
    phi = schvars.phi
    alpha = schvars.alpha
    gamma = schvars.gamma
    C = schvars.C

    # c13
    if params.constraints_used_mip[13]:
        for k in inst.K:
            for i, j in inst.A:
                if i != inst.depot_begin and j in inst.V_p_d:
                    model.constraint(
                        t[j]
                        >= t[i] + inst.s[i] + inst.d[i, j, k] - inst.M[2] * (1 - x[i, j, k])
                    )

    # c14
    if params.constraints_used_mip[14]:
        for k in inst.K:
            for j in inst.V_p:
                if inst.in_A[inst.depot_begin, j]:
                    model.constraint(
                        t[j]
                        >= tstart[k]
                        + inst.d[inst.depot_begin, j, k]
                        - inst.M[3] * (1 - x[inst.depot_begin, j, k]),
                    )

    # c15
    if params.constraints_used_mip[15]:
        for i in inst.V_p:
            sumX = 0
            for k in inst.K:
                for ell, p in inst.A:
                    if p == i:
                        sumX += inst.d[i, inst.n + i, k] * x[ell, i, k]
            model.constraint(t[i] + inst.s[i] + sumX <= t[inst.n + i])

    # c16
    if params.constraints_used_mip[16]:
        for i, j in inst.A_m:
            sum1 = 0
            for h in inst.H_e[i][j]:
                sum1 += phi[i, j, h]
            sum2 = 0
            for k in inst.K:
                sum2 += x[i, j, k]
            model.constraint(sum1 == sum2)

    # c17
    if params.constraints_used_mip[17]:
        for i, j in inst.A_m:
            for k in inst.K:
                for h in inst.H_e[i][j]:
                    if i != inst.depot_begin:
                        model.constraint(
                            alpha[i, j, h]
                            >= t[i]
                            + inst.s[i]
                            + inst.d_bar[i, h, k]
                            - inst.M[4] * (2 - phi[i, j, h] - x[i, j, k])
                        )

    # c18
    if params.constraints_used_mip[18]:
        for i, j in inst.A_m:
            if j in inst.V_p:
                for h in inst.H_e[i][j]:
                    for k in inst.K:
                        if i == inst.depot_begin:
                            model.constraint(
                                alpha[inst.depot_begin, j, h]
                                >= tstart[k]
                                + inst.d_bar[inst.depot_begin, h, k]
                                - inst.M[5]
                                * (
                                    2
                                    - phi[inst.depot_begin, j, h]
                                    - x[inst.depot_begin, j, k]
                                )
                            )

    # c19
    if params.constraints_used_mip[19]:
        for i, j in inst.A_m:
            for k in inst.K:
                for h in inst.H_e[i][j]:
                    if j in inst.V_p_d:
                        model.constraint(
                            t[j]
                            >= alpha[i, j, h]
                            + inst.O[inst.f[i, h], inst.f[j, h], h]
                            + inst.d_bar[j, h, k]
                            - inst.M[6] * (2 - phi[i, j, h] - x[i, j, k]),
                        )

    # c20
    if params.constraints_used_mip[20]:
        if inst.n > 20:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    if (i, j) < (iprime, jprime):
                        common_h = set(inst.H_e[i][j]).intersection(inst.H_e[iprime][jprime])
                        for h in common_h:
                            g1 = (
                                gamma[i, j, iprime, jprime, h]
                                if is_precede_possible(i, j, iprime, jprime, h, inst)
                                else 0
                            )
                            g2 = (
                                gamma[iprime, jprime, i, j, h]
                                if is_precede_possible(iprime, jprime, i, j, h, inst)
                                else 0
                            )
                            model.constraint(
                                g1 + g2 >= phi[i, j, h] + phi[iprime, jprime, h] - 1,
                            )

        else:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    if (i, j) < (iprime, jprime):
                        for h in inst.H_eprime[i][j][iprime][jprime]:
                            g1 = (
                                gamma[i, j, iprime, jprime, h]
                                if inst.feas_gamma[i, j, iprime, jprime, h]
                                else 0
                            )
                            g2 = (
                                gamma[iprime, jprime, i, j, h]
                                if inst.feas_gamma[iprime, jprime, i, j, h]
                                else 0
                            )
                            model.constraint(
                                g1 + g2 >= phi[i, j, h] + phi[iprime, jprime, h] - 1,
                            )

    # c21
    if params.constraints_used_mip[21]:
        if inst.n > 20:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    common_h = set(inst.H_e[i][j]).intersection(inst.H_e[iprime][jprime])
                    for h in common_h:
                        if is_precede_possible(i, j, iprime, jprime, h, inst):
                            model.constraint(gamma[i, j, iprime, jprime, h] <= phi[i, j, h])
        else:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    for h in inst.H_eprime[i][j][iprime][jprime]:
                        # if (i, j) != (iprime, jprime):
                        if inst.feas_gamma[i, j, iprime, jprime, h]:
                            model.constraint(gamma[i, j, iprime, jprime, h] <= phi[i, j, h])

    # c22
    if params.constraints_used_mip[22]:
        if inst.n > 20:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    common_h = set(inst.H_e[i][j]).intersection(inst.H_e[iprime][jprime])
                    for h in common_h:
                        if is_precede_possible(iprime, jprime, i, j, h, inst):
                            model.constraint(gamma[iprime, jprime, i, j, h] <= phi[i, j, h])
        else:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    for h in inst.H_eprime[i][j][iprime][jprime]:
                        # if (i, j) != (iprime, jprime):
                        if inst.feas_gamma[iprime, jprime, i, j, h]:
                            model.constraint(gamma[iprime, jprime, i, j, h] <= phi[i, j, h])


    # c23
    if params.constraints_used_mip[23]:
        if inst.n > 20:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    common_h = set(inst.H_e[i][j]).intersection(inst.H_e[iprime][jprime])
                    common_h = common_h.intersection(set(inst.H_e[j][iprime]))
                    for h in common_h:
                        if is_precede_possible(i, j, iprime, jprime, h, inst):
                            model.constraint(
                                alpha[iprime, jprime, h]
                                >= alpha[i, j, h]
                                + inst.O[inst.f[i, h], inst.f[j, h], h]
                                + inst.O[inst.f[j, h], inst.f[iprime, h], h]
                                - inst.M[7] * (1 - gamma[i, j, iprime, jprime, h]),
                            )
        else:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    for h in (
                        set(inst.H_e[i][j])
                        .intersection(inst.H_e[iprime][jprime])
                        .intersection(inst.H_e[j][iprime])
                    ):
                        # if (i, j) != (iprime, jprime):
                        if inst.feas_gamma[i, j, iprime, jprime, h]:
                            model.constraint(
                                alpha[iprime, jprime, h]
                                >= alpha[i, j, h]
                                + inst.O[inst.f[i, h], inst.f[j, h], h]
                                + inst.O[inst.f[j, h], inst.f[iprime, h], h]
                                - inst.M[7] * (1 - gamma[i, j, iprime, jprime, h]),
                            )

    # c24
    if params.constraints_used_mip[24]:
        for i, j in inst.A_m:
            for h in inst.H_e[i][j]:
                model.constraint(
                    alpha[i, j, h]
                    >= inst.O[inst.initial_station, inst.f[i, h], h]
                    - inst.M[8] * (1 - phi[i, j, h]),
                )

    # c25
    if params.constraints_used_mip[25]:
        for k in inst.K:
            for i in inst.V_d:
                if inst.in_A[i, inst.depot_end]:
                    model.constraint(
                        tfinal[k]
                        >= t[i]
                        + inst.s[i]
                        + inst.d[i, inst.depot_end, k]
                        - inst.M[2] * (1 - x[i, inst.depot_end, k]),
                    )

    # c26
    if params.constraints_used_mip[26]:
        for i in inst.V_d:
            if inst.in_A_m[i, inst.depot_end]:
                for k in inst.K:
                    for h in inst.H_e[i][inst.depot_end]:
                        model.constraint(
                            tfinal[k]
                            >= alpha[i, inst.depot_end, h]
                            + inst.O[inst.f[i, h], inst.f[inst.depot_end, h], h]
                            + inst.d_bar[inst.depot_end, h, k]
                            - inst.M[4]
                            * (2 - phi[i, inst.depot_end, h] - x[i, inst.depot_end, k]),
                        )

    # c27
    if params.constraints_used_mip[27]:
        for k in inst.K:
            model.constraint(C[k] >= tfinal[k] - tstart[k])

    # c28
    if params.constraints_used_mip[28]:
        for i in inst.V_p_d:
            model.constraint(
                inst.eprime[i] <= t[i],
            )
            model.constraint(
                t[i] <= inst.lprime[i],
            )

    # c29
    if params.constraints_used_mip[29]:
        for k in inst.K:
            model.constraint(tstart[k] <= tfinal[k])
