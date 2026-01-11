function hillClimbing(extld::ExternalLMNSData, hcp::HillClimbingParams)
	return extld.mipSolT.stats.objValue + hcp.epsilon < extld.mipSol.stats.objValue
end

function metropolis(extld::ExternalLMNSData, mp::MetropolisParams)
	fn = extld.mipSolT.stats.objValue
	fs = extld.mipSol.stats.objValue
	isAccepted = false
	if fn < fs || rand(mp.rng) <= exp(-(fn - fs) / mp.temp)
		isAccepted = true
	end
	return isAccepted
end

function simulatedAnnealing!(extld::ExternalLMNSData, sp::SimulatedAnnealingParams)
	fn = extld.mipSolT.stats.objValue
	fs = extld.mipSol.stats.objValue
	isAccepted = false
	if fn < fs || rand(mp.rng) <= exp(-(fn - fs) / sp.temp)
		isAccepted = true
	end
	sp.temp *= sp.cool
	return isAccepted
end
