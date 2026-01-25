from modules.data import InstanceData, is_precede_possible
from modules.parameters import ParameterData
from hexaly.optimizer import HxModel
from ..entities_mip_hexaly_formulation import (
    MIPHxRoutingVars,
    MIPHxSchedulingVars,
)

def mip_hexaly_scheduling_constraints(
    inst: InstanceData,
    model: HxModel,
    rtvars: MIPHxRoutingVars,
    schvars: MIPHxSchedulingVars,
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

    """
    Constraints (13):
    - (General case) whenever an arc is traversed by a vehicle, a 
    lower bound on the time to serve its destination node is 
    determined by the times of its origin node 
    """
    if params.constraints_used_mip[13]:
        for k in inst.K:
            for i, j in inst.A:
                if i != inst.depot_begin and j in inst.V_p_d:
                    model.constraint(
                        t[j]
                        >= t[i] + inst.s[i] + inst.d[i, j, k] - inst.M[2] * (1 - x[i, j, k])
                    )

    """
    Constraints (14):
    - (Depot case) whenever an arc is traversed by a vehicle, a 
    lower bound on the time to serve its destination node is 
    determined by the times of its origin node 
    """
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

    """
    Constraints (15):
    - A pickup node of a request is visited before its delivery node
    """
    if params.constraints_used_mip[15]:
        for i in inst.V_p:
            sumX = 0
            for k in inst.K:
                for ell, p in inst.A:
                    if p == i:
                        sumX += inst.d[i, inst.n + i, k] * x[ell, i, k]
            model.constraint(t[i] + inst.s[i] + sumX <= t[inst.n + i])

    """
    Constraints (16):
    - A machine is used for an arc if and only if it is traversed by a vehicle.
    """
    if params.constraints_used_mip[16]:
        for i, j in inst.A_m:
            sum1 = 0
            for h in inst.H_e[i][j]:
                sum1 += phi[i, j, h]
            sum2 = 0
            for k in inst.K:
                sum2 += x[i, j, k]
            model.constraint(sum1 == sum2)

    """
    Constraints (17):
    - (General case) Whenever a machine is used to traverse an arc, a 
    lower bound on its starting time on the machine is determined by 
    the times corresponding to its origin node
    """
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

    """
    Constraints (18):
    - (Depot case) Whenever a machine is used to traverse an arc, a 
    lower bound on its starting time on the machine is determined by
    the times corresponding to its origin node
    """
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

    """
    Constraints (19):
    - Whenever a machine is used to traverse an arc, the machine times 
    define a lower bound on the starting time of its destination node.
    """
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

    """
    Constraints (20):
    - There is an order between the traversal of two distinct arcs if 
    and only if they are both scheduled on the same machine.
    """
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

    """
    Constraints (21):
    - There is an order between the traversal of two distinct arcs if 
    and only if they are both scheduled on the same machine.
    """
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
                        if inst.feas_gamma[i, j, iprime, jprime, h]:
                            model.constraint(gamma[i, j, iprime, jprime, h] <= phi[i, j, h])

    """
    Constraints (22):
    - There is an order between the traversal of two distinct arcs if 
    and only if they are both scheduled on the same machine.
    """
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
                        if inst.feas_gamma[iprime, jprime, i, j, h]:
                            model.constraint(gamma[iprime, jprime, i, j, h] <= phi[i, j, h])


    """
    Constraints (23):
    - A lower bound on the time to traverse an arc whenever it 
    is preceded by another arc. 
    - Note that the machine `h` moves with dead freight from its 
    current station f^h_j (inst.f[j,h]) to its next boarding 
    station f^h_{i'} (inst.f[iprime,h]), in case 
    f^h_j != f^h_{i'} (inst.f[j,h] != inst.f[iprime,h]).
    """
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
                        if inst.feas_gamma[i, j, iprime, jprime, h]:
                            model.constraint(
                                alpha[iprime, jprime, h]
                                >= alpha[i, j, h]
                                + inst.O[inst.f[i, h], inst.f[j, h], h]
                                + inst.O[inst.f[j, h], inst.f[iprime, h], h]
                                - inst.M[7] * (1 - gamma[i, j, iprime, jprime, h]),
                            )

    """
    Constraints (24):
    - A lower bound on the time to traverse an arc (whenever it is
    traversed) based on the time that the machine takes between its
    initial station and the initial travel station.
    """
    if params.constraints_used_mip[24]:
        for i, j in inst.A_m:
            for h in inst.H_e[i][j]:
                model.constraint(
                    alpha[i, j, h]
                    >= inst.O[inst.initial_station, inst.f[i, h], h]
                    - inst.M[8] * (1 - phi[i, j, h]),
                )

    """
    Constraints (25):
    - (General case) Lower bound on the times the vehicles arrive at the depot.
    """
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

    """
    Constraints (26):
    - (Different regions case) Lower bound on the times the vehicles arrive at the depot.
    """
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

    """
    Constraints (27):
    - Lower bounds on the completion times of the vehicles.
    """
    if params.constraints_used_mip[27]:
        for k in inst.K:
            model.constraint(C[k] >= tfinal[k] - tstart[k])

    """
    Constraints (28):
    - Lower and upper bounds on service start times to respect time windows
    """
    if params.constraints_used_mip[28]:
        for i in inst.V_p_d:
            model.constraint(
                inst.eprime[i] <= t[i],
            )
            model.constraint(
                t[i] <= inst.lprime[i],
            )

    """
    Constraints (29):
    - Vehicle start time earlier than its end time.
    """
    if params.constraints_used_mip[29]:
        for k in inst.K:
            model.constraint(tstart[k] <= tfinal[k])
