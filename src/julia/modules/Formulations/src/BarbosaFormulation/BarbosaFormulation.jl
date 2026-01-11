function barbosaFormulation(env::Union{Gurobi.Env, Nothing}, inst::InstanceData, params::ParameterData)
	println("Running Formulations.barbosaFormulation")

	if params.solver == "Gurobi"
		model = Model(() -> Gurobi.Optimizer(env))
		set_attribute(model, "TimeLimit", params.maxtime)
		set_attribute(model, "LogFile", params.output * inst.name * "_grb.log")
	else
		println("No solver selected")
		return 0
	end

	### Defining variables ###

	# Routing variables

	@variable(model, x[i = inst.Vprime, j = inst.Vprime, k = inst.K, ell = inst.L_K; (i, j) in inst.A], binary = true)
	@variable(model, z[k = inst.K, ell = inst.L_K] >= 0, Int)

	# Scheduling variables

	@variable(model, inst.jobs[1].lat >= t[k = inst.K, ell = inst.L_K] >= 0)
	@variable(model, inst.jobs[1].lat >= C[k = inst.K] >= 0)
	@variable(
		model,
		phi[i = inst.Vprime, j = inst.Vprime, h = inst.H_e[i][j], ell = inst.L_H, s = inst.Sprime_h[h]; ((i, j) in inst.A_m)],
		binary = true
	)
	@variable(model, gamma[h = inst.H], binary = true)
	@variable(model, inst.jobs[1].lat >= alpha[h = inst.H, ell = inst.L_H] >= 0)

	### Routing Constraints ###

	# c1
	for k in inst.K
		sumX = sum(x[1, j, k, 1] for j in inst.V_p)
		sumX += x[1, 2*inst.n+2, k, 1]
		@constraint(model, sumX == 1, base_name = "c1")
	end

	# c2
	for k in inst.K
		for i in inst.V_p_d
			for ell in inst.L_K[2:end]
				sum1 = sum(x[j, i, k, ell-1] for (j, p) in inst.A if p == i)
				sum2 = sum(x[i, j, k, ell] for (p, j) in inst.A if p == i)

				@constraint(model, sum1 - sum2 == 0, base_name = "c2")
			end
		end
	end

	# c3
	for k in inst.K
		sumX = sum(sum(x[j, 2*inst.n+2, k, ell] for j in inst.V_d) + x[1, 2*inst.n+2, k, ell] for ell in inst.L_K)

		@constraint(model, sumX == 1, base_name = "c3")
	end

	# # c4
	# for i in inst.V_p_d
	#   sum1 = sum(sum(sum(x[i, j, k, ell] for ell in inst.L_K) for (p, j) in inst.A if p == i) for k in inst.K)
	#   sum2 = sum(sum(sum(x[j, i, k, ell] for ell in inst.L_K) for (j, p) in inst.A if p == i) for k in inst.K)

	#   @constraint(model, sum1 == sum2, base_name = "c4")
	#   @constraint(model, sum1 <= 1, base_name = "c4")
	# end

	# c5
	for ell in inst.L_K
		for k in inst.K
			sumX = sum(x[i, j, k, ell] for (i, j) in inst.A)

			@constraint(model, sumX <= 1, base_name = "c5")
		end
	end

	# c6
	for i in inst.V_p_d
		sumX = AffExpr(0)
		for k in inst.K
			for (j, p) in inst.A
				if p == i
					for ell in inst.L_K
						add_to_expression!(sumX, x[j, i, k, ell])
					end
				end
			end
		end
		@constraint(model, sumX == 1, base_name = "c6")
	end

	# c7
	for k in inst.K
		for i in inst.V_p
			for ell in inst.L_K
				sum1 = AffExpr(0)
				for (j, p) in inst.A
					if p == i
						add_to_expression!(sum1, x[j, i, k, ell])
					end
				end

				sum2 = AffExpr(0)
				for (j, p) in inst.A
					for ellprime in inst.L_K[ell+1:end]
						if p == inst.n + i
							add_to_expression!(sum2, x[j, inst.n+i, k, ellprime])
						end
					end
				end

				@constraint(model, sum1 == sum2, base_name = "c7")
			end
		end
	end

	if params.elevator != 1 || true
		# c8
		for k in inst.K
			@constraint(model, z[k, 1] == 0, base_name = "c8")
		end

		# c9
		for k in inst.K
			for ell in inst.L_K[2:end]
				sumX = AffExpr(0)
				for (i, j) in inst.A
					add_to_expression!(sumX, inst.q[j], x[i, j, k, ell-1])
				end
				@constraint(model, z[k, ell] >= z[k, ell-1] + sumX, base_name = "c9")
			end
		end

		# c10
		for k in inst.K
			for ell in inst.L_K[2:end]
				sumX = AffExpr(0)
				for (i, j) in inst.A
					add_to_expression!(sumX, min(inst.Q[k], max(0, inst.Q[k] + inst.q[j])), x[i, j, k, ell-1])
				end

				@constraint(model, z[k, ell] <= sumX, base_name = "c10")
			end
		end

		# c11
		for k in inst.K
			for ell in inst.L_K[2:end]
				sumX = AffExpr(0)
				for (i, j) in inst.A
					if j in inst.V_p
						add_to_expression!(sumX, inst.q[j], x[i, j, k, ell-1])
					end
				end

				@constraint(model, z[k, ell] >= sumX, base_name = "c11")
			end
		end
	end

	println("Finished Routing constraints")
	# # ### Scheduling constraints ###

	# c14
	for k in inst.K
		for ell in inst.L_K[2:end]
			sumX = AffExpr(0)
			for (i, j) in inst.A
				add_to_expression!(sumX, inst.s[i] + inst.d[i, j, k], x[i, j, k, ell-1])
			end

			@constraint(model, t[k, ell] >= t[k, ell-1] + sumX, base_name = "c14")
		end
	end

	# c15
	for (i, j) in inst.A_m
		sum1 = AffExpr(0)
		for h in inst.H_e[i][j]
			for ellprime in inst.L_H
				for s in inst.Sprime_h[h]
					add_to_expression!(sum1, phi[i, j, h, ellprime, s])
				end
			end
		end
		sum2 = AffExpr(0)
		for k in inst.K
			for ell in inst.L_K
				add_to_expression!(sum2, x[i, j, k, ell])
			end
		end

		@constraint(model, sum1 == sum2, base_name = "c15")
	end

	# c16
	for h in inst.H
		sumPhi = AffExpr(0)
		for (i, j) in inst.A_m
			if h in inst.H_e[i][j]
				for ell in inst.L_H
					for s in inst.Sprime_h[h]
						add_to_expression!(sumPhi, phi[i, j, h, ell, s])
					end
				end
			end
		end

		@constraint(model, gamma[h] <= sumPhi, base_name = "c16")
		@constraint(model, sumPhi <= (3 * inst.n + 1) * gamma[h], base_name = "c16")
	end

	# c17
	for h in inst.H
		sumPhi = AffExpr(0)
		for (i, j) in inst.A_m
			if h in inst.H_e[i][j]
				for s in inst.Sprime_h[h]
					add_to_expression!(sumPhi, phi[i, j, h, 1, s])
				end
			end
		end

		@constraint(model, sumPhi == gamma[h], base_name = "c17")
	end

	# c18
	for h in inst.H
		sumPhi = AffExpr(0)
		for (i, j) in inst.A_m
			if h in inst.H_e[i][j]
				for ell in inst.L_H
					add_to_expression!(sumPhi, phi[i, j, h, ell, inst.Sprime_h[h][end]])
				end
			end
		end

		@constraint(model, sumPhi == gamma[h], base_name = "c18")
	end

	# c19
	for h in inst.H
		for ell in inst.L_H[2:end]
			for s in inst.S_h[h]
				sum1 = AffExpr(0)
				for (i, j) in inst.A_m
					if h in inst.H_e[i][j] && inst.f[i][h] == s
						for t in inst.Sprime_h[h]
							add_to_expression!(sum1, phi[i, j, h, ell, t])
						end
					end
				end

				sum2 = AffExpr(0)
				for (i, j) in inst.A_m
					if h in inst.H_e[i][j]
						add_to_expression!(sum2, phi[i, j, h, ell-1, s])
					end
				end

				@constraint(model, sum1 - sum2 == 0, base_name = "c19")
			end
		end
	end

	# c20
	for (i, j) in inst.A_m
		for h in inst.H_e[i][j]
			for k in inst.K
				for ell in inst.L_K
					for ellprime in inst.L_H
						sumPhi = sum(phi[i, j, h, ellprime, s] for s in inst.Sprime_h[h])
						@constraint(
							model,
							alpha[h, ellprime] >= t[k, ell] + inst.s[i] + inst.d_bar[i, h, k] - inst.M[4] * (2 - sumPhi - x[i, j, k, ell]),
							base_name = "c20"
						)
					end
				end
			end
		end
	end

	# c21
	for (i, j) in inst.A_m
		for h in inst.H_e[i][j]
			for k in inst.K
				for ell in inst.L_K[2:end]
					for ellprime in inst.L_H
						sumPhi = sum(phi[i, j, h, ellprime, s] for s in inst.Sprime_h[h])
						@constraint(
							model,
							t[k, ell] >=
							alpha[h, ellprime] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.d_bar[j, h, k] -
							inst.M[6] * (2 - sumPhi - x[i, j, k, ell-1]),
							base_name = "c21"
						)
					end
				end
			end
		end
	end

	# c22
	for h in inst.H
		for ell in inst.L_H[2:end]
			sumPhi = AffExpr(0)
			for (i, j) in inst.A_m
				if h in inst.H_e[i][j]
					for s in inst.Sprime_h[h]
						add_to_expression!(
							sumPhi,
							inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.O[(inst.f[j][h], s, h)],
							phi[i, j, h, ell-1, s],
						)
					end
				end
			end
			@constraint(model, alpha[h, ell] >= alpha[h, ell-1] + sumPhi, base_name = "c22")
		end
	end

	# c23
	for h in inst.H
		sumPhi = AffExpr(0)
		for (i, j) in inst.A_m
			if h in inst.H_e[i][j]
				for s in inst.Sprime_h[h]
					add_to_expression!(sumPhi, inst.O[(1, inst.f[i][h], h)], phi[i, j, h, 1, s])
				end
			end
		end
		@constraint(model, alpha[h, 1] >= sumPhi, base_name = "c23")
	end

	# c24
	for k in inst.K
		@constraint(model, C[k] >= t[k, 2*inst.n+2] - t[k, 1], base_name = "c24")
	end

	# c25
	for k in inst.K
		for ell in inst.L_K[2:end]
			sum1 = AffExpr(0)
			for (i, j) in inst.A
				add_to_expression!(sum1, inst.e[i], x[i, j, k, ell])
			end
			sum2 = AffExpr(0)
			for (i, j) in inst.A
				add_to_expression!(sum2, inst.l[i], x[i, j, k, ell])
			end
			sum3 = AffExpr(0)
			for (i, j) in inst.A
				add_to_expression!(sum3, x[i, j, k, ell])
			end

			@constraint(model, sum1 <= t[k, ell], base_name = "c25")
			@constraint(model, t[k, ell] <= sum2 + inst.l[inst.depot_begin] * (1 - sum3), base_name = "c25")
		end
	end

	# c26
	for k in inst.K
		@constraint(model, inst.jobs[1].earl <= t[k, 1], base_name = "c26")
		@constraint(model, t[k, 1] <= t[k, 2*inst.n+2], base_name = "c26")
		@constraint(model, t[k, 2*inst.n+2] <= inst.jobs[1].lat, base_name = "c26")
	end

	# # c31 Not yet converted!!!
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

	println("Finished Scheduling constraints")


	# ### Objective function ###

	# c32
	@objective(model, Min, sum(C))
	println("Finished Objective function")
	# write_to_file(model, "modelo.lp")
	# println("Model file created")

	# Warm-up
	if params.warmStart
		sol = Multistart.multistartlp(env, inst, params)

		for (i, j) in inst.A
			for k in inst.K
				found = false
				rt = sol.vehicles[k]
				for iprime in 1:length(rt)-1
					if rt[iprime].node == i && rt[iprime+1].node == j
						found = true
						set_start_value(x[i, j, k], 1)
						break
					end
				end
				if !found
					set_start_value(x[i, j, k], 0)
				end
			end
		end

		for (i, j) in inst.A_m
			for h in inst.H_e[i][j]
				found = false
				mach = sol.machines[h]
				for iprime in eachindex(mach)
					if mach[iprime].orig == i && mach[iprime].dest == j
						set_start_value(phi[i, j, h], 1)
						found = true
						break
					end
				end
				if !found
					set_start_value(phi[i, j, h], 0)
				end
			end
		end

		for (i, j) in inst.A_m
			for (iprime, jprime) in inst.A_m
				for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
					if (i, j) != (iprime, jprime)
						set_start_value(gamma[i, j, iprime, jprime, h], 0)
					end
				end
			end
		end

		for h in inst.H
			mach = sol.machines[h]
			for i in 1:length(mach)-1
				for j in i+1:length(mach)
					if h in intersect(inst.H_e[mach[i].orig][mach[i].dest], inst.H_e[mach[j].orig][mach[j].dest])
						set_start_value(gamma[mach[i].orig, mach[i].dest, mach[j].orig, mach[j].dest, h], 1)
					else
						set_start_value(gamma[mach[i].orig, mach[i].dest, mach[j].orig, mach[j].dest, h], 0)
					end
				end
			end
		end
	end

	# set_attribute(model, "PreSolve", 0)
	# undo = relax_integrality(model)
	# println("Number of integer constraints (relax): ", num_constraints(model, VariableRef, MOI.Integer))
	# undo()
	# println("Number of integer constraints (normal): ", num_constraints(model, VariableRef, MOI.Integer))

	# function my_callback_function(cb_data, cb_where::Cint)
	#   if cb_where != GRB_CB_MIPNODE
	#     return
	#   end

	#   nodeCount = Ref{Int64}(0)
	#   GRBcbget(cb_data, cb_where, GRB_CB_MIPNODE_NODCNT, nodeCount)
	#   if nodeCount[] > 0
	#     GRBterminate(unsafe_backend(model))
	#     return
	#   end

	#   mipNodeStatus = Ref{Int64}(GRB_INFEASIBLE)
	#   GRBcbget(cb_data, cb_where, GRB_CB_MIPNODE_STATUS, mipNodeStatus)
	#   if mipNodeStatus[] == GRB_OPTIMAL
	#     # Get the root relaxation solution
	#     numVars = num_variables(model) + 12
	#     resultP = Float64[0 for _ in 1:numVars]
	#     GRBcbget(cb_data, cb_where, GRB_CB_MIPNODE_REL, resultP)
	#   end
	# end


	# MOI.set(model, Gurobi.CallbackFunction(), my_callback_function)

	t1 = time_ns()
	println("starting")
	status = optimize!(model)
	println("final")
	t2 = time_ns()
	elapsedtime = (t2 - t1) / 1.0e9

	opt = 0
	if termination_status(model) == OPTIMAL
		println("Solution is optimal")
		opt = 1
	elseif termination_status(model) == TIME_LIMIT && has_values(model)
		println("Solution is suboptimal due to a time limit, but a primal solution is available")
	else
		println("The model was not solved correctly. Status: ", status)
		return
	end
	println("  objective value = ", objective_value(model))

	println(status)
	objValue = sum(value.(C))
	bestbound = objective_bound(model)
	numnodes = node_count(model)
	time = solve_time(model)
	gap = 100 * (objValue - bestbound) / objValue

	x = value.(x)
	z = value.(z)
	t = value.(t)
	C = value.(C)
	phi = value.(phi)
	alpha = value.(alpha)
	gamma = value.(gamma)

	# for ell in inst.L_K
	#   for k in inst.K
	#     for (i, j) in inst.A
	#       if x[i, j, k, ell] > 0.5
	#         println("i ", i)
	#         println("j ", j)
	#         println("k ", k)
	#         println("ell ", ell)
	#       end
	#     end
	#   end
	#   println()
	# end

	# for k in inst.K
	#   for ell in inst.L_K[2:end]
	#     println("t[", k, ",", ell, "] ", t[k, ell])
	#     println("t[", k, ",", ell - 1, "] ", t[k, ell-1])
	#     for (i, j) in inst.A
	#       if x[i, j, k, ell-1] > 0.5
	#         println("inst.s[", i, "] ", inst.s[i])
	#         println("inst.d[", i, ",", j, ",", k, "] ", inst.d[i, j, k])
	#       end
	#     end
	#     println()
	#   end
	# end

	# for (i, j) in inst.A_m
	#   for h in inst.H_e[i][j]
	#     for ellprime in inst.L_H
	#       for s in inst.Sprime_h[h]
	#         if phi[i, j, h, ellprime, s] > 0.5
	#           println("phi[", i, ", ", j, ", ", h, ", ", ellprime, ", ", s, "] ", phi[i, j, h, ellprime, s])
	#         end
	#       end
	#     end
	#   end
	#   for k in inst.K
	#     for ell in inst.L_K
	#       if x[i, j, k, ell] > 0.5
	#         println("x[", i, ", ", j, ", ", k, ", ", ell, "] ", x[i, j, k, ell])
	#       end
	#     end
	#   end
	#   println()
	# end

	# println("set is machine is used")
	# for h in inst.H
	#   sumPhi = 0
	#   for (i, j) in inst.A_m
	#     if h in inst.H_e[i][j]
	#       for ell in inst.L_H
	#         for s in inst.Sprime_h[h]
	#           sumPhi += round(phi[i, j, h, ell, s])
	#         end
	#       end
	#     end
	#   end

	#   println("gamma[", h, "] = ", gamma[h])
	#   println("sumPhi = ", sumPhi)
	#   println()
	# end

	# println("leave in moment 1")
	# for h in inst.H
	#   for (i, j) in inst.A_m
	#     if h in inst.H_e[i][j]
	#       for s in inst.Sprime_h[h]
	#         if phi[i, j, h, 1, s] > 0.5
	#           println("phi[", i, ", ", j, ", ", h, ", ", 1, ", ", s, "] ", phi[i, j, h, 1, s])
	#         end
	#       end
	#     end
	#   end

	#   println("gamma[", h, "] = ", gamma[h])
	#   println()
	# end

	# println("must go to dummy end station")
	# for h in inst.H
	#   for (i, j) in inst.A_m
	#     if h in inst.H_e[i][j]
	#       for ell in inst.L_H
	#         if phi[i, j, h, ell, inst.Sprime_h[h][end]] > 0.5
	#           println("phi[", i, ", ", j, ", ", h, ", ", ell, ", ", inst.Sprime_h[h][end], "] = ", phi[i, j, h, ell, inst.Sprime_h[h][end]])
	#         end
	#       end
	#     end
	#   end

	#   println("gamma[", h, "] = ", gamma[h])
	#   println()
	# end

	# # c22 
	# println("start time machine travel must be after the previous and the time to go to starting station")
	# for h in inst.H
	#   for ell in inst.L_H[2:end]
	#     println("alpha[", h, ",", ell, "] = ", alpha[h, ell])
	#     println("alpha[", h, ",", ell - 1, "] = ", alpha[h, ell-1])

	#     for (i, j) in inst.A_m
	#       if h in inst.H_e[i][j]
	#         for s in inst.Sprime_h[h]
	#           if phi[i, j, h, ell-1, s] > 0.5
	#             println("travel:\n\tinst.O[(", inst.f[i][h], ", ", inst.f[j][h], ", ", h, ")] = ", inst.O[(inst.f[i][h], inst.f[j][h], h)])
	#             println("setup:\n\tinst.O[(", inst.f[j][h], ", ", s, ", ", h, ")] = ", inst.O[(inst.f[j][h], s, h)])
	#             println("phi[", i, ", ", j, ", ", h, ", ", ell - 1, ", ", s, "] = ", phi[i, j, h, ell-1, s])
	#           end
	#         end
	#       end
	#     end
	#     println()
	#   end
	# end

	# # c23
	# println("the machine must be in starting station")
	# for h in inst.H
	#   println("alpha[", h, ", ", 1, "] = ", alpha[h, 1])
	#   for (i, j) in inst.A_m
	#     if h in inst.H_e[i][j]
	#       for s in inst.Sprime_h[h]
	#         if phi[i, j, h, 1, s] > 0.5
	#           println("phi[", i, ", ", j, ", ", h, ", ", 1, ", ", s, "] = ", round(phi[i, j, h, 1, s]))
	#           println("inst.O[(", 1, ", ", inst.f[i][h], ", ", h, ")] = ", inst.O[(1, inst.f[i][h], h)])
	#         end
	#       end
	#     end
	#   end
	#   println()
	# end

	# # c20
	# println("machine travel start time")
	# for h in inst.H
	#   for k in inst.K
	#     for (i, j) in inst.A_m
	#       if h in inst.H_e[i][j]
	#         for ell in inst.L_K
	#           for ellprime in inst.L_H
	#             for s in inst.Sprime_h[h]
	#               if phi[i, j, h, ellprime, s] > 0.5 && x[i, j, k, ell] > 0.5
	#                 println("phi[", i, ", ", j, ", ", h, ", ", ellprime, ", ", s, "] = ", phi[i, j, h, ellprime, s])
	#                 println("x[", i, ",", j, ",", k, ",", ell, "] = ", x[i, j, k, ell])
	#                 println("alpha[", h, ", ", ellprime, "] = ", alpha[h, ellprime])
	#                 println("t[", k, ", ", ell, "] = ", t[k, ell])
	#                 println("inst.s[", i, "] = ", inst.s[i])
	#                 println("inst.d_bar[", i, ",", h, ",", k, "] = ", inst.d_bar[i, h, k])
	#                 println()
	#               end
	#             end

	#           end
	#         end
	#       end
	#     end
	#   end
	# end

	# println("vehicle arrival time after machine travel")
	# for h in inst.H
	#   for k in inst.K
	#     for (i, j) in inst.A_m
	#       if h in inst.H_e[i][j]
	#         for ell in inst.L_K[2:end]
	#           for ellprime in inst.L_H
	#             for s in inst.Sprime_h[h]
	#               if phi[i, j, h, ellprime, s] > 0.5 && x[i, j, k, ell-1] > 0.5
	#                 println("phi[", i, ", ", j, ", ", h, ", ", ellprime, ", ", s, "] = ", phi[i, j, h, ellprime, s])
	#                 println("x[", i, ",", j, ",", k, ",", ell - 1, "] = ", x[i, j, k, ell-1])
	#                 println("t[", k, ", ", ell, "] = ", t[k, ell])
	#                 println("alpha[", h, ", ", ellprime, "] = ", alpha[h, ellprime])
	#                 println("inst.O[(", inst.f[i][h], ", ", inst.f[j][h], ", ", h, ")] = ", inst.O[(inst.f[i][h], inst.f[j][h], h)])
	#                 println("inst.d_bar[", j, ",", h, ",", k, "] = ", inst.d_bar[j, h, k])
	#                 println()
	#               end
	#             end
	#           end
	#         end
	#       end
	#     end
	#   end
	# end

	# for k in inst.K
	#   for ell in inst.L_K
	#     println("z[", k, ",", ell, "]", z[k, ell])
	#   end
	#   println()
	# end

	# sol = createSolutionMelo(inst, x, z, t, tstart, tfinal, C, phi, gamma, alpha, objValue, bestbound, time, gap, numnodes, params)

	# if params.printsol == 1
	#   printDetailMeloFormulationSolution(inst, sol)
	# end
	# saveSolutionToFile(sol, inst, params)
	# if validateSolution(inst, sol, params)
	#   println("Everything is awesome!")
	# else
	#   println("Infeasible solution")
	# end

end # function barbosaFormulation()