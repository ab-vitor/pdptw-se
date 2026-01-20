from gurobipy import Model, GRB, tupledict


def mip_gurobi_objective_function(model: Model, C: tupledict) -> None:
    """
    Set the MIP's objective to minimize the total C[k] across all vehicles k.
    """
    model.setObjective(C.sum(), GRB.MINIMIZE)
