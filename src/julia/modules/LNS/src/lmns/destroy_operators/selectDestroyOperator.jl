function selectDestroyOperator!(extld::ExternalLMNSData, ddp::DegreeDestructionParams)::Nothing
	extld.destroyOperatorFunction!, extld.destroyOperator =
		rand(ddp.rng, extld.destroyOptions)
	idop = Int(extld.destroyOperator)
	extld.countExecutionsPerOperator[idop] += 1
	return nothing
end
