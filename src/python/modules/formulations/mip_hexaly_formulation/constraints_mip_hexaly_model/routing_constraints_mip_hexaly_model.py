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

    """
    Constraints (1): 
    - Every vehicle departs from the depot
    """
    if params.constraints_used_mip[1]:
        for k in inst.K:
            sumX = model.sum(
                [x[inst.depot_begin, j, k] for j in inst.V_p]
                + [x[inst.depot_begin, inst.depot_end, k]],
            )
            model.constraint(sumX == 1)

    """
    Constraints (2): 
    - Every vehicle leaves a node whenever they arrive at it
    """
    if params.constraints_used_mip[2]:
        for k in inst.K:
            for i in inst.V_p_d:
                sum1 = model.sum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                sum2 = model.sum(x[i, j, k] for j in inst.Vprime if inst.in_A[i, j])
                model.constraint(sum1 - sum2 == 0)

    """
    Constraints (3): 
    - Every vehicle goes back to the depot
    """
    if params.constraints_used_mip[3]:
        for k in inst.K:
            sumX = model.sum(
                [x[j, inst.depot_end, k] for j in inst.V_d]
                + [x[inst.depot_begin, inst.depot_end, k]],
            )
            model.constraint(sumX == 1)

    """
    Constraints (4):
    - Every pickup and delivery node is visited
    """
    if params.constraints_used_mip[4]:
        for i in inst.V_p_d:
            sumX = model.sum(
                x[j, i, k] for k in inst.K for j in inst.Vprime if inst.in_A[j, i]
            )
            model.constraint(sumX == 1)

    """
    Constraints (5):
    - The pickup and delivery nodes corresponding to a given request are visited
    by the same vehicle
    """
    if params.constraints_used_mip[5]:
        for k in inst.K:
            for i in inst.V_p:
                sum1 = model.sum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                sum2 = model.sum(
                    x[j, inst.n + i, k] for j in inst.Vprime if inst.in_A[j, i + inst.n]
                )
                model.constraint(sum1 == sum2)

    """
    Constraints (6):
    - The vehicles are empty at the depot
    """
    if params.constraints_used_mip[6]:
        for k in inst.K:
            model.constraint(z[inst.depot_begin, k] == 0)

    """
    Constraints (7):
    - The vehicles cargo weights are updated whenever they go from one node 
    to another (Lower bound)
    """
    if params.constraints_used_mip[7]:
        for k in inst.K:
            for i, j in inst.A:
                model.constraint(
                    z[j, k] >= z[i, k] + inst.q[j] - inst.M[1] * (1 - x[i, j, k])
                )

    """
    Constraints (8):
    - The vehicles cargo weights are updated whenever they go from one node 
    to another (Upper bound)
    """
    if params.constraints_used_mip[8]:
        for k in inst.K:
            for i, j in inst.A:
                model.constraint(
                    z[j, k] <= z[i, k] + inst.q[j] + inst.M[1] * (1 - x[i, j, k])
                )

    """
    Constraints (9):
    - Their cargo weights never exceeds their capacities
    """
    if params.constraints_used_mip[9]:
        for k in inst.K:
            for i in inst.V_p_d:
                sumX = model.sum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                rhs = min(inst.Q[k], max(0, inst.Q[k] + inst.q[i])) * sumX
                model.constraint(z[i, k] <= rhs)

    """
    Constraints (10):
    - The weights of every visited node are taken into account
    """
    if params.constraints_used_mip[10]:
        for k in inst.K:
            for i in inst.V_p:
                sumX = model.sum(x[j, i, k] for j in inst.Vprime if inst.in_A[j, i])
                model.constraint(z[i, k] >= inst.q[i] * sumX)
