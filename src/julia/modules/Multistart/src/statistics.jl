function printStats(extmd::ExternalMSLPData)::Nothing
	@printf("Best solution value: %.2f\n", extmd.bestSol.value)
	@printf("Total time elapsed: %.6f\n", extmd.totalTimeElapsed)
	@printf("Time to best: %.6f\n", extmd.timeToBest)
	@printf("Iterations: %d\n", extmd.iteration)
	@printf("Iterations to best: %d\n", extmd.iterationToBest)
	@printf("Improvements: %d\n", extmd.countImprovements)
	@printf("Infeasible solutions percentage: (%d / %d) = %.4f %%\n", extmd.infeasibleSol, extmd.iteration, extmd.percentageInfeasibleSol)
	@printf("(LP improvements)/(LP runs) = %d/%d = %.4f %%\n", extmd.lpImpr, extmd.lpRuns, extmd.percentageLPImpr)
	@printf("Mean LP improvement percentage: %.4f %%\n", extmd.meanLPImprPercentage)

	return nothing
end

function calculateStats(extmd::ExternalMSLPData)::Nothing
	extmd.percentageInfeasibleSol = round(extmd.infeasibleSol / (extmd.iteration) * 100, digits = 4)
	extmd.percentageLPImpr = round(extmd.lpImpr / max(1, extmd.lpRuns) * 100, digits = 4)
	extmd.meanLPImprPercentage = round(extmd.sumLPImprPercentage / max(1, extmd.lpRuns) * 100, digits = 4)
	return nothing
end
