
mutable struct CallbackClosure
	inst::InstanceData
	params::ParameterData
	mipModel::MIPModel
	calls::Int
end

function get_user_cut_function(f::CallbackClosure)::Function
	if f.params.typeUserCut == 1
		return uc_mincut_per_vehicle(f)
	elseif f.params.typeUserCut == 2
		return uc_mincut_all_vehicles(f)
	elseif f.params.typeUserCut == 3
		return uc_smaller_strongly_connected_components_v1(f)
	elseif f.params.typeUserCut == 4
		return uc_smaller_strongly_connected_components_v2(f)
	elseif f.params.typeUserCut == 5
		return uc_all_strongly_connected_components_v1(f)
	elseif f.params.typeUserCut == 6
		return uc_all_strongly_connected_components_v2(f)
	elseif f.params.typeUserCut == 7
		return uc_vehicle_used_or_not(f)
	end

	error("Type of user cut $(f.params.typeUserCut) not available")
end

function uc_mincut_per_vehicle(f::CallbackClosure)
	return function (cb_data)
		# println("Running uc_mincut_per_vehicle")
		x_val = callback_value.(Ref(cb_data), f.mipModel.x)
		t_val = callback_value.(Ref(cb_data), f.mipModel.t)
		tstart_val = callback_value.(Ref(cb_data), f.mipModel.tstart)
		tfinal_val = callback_value.(Ref(cb_data), f.mipModel.tfinal)
		C_val = callback_value.(Ref(cb_data), f.mipModel.C)

		nv = 2 * f.inst.n + 2
		maxdig = 2
		edge_list = Tuple{Int64, Int64}[]
		edge_weights = Array{String}(undef, nv, nv)
		capacity_matrix = zeros(Float64, nv, nv)
		for k in f.inst.K
			for (i, j) in f.inst.A
				if x_val[i, j, k] > f.params.epsilon
					cost_truncked = round(x_val[i, j, k] * 100, digits = maxdig)
					push!(edge_list, (i, j))
					edge_weights[i, j] = string(cost_truncked)
					capacity_matrix[i, j] += x_val[i, j, k]
				end
			end

			g = DiGraph(Edge.(edge_list))
			s = 1
			for i in f.inst.V_p_d
				Sbar, S, flow = mincut(g, s, i, capacity_matrix, DinicAlgorithm())

				sumXoutgoing_i = 0
				for k in f.inst.K, l in f.inst.Vprime[2:end]
					if (i, l) in f.inst.A && x_val[i, l, k] > f.params.epsilon
						sumXoutgoing_i += x_val[i, l, k]
					end
				end
				if flow < sumXoutgoing_i - f.params.epsilon
					f.calls += 1
					node_labels = build_node_labels(f.inst, f.params, x_val, t_val, tstart_val, tfinal_val, C_val)
					filename = get_graph_dot_filename(f.calls)
					# save_graph_to_dot(g, filename, edge_weights, node_labels)


					sum1 = AffExpr(0)
					sum1val = 0
					for k in f.inst.K, l in S, j in Sbar
						if (l, j) in f.inst.A
							add_to_expression!(sum1, f.mipModel.x[l, j, k])
							sum1val += x_val[l, j, k]
						end
					end

					sum2 = AffExpr(0)
					sum2val = 0
					for k in f.inst.K, l in f.inst.Vprime[2:end]
						if (i, l) in f.inst.A
							add_to_expression!(sum2, f.mipModel.x[i, l, k])
							sum2val += x_val[i, l, k]
						end
					end
					# println("Call: ", f.calls, " c2")
					# println("\ts: ", s, " i: ", i)
					# println("\tS: ", S)
					# println("\tSbar: ", Sbar)
					# println("\tsum1val: ", sum1val, " sum2val: ", sum2val)
					# println("\tflow: ", flow, " sumXoutgoing_i: ", sumXoutgoing_i)
					con = @build_constraint(sum1 >= sum2)
					MOI.submit(f.mipModel.model, MOI.UserCut(cb_data), con)
				end
			end
		end
	end
end

function uc_mincut_all_vehicles(f::CallbackClosure)
	return function (cb_data)
		# println("Running uc_mincut_all_vehicles")
		x_val = callback_value.(Ref(cb_data), f.mipModel.x)
		t_val = callback_value.(Ref(cb_data), f.mipModel.t)
		tstart_val = callback_value.(Ref(cb_data), f.mipModel.tstart)
		tfinal_val = callback_value.(Ref(cb_data), f.mipModel.tfinal)
		C_val = callback_value.(Ref(cb_data), f.mipModel.C)

		nv = 2 * f.inst.n + 2
		maxdig = 2
		edge_list = Tuple{Int64, Int64}[]
		edge_weights = Array{String}(undef, nv, nv)
		capacity_matrix = zeros(Float64, nv, nv)
		for (i, j) in f.inst.A
			sumK = 0
			for k in f.inst.K
				if x_val[i, j, k] > f.params.epsilon
					sumK += x_val[i, j, k]
				end
			end
			if sumK > f.params.epsilon
				cost_truncked = round(sumK * 100, digits = maxdig)
				push!(edge_list, (i, j))
				edge_weights[i, j] = string(cost_truncked)
				capacity_matrix[i, j] = sumK
			end
		end

		g = DiGraph(Edge.(edge_list))
		s = 1
		for i in f.inst.V_p_d
			Sbar, S, flow = mincut(g, s, i, capacity_matrix, DinicAlgorithm())

			sumXoutgoing_i = 0
			for k in f.inst.K, l in f.inst.Vprime[2:end]
				if (i, l) in f.inst.A && x_val[i, l, k] > f.params.epsilon
					sumXoutgoing_i += x_val[i, l, k]
				end
			end
			if flow < sumXoutgoing_i - f.params.epsilon
				f.calls += 1
				node_labels = build_node_labels(f.inst, f.params, x_val, t_val, tstart_val, tfinal_val, C_val)
				filename = get_graph_dot_filename(f.calls)
				# save_graph_to_dot(g, filename, edge_weights, node_labels)


				sum1 = AffExpr(0)
				sum1val = 0
				for k in f.inst.K, l in S, j in Sbar
					if (l, j) in f.inst.A
						add_to_expression!(sum1, f.mipModel.x[l, j, k])
						sum1val += x_val[l, j, k]
					end
				end

				sum2 = AffExpr(0)
				sum2val = 0
				for k in f.inst.K, l in f.inst.Vprime[2:end]
					if (i, l) in f.inst.A
						add_to_expression!(sum2, f.mipModel.x[i, l, k])
						sum2val += x_val[i, l, k]
					end
				end
				# println("Call: ", f.calls)
				# println("\ts: ", s, " i: ", i)
				# println("\tS: ", S)
				# println("\tSbar: ", Sbar)
				# println("\tsum1val: ", sum1val, " sum2val: ", sum2val)
				# println("\tflow: ", flow, " sumXoutgoing_i: ", sumXoutgoing_i)
				con = @build_constraint(sum1 >= sum2)
				MOI.submit(f.mipModel.model, MOI.UserCut(cb_data), con)
			end
		end

	end
end

function uc_smaller_strongly_connected_components_v1(f::CallbackClosure)
	return function (cb_data)
		# println("Running uc_smaller_strongly_connected_components_v1")
		x_val = callback_value.(Ref(cb_data), f.mipModel.x)
		t_val = callback_value.(Ref(cb_data), f.mipModel.t)
		tstart_val = callback_value.(Ref(cb_data), f.mipModel.tstart)
		tfinal_val = callback_value.(Ref(cb_data), f.mipModel.tfinal)
		C_val = callback_value.(Ref(cb_data), f.mipModel.C)

		nv = 2 * f.inst.n + 2
		maxdig = 2
		edge_list = Tuple{Int64, Int64}[]
		edge_weights = Array{String}(undef, nv, nv)
		capacity_matrix = zeros(Float64, nv, nv)
		for k in f.inst.K
			for (i, j) in f.inst.A
				if x_val[i, j, k] > f.params.epsilon
					cost_truncked = round(x_val[i, j, k] * 100, digits = maxdig)
					push!(edge_list, (i, j))
					edge_weights[i, j] = string(cost_truncked)
					capacity_matrix[i, j] += x_val[i, j, k]
				end
			end

			g = DiGraph(Edge.(edge_list))

			components = strongly_connected_components_tarjan(g)
			S = components[argmin(map(v -> length(v) > 1 ? length(v) : 4 * f.inst.n, components))]
			if length(S) > 1 && length(S) < length(f.inst.Vprime)
                f.calls += 1
				node_labels = build_node_labels(f.inst, f.params, x_val, t_val, tstart_val, tfinal_val, C_val)
				filename = get_graph_dot_filename(f.calls)
				# save_graph_to_dot(g, filename, edge_weights, node_labels)

				sum1 = AffExpr(0)
				sum1val = 0
				for k in f.inst.K, i in S, j in S
					if (i, j) in f.inst.A
						add_to_expression!(sum1, f.mipModel.x[i, j, k])
						sum1val += x_val[i, j, k]
					end
				end

				# println("Call: ", f.calls, " k: ", k)
				# println("S: ", S)
				# println("sum1val: ", sum1val)
				# println("length(S) - 1: ", length(S) - 1)
				con = @build_constraint(sum1 <= length(S) - 1)
				MOI.submit(f.mipModel.model, MOI.UserCut(cb_data), con)
			end
		end
	end
end

function uc_smaller_strongly_connected_components_v2(f::CallbackClosure)
	return function (cb_data)
		# println("Running uc_smaller_strongly_connected_components_v2")
		x_val = callback_value.(Ref(cb_data), f.mipModel.x)
		t_val = callback_value.(Ref(cb_data), f.mipModel.t)
		tstart_val = callback_value.(Ref(cb_data), f.mipModel.tstart)
		tfinal_val = callback_value.(Ref(cb_data), f.mipModel.tfinal)
		C_val = callback_value.(Ref(cb_data), f.mipModel.C)

		nv = 2 * f.inst.n + 2
		maxdig = 2
		edge_list = Tuple{Int64, Int64}[]
		edge_weights = Array{String}(undef, nv, nv)
		capacity_matrix = zeros(Float64, nv, nv)
		for k in f.inst.K
			for (i, j) in f.inst.A
				if x_val[i, j, k] > f.params.epsilon
					cost_truncked = round(x_val[i, j, k] * 100, digits = maxdig)
					push!(edge_list, (i, j))
					edge_weights[i, j] = string(cost_truncked)
					capacity_matrix[i, j] += x_val[i, j, k]
				end
			end

			g = DiGraph(Edge.(edge_list))

			components = strongly_connected_components_tarjan(g)
			S = components[argmin(map(v -> length(v) > 1 ? length(v) : 4 * f.inst.n, components))]
			if length(S) > 1 && length(S) < length(f.inst.Vprime)
                f.calls += 1
				node_labels = build_node_labels(f.inst, f.params, x_val, t_val, tstart_val, tfinal_val, C_val)
				filename = get_graph_dot_filename(f.calls)
				# save_graph_to_dot(g, filename, edge_weights, node_labels)

				Sbar = setdiff(f.inst.Vprime, S)
				piS = [i for i in f.inst.V_p if i + f.inst.n in S]
				sigmaS = [i for i in f.inst.V_d if i - f.inst.n in S]

				# println("Call: ", f.calls, " k: ", k)
				# println("S: ", S)
				# println("Sbar: ", Sbar)
				# println("piS: ", piS)
				# println("sigmaS: ", sigmaS)

				sum1 = AffExpr(0)
				sum1val = 0
				for k in f.inst.K, i in S, j in S
					if (i, j) in f.inst.A
						add_to_expression!(sum1, f.mipModel.x[i, j, k])
						sum1val += x_val[i, j, k]
					end
				end
				sum2 = AffExpr(0)
				sum2val = 0
				for i in S, j in intersect(Sbar, piS)
					if (i, j) in f.inst.A
						add_to_expression!(sum2, f.mipModel.x[i, j, k])
						sum2val += x_val[i, j, k]
					end
				end
				sum3 = AffExpr(0)
				sum3val = 0
				for i in intersect(S, piS), j in setdiff(Sbar, piS)
					if (i, j) in f.inst.A
						add_to_expression!(sum3, f.mipModel.x[i, j, k])
						sum3val += x_val[i, j, k]
					end
				end

				if sum1val + sum2val + sum3val > length(S) - 1
					# println("Part 1")
					# println("sum1: ", sum1val, " sum2: ", sum2val, " sum3: ", sum3val)
					# println("sum1 + sum2 + sum3: ", sum1val + sum2val + sum3val)
					# println("length(S) - 1: ", length(S) - 1)
					# println(sum1val + sum2val + sum3val, " > ", length(S) - 1)
				end
				con = @build_constraint(sum1 + sum2 + sum3 <= length(S) - 1)
				MOI.submit(f.mipModel.model, MOI.UserCut(cb_data), con)

				sum2 = AffExpr(0)
				for i in intersect(Sbar, sigmaS), j in S
					if (i, j) in f.inst.A
						add_to_expression!(sum2, f.mipModel.x[i, j, k])
					end
				end
				sum3 = AffExpr(0)
				for i in setdiff(Sbar, sigmaS), j in intersect(S, sigmaS)
					if (i, j) in f.inst.A
						add_to_expression!(sum3, f.mipModel.x[i, j, k])
					end
				end

				if sum1val + sum2val + sum3val > length(S) - 1
					# println("Part 2")
					# println("sum1: ", sum1val, " sum2: ", sum2val, " sum3: ", sum3val)
					# println("sum1 + sum2 + sum3: ", sum1val + sum2val + sum3val)
					# println("length(S) - 1: ", length(S) - 1)
					# println(sum1val + sum2val + sum3val, " > ", length(S) - 1)
				end
				con = @build_constraint(sum1 + sum2 + sum3 <= length(S) - 1)
				MOI.submit(f.mipModel.model, MOI.UserCut(cb_data), con)
			end
		end
	end
end

function uc_all_strongly_connected_components_v1(f::CallbackClosure)
	return function (cb_data)
		# println("Running uc_all_strongly_connected_components_v1")
		x_val = callback_value.(Ref(cb_data), f.mipModel.x)
		t_val = callback_value.(Ref(cb_data), f.mipModel.t)
		tstart_val = callback_value.(Ref(cb_data), f.mipModel.tstart)
		tfinal_val = callback_value.(Ref(cb_data), f.mipModel.tfinal)
		C_val = callback_value.(Ref(cb_data), f.mipModel.C)

		nv = 2 * f.inst.n + 2
		maxdig = 2
		edge_list = Tuple{Int64, Int64}[]
		edge_weights = Array{String}(undef, nv, nv)
		capacity_matrix = zeros(Float64, nv, nv)
		for k in f.inst.K
			for (i, j) in f.inst.A
				if x_val[i, j, k] > f.params.epsilon
					cost_truncked = round(x_val[i, j, k] * 100, digits = maxdig)
					push!(edge_list, (i, j))
					edge_weights[i, j] = string(cost_truncked)
					capacity_matrix[i, j] += x_val[i, j, k]
				end
			end

			g = DiGraph(Edge.(edge_list))

			components = strongly_connected_components_tarjan(g)
			for S in components
				if length(S) > 1 && length(S) < length(f.inst.Vprime)
                    f.calls += 1
					node_labels = build_node_labels(f.inst, f.params, x_val, t_val, tstart_val, tfinal_val, C_val)
					filename = get_graph_dot_filename(f.calls)
					# save_graph_to_dot(g, filename, edge_weights, node_labels)

					# println("Call: ", f.calls, " k: ", k)
					# println("S: ", S)

					sum1 = AffExpr(0)
					sum1val = 0
					for k in f.inst.K, i in S, j in S
						if (i, j) in f.inst.A
							add_to_expression!(sum1, f.mipModel.x[i, j, k])
							sum1val += x_val[i, j, k]
						end
					end

					# println("sum1val: ", sum1val)
					# println("length(S) - 1: ", length(S) - 1)
					con = @build_constraint(sum1 <= length(S) - 1)
					MOI.submit(f.mipModel.model, MOI.UserCut(cb_data), con)
				end
			end
		end
	end
end

function uc_all_strongly_connected_components_v2(f::CallbackClosure)
	return function (cb_data)
		# println("Running uc_all_strongly_connected_components_v2")
		x_val = callback_value.(Ref(cb_data), f.mipModel.x)
		t_val = callback_value.(Ref(cb_data), f.mipModel.t)
		tstart_val = callback_value.(Ref(cb_data), f.mipModel.tstart)
		tfinal_val = callback_value.(Ref(cb_data), f.mipModel.tfinal)
		C_val = callback_value.(Ref(cb_data), f.mipModel.C)

		nv = 2 * f.inst.n + 2
		maxdig = 2
		edge_list = Tuple{Int64, Int64}[]
		edge_weights = Array{String}(undef, nv, nv)
		capacity_matrix = zeros(Float64, nv, nv)
		for k in f.inst.K
			for (i, j) in f.inst.A
				if x_val[i, j, k] > f.params.epsilon
					cost_truncked = round(x_val[i, j, k] * 100, digits = maxdig)
					push!(edge_list, (i, j))
					edge_weights[i, j] = string(cost_truncked)
					capacity_matrix[i, j] += x_val[i, j, k]
				end
			end

			g = DiGraph(Edge.(edge_list))

			components = strongly_connected_components_tarjan(g)
			for S in components
				if length(S) > 1 && length(S) < length(f.inst.Vprime)
                    f.calls += 1
					node_labels = build_node_labels(f.inst, f.params, x_val, t_val, tstart_val, tfinal_val, C_val)
					filename = get_graph_dot_filename(f.calls)
					# save_graph_to_dot(g, filename, edge_weights, node_labels)

					Sbar = setdiff(f.inst.Vprime, S)
					piS = [i for i in f.inst.V_p if i + f.inst.n in S]
					sigmaS = [i for i in f.inst.V_d if i - f.inst.n in S]

					# println("Call: ", f.calls, " k: ", k)
					# println("S: ", S)
					# println("Sbar: ", Sbar)
					# println("piS: ", piS)
					# println("sigmaS: ", sigmaS)

					sum1 = AffExpr(0)
					sum1val = 0
					for k in f.inst.K, i in S, j in S
						if (i, j) in f.inst.A
							add_to_expression!(sum1, f.mipModel.x[i, j, k])
							sum1val += x_val[i, j, k]
						end
					end
					sum2 = AffExpr(0)
					sum2val = 0
					for i in S, j in intersect(Sbar, piS)
						if (i, j) in f.inst.A
							add_to_expression!(sum2, f.mipModel.x[i, j, k])
							sum2val += x_val[i, j, k]
						end
					end
					sum3 = AffExpr(0)
					sum3val = 0
					for i in intersect(S, piS), j in setdiff(Sbar, piS)
						if (i, j) in f.inst.A
							add_to_expression!(sum3, f.mipModel.x[i, j, k])
							sum3val += x_val[i, j, k]
						end
					end

					if sum1val + sum2val + sum3val > length(S) - 1
						# println("Part 1")
						# println("sum1: ", sum1val, " sum2: ", sum2val, " sum3: ", sum3val)
						# println("sum1 + sum2 + sum3: ", sum1val + sum2val + sum3val)
						# println("length(S) - 1: ", length(S) - 1)
						# println(sum1val + sum2val + sum3val, " > ", length(S) - 1)
					end
					con = @build_constraint(sum1 + sum2 + sum3 <= length(S) - 1)
					MOI.submit(f.mipModel.model, MOI.UserCut(cb_data), con)

					sum2 = AffExpr(0)
					for i in intersect(Sbar, sigmaS), j in S
						if (i, j) in f.inst.A
							add_to_expression!(sum2, f.mipModel.x[i, j, k])
						end
					end
					sum3 = AffExpr(0)
					for i in setdiff(Sbar, sigmaS), j in intersect(S, sigmaS)
						if (i, j) in f.inst.A
							add_to_expression!(sum3, f.mipModel.x[i, j, k])
						end
					end

					if sum1val + sum2val + sum3val > length(S) - 1
						# println("Part 2")
						# println("sum1: ", sum1val, " sum2: ", sum2val, " sum3: ", sum3val)
						# println("sum1 + sum2 + sum3: ", sum1val + sum2val + sum3val)
						# println("length(S) - 1: ", length(S) - 1)
						# println(sum1val + sum2val + sum3val, " > ", length(S) - 1)
					end
					con = @build_constraint(sum1 + sum2 + sum3 <= length(S) - 1)
					MOI.submit(f.mipModel.model, MOI.UserCut(cb_data), con)
				end
			end
		end
	end
end

function uc_vehicle_used_or_not(f::CallbackClosure)
	return function (cb_data)
		# println("Running uc_vehicle_used_or_not")
		x_val = callback_value.(Ref(cb_data), f.mipModel.x)
		t_val = callback_value.(Ref(cb_data), f.mipModel.t)
		tstart_val = callback_value.(Ref(cb_data), f.mipModel.tstart)
		tfinal_val = callback_value.(Ref(cb_data), f.mipModel.tfinal)
		C_val = callback_value.(Ref(cb_data), f.mipModel.C)

		nv = 2 * f.inst.n + 2
		maxdig = 2
		edge_list = Tuple{Int64, Int64}[]
		edge_weights = Array{String}(undef, nv, nv)
		capacity_matrix = zeros(Float64, nv, nv)
		sumK = 0
		for (i, j) in f.inst.A
			for k in f.inst.K
				if x_val[i, j, k] > f.params.epsilon
					sumK += x_val[i, j, k]
				end
				if sumK > f.params.epsilon
					cost_truncked = round(sumK * 100, digits = maxdig)
					push!(edge_list, (i, j))
					edge_weights[i, j] = string(cost_truncked)
					capacity_matrix[i, j] = sumK
				end
			end
		end

		g = DiGraph(Edge.(edge_list))

		addedConstraint = false

		for (i, j) in f.inst.A
			if i != 1 && j != 2 * f.inst.n + 2
				for k in f.inst.K
					if x_val[1, 2*f.inst.n+2, k] + x_val[i, j, k] > 1 + f.params.epsilon
						f.calls += 1
						# println("Call: ", f.calls, " c2")
						# println("\t(i, j, k): ", (i, j, k))
						# println("\tx[1, 2*f.inst.n+2, k]: ", x_val[1, 2*f.inst.n+2, k])
						# println("\tx[i, j, k]: ", x_val[i, j, k])
						con = @build_constraint(f.mipModel.x[1, 2*f.inst.n+2, k] + f.mipModel.x[i, j, k] <= 1)
						MOI.submit(f.mipModel.model, MOI.UserCut(cb_data), con)
						addedConstraint = true
					end
				end
			end
		end

		if addedConstraint
			node_labels = build_node_labels(f.inst, f.params, x_val, t_val, tstart_val, tfinal_val, C_val)
			filename = get_graph_dot_filename(f.calls)
			# save_graph_to_dot(g, filename, edge_weights, node_labels)
		end
	end
end

