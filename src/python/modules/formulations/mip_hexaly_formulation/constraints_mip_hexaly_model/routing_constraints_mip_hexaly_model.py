from modules.data import InstanceData
from modules.parameters import ParameterData
from hexaly.optimizer import HxModel
from ..entities_mip_hexaly_formulation import MIPHxRoutingVars


def mip_hexaly_routing_constraints(
    inst: InstanceData, params: ParameterData, model: HxModel, rtvars: MIPHxRoutingVars
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
            sumX = model.sum(
                x[j, i, k] for k in inst.K for j in inst.Vprime if inst.in_A[j, i]
            )
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
