function updateCurrentResults!(extmd::ExternalMSLPData, _::AllParams)::Nothing
	# extmd.timeToBest = (CPUtime_us() - extmd.startTime) / 1e6
	extmd.timeToBest = cpu_times()[1] - extmd.startTime
	extmd.iterationToBest = extmd.iteration
	extmd.bestSol = extmd.currSol
	update_offset = extmd.iteration - extmd.iterationToBest
	extmd.largestUpdateOffset = max(extmd.largestUpdateOffset, update_offset)
	extmd.countImprovements += 1

	@printf(
		"%.2f;%.2f;%d;%.6f\n",
		extmd.bestSol.value,
		extmd.lastSGreedySolValue,
		extmd.iteration,
		extmd.timeToBest
	)
    return nothing
end
