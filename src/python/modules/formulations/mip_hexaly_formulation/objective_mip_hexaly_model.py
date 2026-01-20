from hexaly.optimizer import HxModel, HxExpression
from modules.data import InstanceData

def mip_hexaly_objective_function(
    model: HxModel, inst: InstanceData, C: dict[tuple, HxExpression]
) -> None:
    """
    Set the MIP's objective to minimize the total C[k] across all vehicles k.
    """
    total_completion_time = model.sum([C[(k)] for k in inst.K])
    model.minimize(total_completion_time)
