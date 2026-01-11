function meloWarmStartGreedyHeuristic(
	env::Union{Gurobi.Env, Nothing},
	inst::InstanceData,
	params::ParameterData,
	mipModel::MIPModel,
)::Nothing
	println("\n[$(Dates.Time(Dates.now()))] Running Multistart LP for warm start")
	sol = Multistart.multistartlp(env, inst, params)

	arcsInSol = Dict{Tuple{Int64, Int64, Int64}, Int64}()
	for k in inst.K
		rt = sol.vehicles[k]
		for iprime in 1:length(rt)-1
			arcsInSol[(k, rt[iprime].node, rt[iprime+1].node)] = 1
		end
	end
	for (i, j) in inst.A
		for k in inst.K
			set_start_value(mipModel.x[i, j, k], get(arcsInSol, (k, i, j), 0))
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
			set_start_value(mipModel.phi[i, j, h], get(phiValues, (i, j, h), 0))
		end
	end

	for (i, j) in inst.A_m
		for (iprime, jprime) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
				if (i, j) != (iprime, jprime)
					set_start_value(mipModel.gamma[i, j, iprime, jprime, h], 0)
				end
			end
		end
	end

	for h in inst.H
		mach = sol.machines[h]
		for i in 1:length(mach)-1
			for j in i+1:length(mach)
				if h in intersect(inst.H_e[mach[i].orig][mach[i].dest], inst.H_e[mach[j].orig][mach[j].dest])
					set_start_value(mipModel.gamma[mach[i].orig, mach[i].dest, mach[j].orig, mach[j].dest, h], 1)
				else
					set_start_value(mipModel.gamma[mach[i].orig, mach[i].dest, mach[j].orig, mach[j].dest, h], 0)
				end
			end
		end
	end
end # function meloWarmStartGreedyHeuristic()