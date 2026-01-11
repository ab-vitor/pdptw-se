function meloRoutingConstraints(
	inst::InstanceData,
	params::ParameterData,
	model::Model,
	x::Containers.SparseAxisArray,
	z::Containers.DenseAxisArray,
)
	# c1
	for k in inst.K
		sumX = sum(x[inst.depot_begin, j, k] for j in inst.V_p)
		sumX += x[inst.depot_begin, inst.depot_end, k]
		@constraint(model, sumX == 1, base_name = "c1")
	end

	# c2
	for k in inst.K, i in inst.V_p_d
		sum1 = sum(x[j, i, k] for (j, p) in inst.A if p == i)
		sum2 = sum(x[i, j, k] for (p, j) in inst.A if p == i)

		@constraint(model, sum1 - sum2 == 0, base_name = "c2")
	end

	# c3
	for k in inst.K
		sumX = sum(x[j, inst.depot_end, k] for j in inst.V_d)
		sumX += x[inst.depot_begin, inst.depot_end, k]

		@constraint(model, sumX == 1, base_name = "c3")
	end

	# c4
	for i in inst.V_p_d
		sumX = AffExpr(0)
		for k in inst.K, (j, p) in inst.A
			if p == i
				add_to_expression!(sumX, x[j, i, k])
			end
		end
		@constraint(model, sumX == 1, base_name = "c4")
	end

	# c5
	for k in inst.K, i in inst.V_p
		sum1 = AffExpr(0)
		for (j, p) in inst.A
			if p == i
				add_to_expression!(sum1, x[j, i, k])
			end
		end

		sum2 = AffExpr(0)
		for (j, p) in inst.A
			if p == inst.n + i
				add_to_expression!(sum2, x[j, inst.n+i, k])
			end
		end

		@constraint(model, sum1 == sum2, base_name = "c5")
	end

	# c6
	for k in inst.K
		@constraint(model, z[inst.depot_begin, k] == 0, base_name = "c6")
	end

	# c7
	for k in inst.K, (i, j) in inst.A
		@constraint(model, z[j, k] >= z[i, k] + inst.q[j] - inst.M[1] * (1 - x[i, j, k]), base_name = "c7")
	end

	# c8
	for k in inst.K, (i, j) in inst.A
		@constraint(model, z[j, k] <= z[i, k] + inst.q[j] + inst.M[1] * (1 - x[i, j, k]), base_name = "c8")
	end

	# c9
	for k in inst.K, i in inst.V_p_d
		sumX = AffExpr(0)
		for (j, p) in inst.A
			if p == i
				add_to_expression!(sumX, x[j, i, k])
			end
		end

		@constraint(model, z[i, k] <= min(inst.Q[k], max(0, inst.Q[k] + inst.q[i])) * sumX, base_name = "c9")
	end

	# c10
	for k in inst.K, i in inst.V_p
		sumX = AffExpr(0)
		for (j, p) in inst.A
			if p == i
				add_to_expression!(sumX, x[j, i, k])
			end
		end

		@constraint(model, z[i, k] >= inst.q[i] * sumX, base_name = "c10")
	end
end # function meloRoutingConstraints()

function meloSchedulingConstraints(
	inst::InstanceData,
	model::Model,
	x::Containers.SparseAxisArray,
	t::Containers.DenseAxisArray,
	tstart::Containers.DenseAxisArray,
	tfinal::Containers.DenseAxisArray,
	C::Containers.DenseAxisArray,
	phi::Containers.SparseAxisArray,
	gamma::Containers.SparseAxisArray,
	alpha::Containers.SparseAxisArray,
)
	constraints_refs = []
	# c13
	for k in inst.K, (i, j) in inst.A
		if i != inst.depot_begin && j in inst.V_p_d
			@constraint(model, t[j] >= t[i] + inst.s[i] + inst.d[i, j, k] - inst.M[2] * (1 - x[i, j, k]), base_name = "c13")
		end
	end

	# c14
	for k in inst.K, (p, j) in inst.A
		if p == inst.depot_begin && j in inst.V_p
			@constraint(
				model,
				t[j] >= tstart[k] + inst.d[inst.depot_begin, j, k] - inst.M[3] * (1 - x[inst.depot_begin, j, k]),
				base_name = "c14"
			)
		end

	end

	# c15
	for i in inst.V_p
		sumX = AffExpr(0)
		for k in inst.K, (l, p) in inst.A
			if p == i
				add_to_expression!(sumX, inst.d[i, inst.n+i, k], x[l, i, k])
			end
		end

		@constraint(model, t[i] + inst.s[i] + sumX <= t[inst.n+i], base_name = "c15")
	end

	# c16
	for (i, j) in inst.A_m
		sum1 = AffExpr(0)
		for h in inst.H_e[i][j]
			add_to_expression!(sum1, phi[i, j, h])
		end

		sum2 = AffExpr(0)
		for k in inst.K
			add_to_expression!(sum2, x[i, j, k])
		end

		@constraint(model, sum1 == sum2, base_name = "c16")
	end

	# c17
	for (i, j) in inst.A_m, k in inst.K, h in inst.H_e[i][j]
		if i != inst.depot_begin
			@constraint(
				model,
				alpha[i, j, h] >= t[i] + inst.s[i] + inst.d_bar[i, h, k] - inst.M[4] * (2 - phi[i, j, h] - x[i, j, k]),
				base_name = "c17"
			)
		end
	end

	# c18
	for (i, j) in inst.A_m
		if j in inst.V_p
			for h in inst.H_e[i][j], k in inst.K
				if i == inst.depot_begin
					@constraint(
						model,
						alpha[inst.depot_begin, j, h] >=
						tstart[k] + inst.d_bar[inst.depot_begin, h, k] -
						inst.M[5] * (2 - phi[inst.depot_begin, j, h] - x[inst.depot_begin, j, k]),
						base_name = "c18"
					)
				end
			end
		end
	end

	# c19
	for (i, j) in inst.A_m, k in inst.K, h in inst.H_e[i][j]
		if j in inst.V_p_d
			@constraint(
				model,
				t[j] >=
				alpha[i, j, h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.d_bar[j, h, k] -
				inst.M[6] * (2 - phi[i, j, h] - x[i, j, k]),
				base_name = "c19"
			)
		end
	end

	# c20
	for (i, j) in inst.A_m, (iprime, jprime) in inst.A_m, h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
		if (i, j) != (iprime, jprime)# && isPrecedePossible(i, j, iprime, jprime, h, inst) &&
			#isPrecedePossible(iprime, jprime, i, j, h, inst)
			ref = @constraint(
				model,
				gamma[i, j, iprime, jprime, h] + gamma[iprime, jprime, i, j, h] >= phi[i, j, h] + phi[iprime, jprime, h] - 1,
				base_name = "c20"
			)
			push!(constraints_refs, ref)
		end
	end


	# c21
	for (i, j) in inst.A_m, (iprime, jprime) in inst.A_m, h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
		if (i, j) != (iprime, jprime) #&& isPrecedePossible(i, j, iprime, jprime, h, inst)
			ref = @constraint(model, gamma[i, j, iprime, jprime, h] <= phi[i, j, h], base_name = "c21")
			push!(constraints_refs, ref)
		end
	end


	# c22
	for (i, j) in inst.A_m, (iprime, jprime) in inst.A_m, h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
		if (i, j) != (iprime, jprime) #&& isPrecedePossible(iprime, jprime, i, j, h, inst)
			ref = @constraint(model, gamma[iprime, jprime, i, j, h] <= phi[i, j, h], base_name = "c22")
			push!(constraints_refs, ref)
		end
	end

	# c23
	for (i, j) in inst.A_m, (iprime, jprime) in inst.A_m, h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
		if (i, j) != (iprime, jprime) #&& isPrecedePossible(i, j, iprime, jprime, h, inst) &&
			#isPrecedePossible(iprime, jprime, i, j, h, inst)
			ref = @constraint(model, gamma[i, j, iprime, jprime, h] + gamma[iprime, jprime, i, j, h] <= 1, base_name = "c23")
			push!(constraints_refs, ref)
		end
	end

	# c24
	for (i, j) in inst.A_m, (iprime, jprime) in inst.A_m, h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime], inst.H_e[j][iprime])
		if (i, j) != (iprime, jprime)# && isPrecedePossible(i, j, iprime, jprime, h, inst)
			ref = @constraint(
				model,
				alpha[iprime, jprime, h] >=
				alpha[i, j, h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.O[(inst.f[j][h], inst.f[iprime][h], h)] -
				inst.M[7] * (1 - gamma[i, j, iprime, jprime, h]),
				base_name = "c24"
			)
			push!(constraints_refs, ref)
		end
	end

	# c25
	for (i, j) in inst.A_m, h in inst.H_e[i][j]
		@constraint(
			model,
			alpha[i, j, h] >= inst.O[(inst.initial_station, inst.f[i][h], h)] - inst.M[8] * (1 - phi[i, j, h]),
			base_name = "c25"
		)

	end

	# c26
	for k in inst.K, (i, p) in inst.A
		if p == inst.depot_end && i != inst.depot_begin && i in inst.V_d
			@constraint(
				model,
				tfinal[k] >= t[i] + inst.s[i] + inst.d[i, inst.depot_end, k] - inst.M[2] * (1 - x[i, inst.depot_end, k]),
				base_name = "c26"
			)
		end
	end

	# c27
	for (i, p) in inst.A_m
		if p == inst.depot_end && i in inst.V_d
			for k in inst.K, h in inst.H_e[i][p]
				@constraint(
					model,
					tfinal[k] >=
					alpha[i, inst.depot_end, h] + inst.O[(inst.f[i][h], inst.f[inst.depot_end][h], h)] + inst.d_bar[inst.depot_end, h, k] -
					inst.M[4] * (2 - phi[i, inst.depot_end, h] - x[i, inst.depot_end, k]),
					base_name = "c27"
				)
			end
		end
	end

	# c28
	for k in inst.K
		@constraint(model, C[k] >= tfinal[k] - tstart[k], base_name = "c28")
	end

	# c29
	for i in inst.V_p_d
		@constraint(model, inst.eprime[i] <= t[i], base_name = "c29_pt1")
		@constraint(model, t[i] <= inst.lprime[i], base_name = "c29_pt2")
	end

	# c30 - the bounds are set in the variable definition
	for k in inst.K
		@constraint(model, tstart[k] <= tfinal[k], base_name = "c30")
	end

	# for con in constraints_refs
	# 	MOI.set(model, Gurobi.ConstraintAttribute("Lazy"), con, 2)
	# end
	# # c31
	# for (i,j) in inst.A_m
	# 	for h in inst.H
	# 		if !(h in inst.H_e[i][j])
	# 			@constraint(model, phi[i,j,h] == 0, base_name="c31")
	# 			# @constraint(model, alpha[i,j,h] == 0, base_name="c31")
	# 			# for (iprime,jprime) in inst.A_m
	# 			# 	if (i,j) != (iprime, jprime)
	# 			# 		@constraint(model, gamma[i,j,iprime,jprime,h] == 0, base_name="c31")
	# 			# 		@constraint(model, gamma[iprime,jprime,i,j,h] == 0, base_name="c31")
	# 			# 	end
	# 			# end
	# 		end
	# 	end
	# end
end # function meloSchedulingConstraints()