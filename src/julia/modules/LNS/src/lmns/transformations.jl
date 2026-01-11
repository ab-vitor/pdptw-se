function fixMIPSolutionInMIPModel(extld::ExternalLMNSData, inst::InstanceData)
	mipModel = extld.mipModel
	mipSol = extld.mipSol

	tbf = time()
	# for i in inst.Vprime
	# 	for k in inst.K
	# 		fix(mipModel.z[i, k], mipSol.vars.z[i, k])
	# 	end
	# end

	for (i, j) in inst.A
		for k in inst.K
			fix(mipModel.x[i, j, k], mipSol.vars.x[i, j, k])
		end
	end

	for (i, j) in inst.A_m
		for h in inst.H_e[i][j]
			fix(mipModel.phi[i, j, h], mipSol.vars.phi[i, j, h])
		end
	end

	for (i, j) in inst.A_m
		for (iprime, jprime) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
				if (i, j) != (iprime, jprime)
					fix(mipModel.gamma[i, j, iprime, jprime, h], mipSol.vars.gamma[i, j, iprime, jprime, h])
				end
			end
		end
	end

	# bin_vars = [v for v in all_variables(mipModel.model) if is_binary(v)]
	# free_bin_vars = [v for v in all_variables(mipModel.model) if is_binary(v) && !is_fixed(v)]
	# if length(free_bin_vars) < 10
	# 	println(free_bin_vars)
	# end
	# println("Number of bin variables: ", length(bin_vars))
	# println("Number of free and bin variables: ", length(free_bin_vars))

	timeFixingMIPSolution = time() - tbf
	push!(extld.historyLMNSData.timeFixingMIPSolution, timeFixingMIPSolution)
	return mipModel

end # function fixMIPSolutionInMIPModel()

function fixSolutionInMIPModel!(sol::Solution, extld::ExternalLMNSData, inst::InstanceData)::Nothing
	mipModel = extld.mipModel
	tbf = time()

	# for k in inst.K
	# 	rt = sol.vehicles[k]
	# 	for iprime in eachindex(rt)
	# 		i = rt[iprime].node
	# 		fix(mipModel.z[i, k], rt[iprime].load)
	# 	end
	# end

	arcsInSol = Dict{Tuple{Int64, Int64, Int64}, Int64}()
	for k in inst.K
		rt = sol.vehicles[k]
		for iprime in 1:length(rt)-1
			arcsInSol[(k, rt[iprime].node, rt[iprime+1].node)] = 1
		end
	end
	for (i, j) in inst.A
		for k in inst.K
			fix(mipModel.x[i, j, k], get(arcsInSol, (k, i, j), 0))
		end
	end

	phiValues = Dict{Tuple{Int64, Int64, Int64}, Int64}()
	for h in inst.H
		mach = sol.machines[h]
		for iprime in eachindex(mach)
			phiValues[(mach[iprime].orig, mach[iprime].dest, h)] = 1
		end
	end

	for (i, j) in inst.A_m
		for h in inst.H_e[i][j]
			fix(mipModel.phi[i, j, h], get(phiValues, (i, j, h), 0))
		end
	end

	for (i, j) in inst.A_m
		for (iprime, jprime) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
				if (i, j) != (iprime, jprime)
					fix(mipModel.gamma[i, j, iprime, jprime, h], 0)
				end
			end
		end
	end

	for h in inst.H
		mach = sol.machines[h]
		for i in 1:length(mach)-1
			for j in i+1:length(mach)
				if h in intersect(inst.H_e[mach[i].orig][mach[i].dest], inst.H_e[mach[j].orig][mach[j].dest])
					fix(mipModel.gamma[mach[i].orig, mach[i].dest, mach[j].orig, mach[j].dest, h], 1)
				else
					fix(mipModel.gamma[mach[i].orig, mach[i].dest, mach[j].orig, mach[j].dest, h], 0)
				end
			end
		end
	end

	# bin_vars = [v for v in all_variables(mipModel.model) if is_binary(v)]
	# free_bin_vars = [v for v in all_variables(mipModel.model) if is_binary(v) && !is_fixed(v)]
	# if length(free_bin_vars) < 10
	# 	println(free_bin_vars)
	# end
	# println("Number of bin variables: ", length(bin_vars))
	# println("Number of free and bin variables: ", length(free_bin_vars))

	extld.totalTimeFixingSolution += time() - tbf

	return nothing
end # function fixSolutionInMIPModel()
