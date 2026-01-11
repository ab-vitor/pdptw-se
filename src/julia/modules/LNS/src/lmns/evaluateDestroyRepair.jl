function evaluateDestroyRepair!(
	extld::ExternalLMNSData,
	inst::InstanceData,
	allParams::AllParams,
)::Nothing
	ddp = allParams.dgd
	if extld.destroyOperator == RANDOM_ROUTE_REMOVAL
		idop = Int(extld.destroyOperator)
		if extld.mipSolT.stats.status == OPTIMAL && extld.psi[idop] == extld.lastActiveRoutes
			println("Proved optimality by route removal!")
			extld.provedOptimality = true
		end
	else
		idop = Int(extld.destroyOperator)
		if extld.mipSolT.stats.status == OPTIMAL && extld.psi[idop] == ddp.psiOpt[idop]
			println("Proved optimality by request removal!")
			extld.provedOptimality = true
		end
	end
	if extld.iteration % 1 == 0
		updateDegreeOfDestruction!(extld, allParams)
	end

	return nothing
end
