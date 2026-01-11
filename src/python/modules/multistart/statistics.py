from .entities_mslp import ExternalMSLPData


def print_stats(extmd: ExternalMSLPData) -> None:
    print(f"Best solution value: {extmd.best_sol.value:.2f}")
    print(f"Total time elapsed: {extmd.totalTimeElapsed:.6f}")
    print(f"Time to best: {extmd.time_to_best:.6f}")
    print(f"Iterations: {extmd.iteration}")
    print(f"Iterations to best: {extmd.iterationToBest}")
    print(f"Infeasible solutions percentage: {extmd.percentageInfeasibleSol:.4f}")
    print(
        f"(LP improvements)/(LP runs) = {extmd.lpImpr}/{extmd.lpRuns} = {extmd.percentageLPImpr:.4f}"
    )
    print(f"Mean LP improvement percentage: {extmd.meanLPImprPercentage:.4f}")


def calculate_stats(extmd: "ExternalMSLPData") -> None:
    if extmd.iteration > 0:
        extmd.percentageInfeasibleSol = round(
            (extmd.infeasibleSol / extmd.iteration) * 100, 4
        )
    else:
        extmd.percentageInfeasibleSol = 0.0

    extmd.percentageLPImpr = round((extmd.lpImpr / max(1, extmd.lpRuns)) * 100, 4)
    extmd.meanLPImprPercentage = round(
        (extmd.sumLPImprPercentage / max(1, extmd.lpRuns)) * 100, 4
    )
