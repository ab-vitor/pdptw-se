function updateCurrentResults!(extld::ExternalLMNSData, inst::InstanceData, allParams::AllParams)::Nothing
	extld.mipSolB = extld.mipSolT
	update_offset = extld.iteration - extld.iterationToBest
	extld.largestUpdateOffset = max(extld.largestUpdateOffset, update_offset)

	extld.iterationToBest = extld.iteration
	extld.timeToBest = time() - extld.startTime
    extld.countImprovements += 1
	idop = Int(extld.destroyOperator)
	extld.countImprovementsPerOperator[idop] += 1

	@printf(
		"* %.2f;%d;%.6f\n",
		extld.mipSolT.stats.objValue,
		extld.iterationToBest,
		extld.timeToBest
	)


	push!(extld.historyLMNSData.objValues, extld.mipSolB.stats.objValue)
	# extld.bestSol = createSolutionMelo(inst, extld.mipSolB, allParams.general)
	# suff = string("_", extld.destroyOperator, "_", extld.countImprovementsPerOperator[Int(extld.destroyOperator)])
	# saveSolutionTimeline(extld.bestSol, inst, allParams.general, suff)
    return nothing
end
