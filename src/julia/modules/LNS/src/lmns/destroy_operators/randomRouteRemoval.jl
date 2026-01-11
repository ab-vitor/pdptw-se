function randomRouteRemoval!(extld::ExternalLMNSData, inst::InstanceData, allParams::AllParams)::Nothing
	idop = Int(extld.destroyOperator)
	psi = extld.psi[idop]
	mipModel = extld.mipModel
	routeOptions = Int64[]
	ddp = allParams.dgd

	println("-----------## Performing route removals | psi = $(psi) ##------------")
	
	for k in inst.K
		if is_fixed(mipModel.x[inst.depot_begin, inst.depot_end, k]) && fix_value(mipModel.x[inst.depot_begin, inst.depot_end, k]) == 0
			push!(routeOptions, k)
		end
	end
	restrictedRouteOptions = shuffle(ddp.rng, routeOptions)
	activeRoutes = length(restrictedRouteOptions)
	extld.psi[idop] = min(extld.psi[idop], activeRoutes)
	extld.lastActiveRoutes = activeRoutes
	println("\t-> Active routes: $(activeRoutes)")
	println("\t-> Number of route removals: $(extld.psi[idop])")


	# rt_ids = sort(restrictedRouteOptions[1:psi])
	# hash_rt_ids = hash(rt_ids)
	# while haskey(extld.tabuList[idop], psi) && hash_rt_ids in extld.tabuList[idop][psi]
	# 	restrictedRouteOptions = shuffle(ddp.rng, routeOptions)
	# 	rt_ids = sort(restrictedRouteOptions[1:psi])
	# 	hash_rt_ids = hash(rt_ids)
	# end
	# push!(extld.tabuList[idop][psi], hash_rt_ids)

	numDestroyedVars = Ref{Int64}(0)
	println("\t-> Removing vars related to inst.depot_begin -> inst.depot_end")
	removeVarsVehicleDepotToDepot!(extld, inst, numDestroyedVars)
	jobs = Int64[]
	for iprime in 1:psi
		k = restrictedRouteOptions[iprime]
		vehicle = createVehicle(k, inst, mipModel)
		jobs_route_k = vehicle[2:end-1]
		append!(jobs, jobs_route_k)
	end
	println("\t-> Removing vars related to jobs: $(jobs) length = $(length(jobs))")
	removeVarsRelatedToJobs!(jobs, extld, inst, numDestroyedVars)

	push!(extld.historyLMNSData.numDestroyedVars, numDestroyedVars[])

	printStatusVars(mipModel, numDestroyedVars)
	return nothing
end
