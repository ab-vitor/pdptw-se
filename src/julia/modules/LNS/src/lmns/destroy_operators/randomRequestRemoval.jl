function selectJobs(psi::Int64, inst::InstanceData, rng::Random.MersenneTwister)
	requests = copy(inst.V_p)
	S = Int64[]
	for _ in range(1, psi)
		r = remove_randomly!(requests, rng)
		push!(S, r)
		push!(S, r + inst.n)
	end

	return S
end # function selectJobs()

function randomRequestRemoval!(extld::ExternalLMNSData, inst::InstanceData, allParams::AllParams)::Nothing
	idop = Int(extld.destroyOperator)
	psi = extld.psi[idop]
	ddp = allParams.dgd
	
	println("-----------## Performing request removals | psi = $(psi) ##------------")

	jobs = selectJobs(psi, inst, ddp.rng)
	# jobs = sort(selectJobs(psi, inst, ddp.rng))
	# hash_jobs = hash(jobs)
	# while haskey(extld.tabuList[idop], psi) && hash_jobs in extld.tabuList[idop][psi]
	# 	jobs = sort(selectJobs(psi, inst, ddp.rng))
	# 	hash_jobs = hash(jobs)
	# end
	# push!(extld.tabuList[idop][psi], hash_jobs)

	mipModel = extld.mipModel

	numDestroyedVars = Ref{Int64}(0)
	println("\t-> Removing vars related to inst.depot_begin -> inst.depot_end")
	removeVarsVehicleDepotToDepot!(extld, inst, numDestroyedVars)
	println("\t-> Removing vars related to jobs: $(jobs) length = $(length(jobs)). Apply MIP start? $(allParams.reqr.applyMIPStart)")
	removeVarsRelatedToJobs!(jobs, extld, inst, numDestroyedVars, allParams.reqr.applyMIPStart)

	push!(extld.historyLMNSData.numDestroyedVars, numDestroyedVars[])

	printStatusVars(mipModel, numDestroyedVars)


	return nothing
end # function destroy()