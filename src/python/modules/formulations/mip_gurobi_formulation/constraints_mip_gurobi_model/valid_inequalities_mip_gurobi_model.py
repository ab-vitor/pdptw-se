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
from ..entities import MIPGrbRoutingVariables, MIPGrbSchedulingVariables


@indent_prints
def mip_gurobi_valid_inequalities(
    inst: InstanceData,
    model: Model,
    params: ParameterData,
    rtvars: MIPGrbRoutingVariables,
    schvars: MIPGrbSchedulingVariables,
) -> None:
    x = rtvars.x
    t = schvars.t
    alpha = schvars.alpha
    phi = schvars.phi
    gamma = schvars.gamma

    """
    Constraints (35):
    - Each vehicle cannot be inactive and also serve a pickup/delivery node.
    """
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

    """
    Constraints (36):
    - (P&D vehicle) Each edge can only be traversed in one direction
    """
    if params.constraints_used_mip[36]:
        count = 0
        for i, j in combinations(inst.V_p_d, 2):
            if inst.in_A[i, j] and inst.in_A[j, i]:
                count += 1
                sum1 = quicksum(x[i, j, k] for k in inst.K)
                sum2 = quicksum(x[j, i, k] for k in inst.K)
                model.addConstr(sum1 + sum2 <= 1, name=f"c36_{i}_{j}")

        print(f"Number of c36 constraints added: {count}")

    """
    Constraints (37):
    - (Machine) Each edge can only be traversed in one direction
    """
    if params.constraints_used_mip[37]:
        count = 0
        for i, j in combinations(inst.V_p_d, 2):
            if inst.in_A_m[i, j] and inst.in_A_m[j, i]:
                count += 1
                sum1 = quicksum(phi[i, j, h] for h in inst.H_e[i][j])
                sum2 = quicksum(phi[j, i, h] for h in inst.H_e[j][i])
                model.addConstr(sum1 + sum2 <= 1, name=f"c37_{i}_{j}")

        print(f"Number of c37 constraints added: {count}")

    """
    Constraints (38):
    - Only one arc can precede the other.
    """
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

    """
    Constraints (39):
    - No path of length w is assigned to a vehicle when the destination 
    node is not reachable within its time window.
    """
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

    """
    Constraints (40):
    - No path of length w composed of arcs in A^m has all its arcs assigned to
    any machine when the destination node is not reachable within its time window for every k ∈ K.
    """
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

    """
    Constraints (41):
    - A lower bound on the start time of the service at a pickup/delivery node.
    """
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

    """
    Constraints (42):
    - Lower bound on the start time of a machine travel based on the time windows
    of the arc nodes.
    - Notice that, given an arc (i, j) in A^m and a machine h ∈ H_{ij}, the variable 
    alpha^h_ij can assume any value when phi^h_{ij} = 0, because it is not taken 
    into account in a feasible solution.
    - Besides, observe that these inequalities are only valid after the 
    preprocessing step on set H_{ij} (see Section 4.4).
    """
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

    """
    Constraints (43):
    - Upper bound on the start time of a machine travel based on the time windows
    of the arc nodes.
    - Notice that, given an arc (i, j) in A^m and a machine h ∈ H_{ij}, the variable 
    alpha^h_ij can assume any value when phi^h_{ij} = 0, because it is not taken 
    into account in a feasible solution.
    - Besides, observe that these inequalities are only valid after the 
    preprocessing step on set H_{ij} (see Section 4.4).
    """
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

    """
    Constraints (44):
    - Similar to constraints (42), but now they include the distinct traversal times 
    of the vehicles.
    - For vehicles with equal traversal times, constraints (42) dominate constraints (44).
    - However, this is not the case when dealing with vehicles with distinct traversal times.
    """
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

    """
    Constraints (45):
    - Similar to constraints (43), but now they include the distinct traversal times 
    of the vehicles.
    - For vehicles with equal traversal times, constraints (43) dominate constraints (45).
    - However, this is not the case when dealing with vehicles with distinct traversal times.
    """
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

    """
    Constraints (46):
    - Denote by mi^h_{iji'} in {0, 1} the constant indicator that is equal to one 
    if the minimum arrival time of a vehicle at machine h coming from node i' 
    (e'_{i'} + s_{i'} + min_{k in K} {d_bar^k_{i′ h}) is greater than or equal to 
    the maximum arrival time of the machine h after traversing arc (i, j) 
    (l'_{j} − min_{k in K} {d_bar^k_{jh} + O^h_{f^h_j f^h_{i'}}), otherwise,
    it is zero. 
    - Hence, the constraints enforce that the start time to use a machine h 
    in a certain arc (i', j') in A^m must always precede the start time to 
    use a machine h in another arc (i, j) in A^m when mi^h_{iji'} = 1.
    """
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
