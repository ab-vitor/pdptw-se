from gurobipy import Model, quicksum

from modules.data import InstanceData, is_precede_possible
from modules.parameters import ParameterData
from ..entities import MIPGrbRoutingVariables, MIPGrbSchedulingVariables


def mip_gurobi_scheduling_constraints(
    inst: InstanceData,
    model: Model,
    params: ParameterData,
    rtvars: MIPGrbRoutingVariables,
    schvars: MIPGrbSchedulingVariables,
) -> None:
    x = rtvars.x
    t = schvars.t
    tstart = schvars.tstart
    tfinal = schvars.tfinal
    alpha = schvars.alpha
    phi = schvars.phi
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
                    model.addConstr(
                        t[j]
                        >= t[i]
                        + inst.s[i]
                        + inst.d[i, j, k]
                        - inst.M[2] * (1 - x[i, j, k]),
                        name="c13",
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
                    model.addConstr(
                        t[j]
                        >= tstart[k]
                        + inst.d[inst.depot_begin, j, k]
                        - inst.M[3] * (1 - x[inst.depot_begin, j, k]),
                        name="c14",
                    )

    """
    Constraints (15):
    - A pickup node of a request is visited before its delivery node
    """
    if params.constraints_used_mip[15]:
        for i in inst.V_p:
            sumX = quicksum(
                inst.d[i, inst.n + i, k] * x[ell, i, k]
                for k in inst.K
                for ell in inst.Vprime
                if inst.in_A[ell, i]
            )
            model.addConstr(t[i] + inst.s[i] + sumX <= t[inst.n + i], name="c15")

    """
    Constraints (16):
    - A machine is used for an arc if and only if it is traversed by a vehicle.
    """
    if params.constraints_used_mip[16]:
        for i, j in inst.A_m:
            sum1 = quicksum(phi[i, j, h] for h in inst.H_e[i][j])
            sum2 = quicksum(x[i, j, k] for k in inst.K)
            model.addConstr(sum1 == sum2, name="c16")

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
                        model.addConstr(
                            alpha[i, j, h]
                            >= t[i]
                            + inst.s[i]
                            + inst.d_bar[i, h, k]
                            - inst.M[4] * (2 - phi[i, j, h] - x[i, j, k]),
                            name="c17",
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
                            model.addConstr(
                                alpha[inst.depot_begin, j, h]
                                >= tstart[k]
                                + inst.d_bar[inst.depot_begin, h, k]
                                - inst.M[5]
                                * (
                                    2
                                    - phi[inst.depot_begin, j, h]
                                    - x[inst.depot_begin, j, k]
                                ),
                                name="c18",
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
                        model.addConstr(
                            t[j]
                            >= alpha[i, j, h]
                            + inst.O[(inst.f[i, h], inst.f[j, h], h)]
                            + inst.d_bar[j, h, k]
                            - inst.M[6] * (2 - phi[i, j, h] - x[i, j, k]),
                            name="c19",
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
                        common_h = set(inst.H_e[i][j]).intersection(
                            inst.H_e[iprime][jprime]
                        )
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
                            model.addConstr(
                                g1 + g2 >= phi[i, j, h] + phi[iprime, jprime, h] - 1,
                                name="c20",
                            )
        else:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    for h in inst.H_eprime[i][j][iprime][jprime]:
                        if (i, j) < (iprime, jprime):
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
                            model.addConstr(
                                g1 + g2 >= phi[i, j, h] + phi[iprime, jprime, h] - 1,
                                name="c20",
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
                    common_h = set(inst.H_e[i][j]).intersection(
                        inst.H_e[iprime][jprime]
                    )
                    for h in common_h:
                        if is_precede_possible(i, j, iprime, jprime, h, inst):
                            model.addConstr(
                                gamma[i, j, iprime, jprime, h] <= phi[i, j, h],
                                name=f"c21_{i}_{j}_{iprime}_{jprime}_{h}",
                            )
        else:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    for h in inst.H_eprime[i][j][iprime][jprime]:
                        if inst.feas_gamma[i, j, iprime, jprime, h]:
                            model.addConstr(
                                gamma[i, j, iprime, jprime, h] <= phi[i, j, h],
                                name=f"c21_{i}_{j}_{iprime}_{jprime}_{h}",
                            )

    """
    Constraints (22):
    - There is an order between the traversal of two distinct arcs if 
    and only if they are both scheduled on the same machine.
    """
    if params.constraints_used_mip[22]:
        if inst.n > 20:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    common_h = set(inst.H_e[i][j]).intersection(
                        inst.H_e[iprime][jprime]
                    )
                    for h in common_h:
                        if is_precede_possible(iprime, jprime, i, j, h, inst):
                            model.addConstr(
                                gamma[iprime, jprime, i, j, h] <= phi[i, j, h],
                                name=f"c22_{i}_{j}_{iprime}_{jprime}_{h}",
                            )
        else:
            for i, j in inst.A_m:
                for iprime, jprime in inst.A_m:
                    for h in inst.H_eprime[i][j][iprime][jprime]:
                        if inst.feas_gamma[iprime, jprime, i, j, h]:
                            model.addConstr(
                                gamma[iprime, jprime, i, j, h] <= phi[i, j, h],
                                name=f"c22_{i}_{j}_{iprime}_{jprime}_{h}",
                            )

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
                    common_h = (
                        set(inst.H_e[i][j])
                        .intersection(inst.H_e[iprime][jprime])
                        .intersection(inst.H_e[j][iprime])
                    )
                    for h in common_h:
                        if is_precede_possible(i, j, iprime, jprime, h, inst):
                            model.addConstr(
                                alpha[iprime, jprime, h]
                                >= alpha[i, j, h]
                                + inst.O[(inst.f[i, h], inst.f[j, h], h)]
                                + inst.O[(inst.f[j, h], inst.f[iprime, h], h)]
                                - inst.M[7] * (1 - gamma[i, j, iprime, jprime, h]),
                                name=f"c23_{i}_{j}_{iprime}_{jprime}_{h}",
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
                            model.addConstr(
                                alpha[iprime, jprime, h]
                                >= alpha[i, j, h]
                                + inst.O[(inst.f[i, h], inst.f[j, h], h)]
                                + inst.O[(inst.f[j, h], inst.f[iprime, h], h)]
                                - inst.M[7] * (1 - gamma[i, j, iprime, jprime, h]),
                                name=f"c23_{i}_{j}_{iprime}_{jprime}_{h}",
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
                model.addConstr(
                    alpha[i, j, h]
                    >= inst.O[(inst.initial_station, inst.f[i, h], h)]
                    - inst.M[8] * (1 - phi[i, j, h]),
                    name=f"c24_{i}_{j}_{h}",
                )

    """
    Constraints (25):
    - (General case) Lower bound on the times the vehicles arrive at the depot.
    """
    if params.constraints_used_mip[25]:
        for k in inst.K:
            for i in inst.V_d:
                if inst.in_A[i, inst.depot_end]:
                    model.addConstr(
                        tfinal[k]
                        >= t[i]
                        + inst.s[i]
                        + inst.d[i, inst.depot_end, k]
                        - inst.M[2] * (1 - x[i, inst.depot_end, k]),
                        name=f"c25_{i}_{inst.depot_end}_{k}",
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
                        model.addConstr(
                            tfinal[k]
                            >= alpha[i, inst.depot_end, h]
                            + inst.O[(inst.f[i, h], inst.f[inst.depot_end, h], h)]
                            + inst.d_bar[inst.depot_end, h, k]
                            - inst.M[4]
                            * (2 - phi[i, inst.depot_end, h] - x[i, inst.depot_end, k]),
                            name=f"c26_{i}_{inst.depot_end}_{k}_{h}",
                        )

    """
    Constraints (27):
    - Lower bounds on the completion times of the vehicles.
    """
    if params.constraints_used_mip[27]:
        for k in inst.K:
            model.addConstr(C[k] >= tfinal[k] - tstart[k], name=f"c27_{k}")

    """
    Constraints (28):
    - Lower and upper bounds on service start times to respect time windows
    """
    if params.constraints_used_mip[28]:
        for i in inst.V_p_d:
            model.addConstr(
                inst.eprime[i] <= t[i],
                name=f"c28_{i}_earl",
            )
            model.addConstr(
                t[i] <= inst.lprime[i],
                name=f"c28_{i}_lat",
            )

    """
    Constraints (29):
    - Vehicle start time earlier than its end time.
    """
    if params.constraints_used_mip[29]:
        for k in inst.K:
            model.addConstr(tstart[k] <= tfinal[k], name=f"c29_{k}")
