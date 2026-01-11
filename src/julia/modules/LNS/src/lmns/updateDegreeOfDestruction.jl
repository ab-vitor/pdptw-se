function updateDegreeOfDestruction!(
	extld::ExternalLMNSData,
	allParams::AllParams,
)::Nothing
	ddp = allParams.dgd
	repairTime = allParams.general.lmnsRepairTime
	perc = 0.9
	idop = Int(extld.destroyOperator)
	if extld.psi[idop] == ddp.maxPsi[idop] || extld.mipSolT.stats.status == TIME_LIMIT
		extld.delta[idop] = -1
		println("Setting delta[$(extld.destroyOperator)] to -1.")
	elseif extld.psi[idop] == ddp.minPsi[idop] ||
		   (extld.mipSolT.stats.status == OPTIMAL && extld.historyLMNSData.timeRepair[end] <= perc * repairTime)
		extld.delta[idop] = 1
		println("Setting delta[$(extld.destroyOperator)] to +1.")
	end

	extld.psi[idop] += extld.delta[idop]
	extld.psi[idop] = max(extld.psi[idop], ddp.minPsi[idop])

	# if extld.mipSolT.stats.gap < ddp.gapToBiggerDestruction
	# 	extld.psi[idop] += 1
	# 	extld.psi[idop] = min(extld.psi[idop], extld.maxPsi[idop])
	# 	println("Increasing degree of destruction to ", extld.psi[idop])
	# elseif extld.iterationToBest != extld.iteration && extld.mipSolT.stats.gap > ddp.gapToSmallerDestruction
	# 	extld.psi[idop] -= 1
	# 	extld.psi[idop] = max(extld.psi[idop], 1)
	# 	println("Decreasing degree of destruction to ", extld.psi[idop])
	# end
	return nothing
end

function decreaseDegreeOfDestruction!(
	extld::ExternalLMNSData,
	ddp::DegreeDestructionParams,
)::Nothing
	idop = Int(extld.destroyOperator)
	extld.psi[idop] -= 1
	extld.psi[idop] = max(extld.psi[idop], ddp.minPsi)
	println("Decreasing degree of destruction to $(extld.psi[idop]).")
	return nothing
end