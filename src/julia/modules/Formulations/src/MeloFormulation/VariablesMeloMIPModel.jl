function meloRoutingVariables(inst::InstanceData, model::Model)
	@variable(model,
		x[i = inst.Vprime, j = inst.Vprime, k = inst.K;
			(i, j) in inst.A],
		binary = true
	)
	# @variable(model, 0 <= x[i = inst.Vprime, j = inst.Vprime, k = inst.K; (i, j) in inst.A] <= 1)
	# @variable(model, z[i = inst.Vprime, k = inst.K] >= 0, Int)
	@variable(model, z[i = inst.Vprime, k = inst.K] >= 0)

	return x, z
end # function meloRoutingVariables()

function isPrecedePossible(i::Int64, j::Int64, iprime::Int64, jprime::Int64, h::Int64, inst::InstanceData)::Bool
	return (
		inst.eprime[i] + inst.s[i] + inst.d_bar_min[i, h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.O[(inst.f[j][h], inst.f[iprime][h], h)] <=
		inst.lprime[jprime] - inst.d_bar_min[jprime, h] - inst.O[(inst.f[iprime][h], inst.f[jprime][h], h)]
	)
end

function meloSchedulingVariables(inst::InstanceData, model::Model)
	Lb = inst.e[inst.depot_begin]
	Le = inst.l[inst.depot_begin]

	@variable(model, Le >= t[i = inst.V_p_d] >= Lb)
	@variable(model, Le >= tstart[k = inst.K] >= Lb)
	@variable(model, Le >= tfinal[k = inst.K] >= Lb)
	@variable(model, Le >= C[k = inst.K] >= Lb)
	@variable(model,
		phi[i = inst.Vprime, j = inst.Vprime, h = inst.H_e[i][j];
			((i, j) in inst.A_m)],
		binary = true
	)
	# @variable(model, 0 <= phi[i = inst.Vprime, j = inst.Vprime, h = inst.H_e[i][j]; ((i, j) in inst.A_m)] <= 1)
	@variable(
		model,
		gamma[
			i = inst.Vprime,
			j = inst.Vprime,
			iprime = inst.Vprime,
			jprime = inst.Vprime,
			h = intersect(inst.H_e[i][j], inst.H_e[iprime][jprime]);
			((i, j) in inst.A_m) && ((iprime, jprime) in inst.A_m) && (i, j) != (iprime, jprime) #&&
			#isPrecedePossible(i, j, iprime, jprime, h, inst),
		],
		binary = true
	)

	nbGammaBefore = 0
	nbGammaFixed = 0
	for i in inst.Vprime, j in inst.Vprime, iprime in inst.Vprime, jprime in inst.Vprime
		for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
			if ((i, j) in inst.A_m) && ((iprime, jprime) in inst.A_m) && (i, j) != (iprime, jprime)
				nbGammaBefore += 1
				if !isPrecedePossible(i, j, iprime, jprime, h, inst)
					fix(gamma[i, j, iprime, jprime, h], 0)
					nbGammaFixed += 1
				end
			end
		end
	end

	# @variable(
	# 	model,
	# 	0 <=
	# 	gamma[i = inst.Vprime, j = inst.Vprime, iprime = inst.Vprime, jprime = inst.Vprime,
	# 		h = intersect(inst.H_e[i][j], inst.H_e[iprime][jprime]);
	# 		((i, j) in inst.A_m) && ((iprime, jprime) in inst.A_m) && (i, j) != (iprime, jprime)] <= 1
	# )
	@variable(model, Le >= alpha[i = inst.Vprime, j = inst.Vprime, h = inst.H_e[i][j]; (i, j) in inst.A_m] >= Lb)
	println()
	println("### Pre-processing - fixing gamma variables ###")
	println("\t-> Fixed $(nbGammaFixed)/$(nbGammaBefore) ($(round(nbGammaFixed/nbGammaBefore*100, digits=2))%) gamma variables to zero (impossible precedence)")
	println("\t-> Total number of variables: $(num_variables(model))")

	bin_vars = [v for v in all_variables(model) if is_binary(v)]
	not_fixed_bin_vars = [v for v in all_variables(model) if is_binary(v) && !is_fixed(v)]
	println("\t-> Number of binary variables: ", length(bin_vars))
	println("\t-> Number of binary variables not fixed: ", length(not_fixed_bin_vars))
	
	println()
	return t, tstart, tfinal, C, phi, gamma, alpha
end # function meloSchedulingVariables()
