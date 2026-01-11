function remove_randomly!(v::Vector{Int64}, rng::Random.MersenneTwister)::Int64
	idx = rand(rng, 1:length(v))
	return splice!(v, idx)
end # function remove_randomly!()

function removeVarsVehicleDepotToDepot!(extld::ExternalLMNSData, inst::InstanceData, numDestroyedVars::Ref{Int64})::Nothing
	mipModel = extld.mipModel
	for k in inst.K
		if is_fixed(mipModel.x[inst.depot_begin, inst.depot_end, k])
			value = fix_value(mipModel.x[inst.depot_begin, inst.depot_end, k])
			unfix(mipModel.x[inst.depot_begin, inst.depot_end, k])
			set_start_value(mipModel.x[inst.depot_begin, inst.depot_end, k], value)
			numDestroyedVars[] += 1
		end
	end
	return nothing
end

function removeVehicleVarsRelatedToJobs!(
	jobs::Vector{Int64},
	extld::ExternalLMNSData,
	inst::InstanceData,
	numDestroyedVars::Ref{Int64},
	isMIPStartApplied::Bool = true,
)::Nothing
	mipModel = extld.mipModel

	for (i, j) in inst.A
		if i in jobs || j in jobs
			# remove arcs in x related to jobs
			for k in inst.K
				if is_fixed(mipModel.x[i, j, k])
					value = isMIPStartApplied ? fix_value(mipModel.x[i, j, k]) : nothing
					unfix(mipModel.x[i, j, k])
					set_start_value(mipModel.x[i, j, k], value)
					numDestroyedVars[] += 1
				end
			end
		end
	end
	return nothing
end

function removeMachineVarsRelatedToJobs!(
	jobs::Vector{Int64},
	extld::ExternalLMNSData,
	inst::InstanceData,
	numDestroyedVars::Ref{Int64},
	isMIPStartApplied::Bool = true,
)::Nothing
	mipModel = extld.mipModel
	for (i, j) in inst.A_m
		if i in jobs || j in jobs
			# remove precedence between machine travels involving jobs
			for (iprime, jprime) in inst.A_m
				if (i, j) != (iprime, jprime)
					if iprime in jobs || jprime in jobs
						for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
							if is_fixed(mipModel.gamma[i, j, iprime, jprime, h])
								value = isMIPStartApplied ? fix_value(mipModel.gamma[i, j, iprime, jprime, h]) : nothing
								unfix(mipModel.gamma[i, j, iprime, jprime, h])
								set_start_value(mipModel.gamma[i, j, iprime, jprime, h], value)
								numDestroyedVars[] += 1
							end
						end
					end
				end
			end

			# remove arcs in phi related to jobs
			for h in inst.H_e[i][j]
				if is_fixed(mipModel.phi[i, j, h])
					value = isMIPStartApplied ? fix_value(mipModel.phi[i, j, h]) : nothing
					unfix(mipModel.phi[i, j, h])
					set_start_value(mipModel.phi[i, j, h], value)
					numDestroyedVars[] += 1
				end
			end
		end
	end
	return nothing
end

function removeVarsRelatedToJobs!(
	jobs::Vector{Int64},
	extld::ExternalLMNSData,
	inst::InstanceData,
	numDestroyedVars::Ref{Int64},
	isMIPStartApplied::Bool = true,
)::Nothing
	removeVehicleVarsRelatedToJobs!(jobs, extld, inst, numDestroyedVars, isMIPStartApplied)
	removeMachineVarsRelatedToJobs!(jobs, extld, inst, numDestroyedVars, isMIPStartApplied)
	return nothing
end

function removeMachineVars!(
	extld::ExternalLMNSData,
	inst::InstanceData,
	numDestroyedVars::Ref{Int64},
	isMIPStartApplied::Bool = true,
)::Nothing
	mipModel = extld.mipModel
	for (i, j) in inst.A_m
		# remove precedence between machine travels
		for (iprime, jprime) in inst.A_m
			if (i, j) != (iprime, jprime)
				for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
					if is_fixed(mipModel.gamma[i, j, iprime, jprime, h])
						value = isMIPStartApplied ? fix_value(mipModel.gamma[i, j, iprime, jprime, h]) : nothing
						unfix(mipModel.gamma[i, j, iprime, jprime, h])
						set_start_value(mipModel.gamma[i, j, iprime, jprime, h], value)
						numDestroyedVars[] += 1
					end
				end
			end
		end

		# remove arcs in phi 
		for h in inst.H_e[i][j]
			if is_fixed(mipModel.phi[i, j, h])
				value = isMIPStartApplied ? fix_value(mipModel.phi[i, j, h]) : nothing
				unfix(mipModel.phi[i, j, h])
				set_start_value(mipModel.phi[i, j, h], value)
				numDestroyedVars[] += 1
			end
		end
	end
	return nothing
end

function getNextNodeRoute(i::Int64, k::Int64, inst::InstanceData, model::MIPModel)::Int64
	for j in inst.Vprime
		if (i, j) in inst.A && is_fixed(model.x[i, j, k]) && fix_value(model.x[i, j, k]) == 1
			return j
		end
	end
	return 0 # should never happen in a feasible solution
end

function createVehicle(
	k::Int64,
	inst::InstanceData,
	model::MIPModel,
)::Vector{Int64}
	vehicle = Int64[]

	i = inst.depot_begin
	push!(vehicle, i)
	j = getNextNodeRoute(i, k, inst, model)
	while j != inst.depot_end
		push!(vehicle, j)
		i = j
		j = getNextNodeRoute(i, k, inst, model)
	end
	push!(vehicle, j)
	return vehicle
end

function createVehicles(
	inst::InstanceData,
	model::MIPModel,
)::Vector{Vector{Int64}}
	vehicles = Vector{Int64}[]

	for k in inst.K
		vehicle = createVehicle(k, inst, model)
		push!(vehicles, vehicle)
	end
	return vehicles
end

function printStatusVars(mipModel::MIPModel, numDestroyedVars::Ref{Int64})
	bin_vars = [v for v in all_variables(mipModel.model) if is_binary(v)]
	fixed_bin_vars = [v for v in all_variables(mipModel.model) if is_binary(v) && is_fixed(v)]
	# if length(fixed_bin_vars) < 10
	# 	println("\t-> fixed vars", fixed_bin_vars)
	# end
	println("\t-> Number of binary variables: ", length(bin_vars))
	println("\t-> Number of fixed and binary variables: ", length(fixed_bin_vars))
	println("\t-> numDestroyedVars[] = ", numDestroyedVars[])
end