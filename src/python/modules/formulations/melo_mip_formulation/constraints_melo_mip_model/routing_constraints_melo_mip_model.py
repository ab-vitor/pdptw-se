from gurobipy import Model, quicksum

from modules.data import InstanceData
from modules.parameters import ParameterData
from ..entities import MIPRoutingVariables


def melo_routing_constraints(
    inst: InstanceData, params: ParameterData, model: Model, rtvars: MIPRoutingVariables
) -> None:
    x = rtvars.x
    z = rtvars.z

    """
    Add the routing constraints c1–c10 to `model`.
    """

    # c1
    if params.constraints_used_melo_mip[1]:
        for k in inst.K:
            sumX = quicksum(x[inst.depot_begin, j, k] for j in inst.V_p)
            sumX += x[inst.depot_begin, inst.depot_end, k]
            model.addConstr(sumX == 1, name=f"c1_{k}")

    # c2
    if params.constraints_used_melo_mip[2]:
        for k in inst.K:
            for i in inst.V_p_d:
                sum1 = quicksum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                sum2 = quicksum(x[i, j, k] for j in inst.Vprime if inst.in_A[i, j])
                model.addConstr(sum1 - sum2 == 0, name=f"c2_{i}_{k}")

    # c3
    if params.constraints_used_melo_mip[3]:
        for k in inst.K:
            sumX = quicksum(x[j, inst.depot_end, k] for j in inst.V_d)
            sumX += x[inst.depot_begin, inst.depot_end, k]
            model.addConstr(sumX == 1, name=f"c3_{k}")

    # c4
    if params.constraints_used_melo_mip[4]:
        for i in inst.V_p_d:
            sumX = quicksum(
                x[j, i, k] for k in inst.K for j in inst.Vprime if inst.in_A[j, i]
            )
            model.addConstr(sumX == 1, name=f"c4_{i}")

    # c5
    if params.constraints_used_melo_mip[5]:
        for k in inst.K:
            for i in inst.V_p:
                sum1 = quicksum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                sum2 = quicksum(
                    x[j, inst.n + i, k] for j in inst.Vprime if inst.in_A[j, i + inst.n]
                )
                model.addConstr(sum1 == sum2, name=f"c5_{i}_{k}")

    # c6
    if params.constraints_used_melo_mip[6]:
        for k in inst.K:
            model.addConstr(z[inst.depot_begin, k] == 0, name=f"c6_{k}")

    # c7
    if params.constraints_used_melo_mip[7]:
        for k in inst.K:
            for i, j in inst.A:
                model.addConstr(
                    z[j, k] >= z[i, k] + inst.q[j] - inst.M[1] * (1 - x[i, j, k]),
                    name=f"c7_{i}_{j}_{k}",
                )

    # c8
    if params.constraints_used_melo_mip[8]:
        for k in inst.K:
            for i, j in inst.A:
                model.addConstr(
                    z[j, k] <= z[i, k] + inst.q[j] + inst.M[1] * (1 - x[i, j, k]),
                    name=f"c8_{i}_{j}_{k}",
                )

    # c9
    if params.constraints_used_melo_mip[9]:
        for k in inst.K:
            for i in inst.V_p_d:
                sumX = quicksum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                rhs = min(inst.Q[k], max(0, inst.Q[k] + inst.q[i])) * sumX
                model.addConstr(z[i, k] <= rhs, name=f"c9_{i}_{k}")

    # c10
    if params.constraints_used_melo_mip[10]:
        for k in inst.K:
            for i in inst.V_p:
                sumX = quicksum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                model.addConstr(z[i, k] >= inst.q[i] * sumX, name=f"c10_{i}_{k}")
