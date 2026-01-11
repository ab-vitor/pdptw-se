
function detailed_analysis(inst, params, x, z, t, tstart, tfinal, C, phi, gamma, alpha)
	# c1
	println("@constraint(model, sumX == 1, base_name = 'c1')")
	for k in inst.K
		sumX = sum(x[1, j, k] for j in inst.V_p)
		sumX += x[1, 2*inst.n+2, k]
		println("sumX = ", sumX)
		for j in inst.V_p
			if x[1, j, k] > params.epsilon
				println("x[", 1, ", ", j, ", ", k, "] = ", x[1, j, k])
			end
		end
		if x[1, 2*inst.n+2, k] > params.epsilon
			println("x[", 1, ", ", 2 * inst.n + 2, ", ", k, "] = ", x[1, 2*inst.n+2, k])
		end

		println()
	end

	println("@constraint(model, x[1, 2*inst.n+2, k] + x[i, j, k] <= 1, base_name = 'c1.3')")
	for k in inst.K
		for (i, j) in inst.A
			if i != 1 && j != 2 * inst.n + 2
				if x[1, 2*inst.n+2, k] > params.epsilon || x[i, j, k] > params.epsilon
					println("x[1, $(2*inst.n+2), $(k)] +  x[$(i), $(j), $(k)] <= 1")
					println("$(x[1, 2*inst.n+2, k]) + $(x[i, j, k]) <= 1")
					println("$(x[1, 2*inst.n+2, k] + x[i, j, k]) <= 1")
					println()
				end
			end
		end
	end

	println("@constraint(model, x[i, j, k] + x[j, i, k] <= 1, base_name = 'c1.6')")
	for k in inst.K
		for (i, j) in inst.A
			if (j, i) in inst.A
				if x[i, j, k] > params.epsilon || x[j, i, k] > params.epsilon
					println("x[$(i), $(j), $(k)] +  x[$(j), $(i), $(k)] <= 1")
					println("$(x[i, j, k]) + $(x[j, i, k]) <= 1")
					println("$(x[i, j, k] + x[j, i, k]) <= 1")
					println()
				end
			end
		end
	end

	# c2
	println("@constraint(model, sum1 - sum2 == 0, base_name = 'c2')")
	for k in inst.K
		for i in inst.V_p_d
			sum1 = sum(x[j, i, k] for (j, p) in inst.A if p == i)
			sum2 = sum(x[i, j, k] for (p, j) in inst.A if p == i)

			println("sum1 = ", sum1)
			println("sum2 = ", sum2)
			if sum1 == 0 && sum2 == 0
				println()
				continue
			end

			println("------------- sum1 ---------------")
			for (j, p) in inst.A
				if p == i
					if x[j, i, k] > params.epsilon
						println("x[", j, ", ", i, ", ", k, "] = ", x[j, i, k])
					end
				end

			end

			println("------------- sum2 ---------------")
			for (p, j) in inst.A
				if p == i
					if x[i, j, k] > params.epsilon
						println("x[", i, ", ", j, ", ", k, "] = ", x[i, j, k])
					end
				end
			end
			println()
		end
	end

	# c3
	println("@constraint(model, sumX == 1, base_name = 'c3')")
	for k in inst.K
		sumX = sum(x[j, 2*inst.n+2, k] for j in inst.V_d)
		sumX += x[1, 2*inst.n+2, k]
		println("sumX = ", sumX)
		for j in inst.V_d
			if x[j, 2*inst.n+2, k] > params.epsilon
				println("x[", j, ", ", 2 * inst.n + 2, ", ", k, "] = ", x[j, 2*inst.n+2, k])
			end
		end
		if x[1, 2*inst.n+2, k] > params.epsilon
			println("x[", 1, ", ", 2 * inst.n + 2, ", ", k, "] = ", x[1, 2*inst.n+2, k])
		end
		println()
	end

	# c4
	println("@constraint(model, sumX == 1, base_name = 'c4')")
	for i in inst.V_p_d
		sumX = 0
		for k in inst.K
			for (j, p) in inst.A
				if p == i
					sumX += x[j, i, k]
					if x[j, i, k] > params.epsilon
						println("x[", j, ", ", i, ", ", k, "] = ", x[j, i, k])
					end
				end
			end
		end

		println("sumX = ", sumX)
		println()
	end

	# c4.3
	println("@constraint(model, sumX == 1, base_name = 'c4.3')")
	for i in inst.V_p_d
		sumX = 0
		for k in inst.K
			for (p, j) in inst.A
				if p == i
					sumX += x[i, j, k]
					if x[i, j, k] > params.epsilon
						println("x[", i, ", ", j, ", ", k, "] = ", x[i, j, k])
					end
				end
			end
		end

		println("sumX = ", sumX)
		println()
	end

	# # c4.6
	# println("@constraint(model, sumX == 2 * inst.n, base_name = 'c4.6')")
	# sumX = 0
	# for i in inst.V_p_d
	# 	for k in inst.K
	# 		for (j, p) in inst.A
	# 			if p == i
	# 				if x[j, i, k] > params.epsilon
	# 					sumX += x[j, i, k]
	# 					println("x[$(j), $(i), $(k)] = $(x[j,i,k])")
	# 				end
	# 			end
	# 		end
	# 	end
	# 	println()
	# end
	# println("sumX = ", sumX)
	# println()

	# c5
	println("@constraint(model, sum1 == sum2, base_name = 'c5')")
	for k in inst.K
		for i in inst.V_p
			sum1 = 0
			for (j, p) in inst.A
				if p == i
					sum1 += x[j, i, k]
					if x[j, i, k] > params.epsilon
						println("x[", j, ", ", i, ", ", k, "] = ", x[j, i, k])
					end
				end
			end
			println("sum1 = ", sum1)

			sum2 = AffExpr(0)
			for (j, p) in inst.A
				if p == inst.n + i
					sum2 += x[j, inst.n+i, k]
					if x[j, inst.n+i, k] > params.epsilon
						println("x[", j, ", ", inst.n + i, ", ", k, "] = ", x[j, inst.n+i, k])
					end
				end
			end
			println("sum2 = ", sum2)
			println()
		end
	end

	# c13
	println("@constraint(model, t[j] >= t[i] + inst.s[i] + inst.d[i, j, k] - inst.M[2] * (1 - x[i, j, k]), base_name = 'c13')")
	for k in inst.K
		for (i, j) in inst.A
			if i != 1 && j in inst.V_p_d
				if x[i, j, k] > params.epsilon
					println(
						"t[",
						j,
						"] >= t[",
						i,
						"] + inst.s[",
						i,
						"] + inst.d[",
						i,
						", ",
						j,
						", ",
						k,
						"]: ",
						t[j],
						" >= ",
						t[i],
						" + ",
						inst.s[i],
						" + ",
						inst.d[i, j, k],
					)
					println("- inst.M[2] * (1 - x[", i, ", ", j, ", ", k, "])", " - ", inst.M[2], " * (1 - ", x[i, j, k], ")")
					println(-inst.M[2] * (1 - x[i, j, k]))
					println(t[j], " >= ", t[i] + inst.s[i] + inst.d[i, j, k] - inst.M[2] * (1 - x[i, j, k]))
					println()
				end
			end
		end
	end

	# c14
	println("@constraint(model, t[j] >= tstart[k] + inst.d[1, j, k] - inst.M[3] * (1 - x[1, j, k]), base_name = 'c14')")
	for k in inst.K
		for (p, j) in inst.A
			if p == 1 && j in inst.V_p_d
				if x[1, j, k] > params.epsilon
					println(
						"t[",
						j,
						"] >= tstart[",
						k,
						"] + inst.d[1, ",
						j,
						", ",
						k,
						"]: ",
						t[j],
						" >= ",
						tstart[k],
						" + ",
						inst.d[1, j, k],
					)
					println("- inst.M[3] * (1 - x[", 1, ", ", j, ", ", k, "])", " - ", inst.M[3], " * (1 - ", x[1, j, k], ")")
					println(-inst.M[3] * (1 - x[1, j, k]))
					println(t[j], " >= ", tstart[k] + inst.d[1, j, k] - inst.M[3] * (1 - x[1, j, k]))
					println()
				end
			end
		end
	end

	# c15
	println("@constraint(model, t[i] + inst.s[i] + sumX <= t[inst.n+i], base_name = 'c15')")
	for i in inst.V_p
		sumX = 0
		for k in inst.K
			for (l, p) in inst.A
				if p == i
					if x[l, i, k] > params.epsilon
						sumX += inst.d[i, inst.n+i, k] * x[l, i, k]
						println(
							"inst.d[",
							i,
							", ",
							inst.n + i,
							", ",
							k,
							"] * x[",
							l,
							", ",
							i,
							", ",
							k,
							"] = ",
							inst.d[i, inst.n+i, k],
							" * ",
							x[l, i, k],
							" = ",
							inst.d[i, inst.n+i, k] * x[l, i, k],
						)
					end
				end
			end
		end
		println("t[", i, "] + inst.s[", i, "] + ", sumX, " <= t[", inst.n + i, "]")
		println(t[i], " + ", inst.s[i], " + ", sumX, " <= ", t[inst.n+i])
		println(t[i] + inst.s[i] + sumX, " <= ", t[inst.n+i])
		println()
	end

	# c16
	println("@constraint(model, sum1 == sum2, base_name = 'c16')")
	for (i, j) in inst.A_m
		sum1 = 0
		for h in inst.H_e[i][j]
			sum1 += phi[i, j, h]
			if phi[i, j, h] > params.epsilon
				println("phi[", i, ", ", j, ", ", h, "] = ", phi[i, j, h])
			end
		end
		println("sum1 = ", sum1)

		sum2 = 0
		for k in inst.K
			sum2 += x[i, j, k]
			if x[i, j, k] > params.epsilon
				println("x[", i, ", ", j, ", ", k, "] = ", x[i, j, k])
			end
		end
		println("sum2 = ", sum2)
		println()
	end

	# c17
	println(
		"@constraint(model, alpha[i, j, h] >= t[i] + inst.s[i] + inst.d_bar[i, h, k] - inst.M[4] * (1 - phi[i, j, h]), base_name = 'c17')",
	)
	for (i, j) in inst.A_m
		for k in inst.K
			for h in inst.H_e[i][j]
				if i != 1
					if phi[i, j, h] > params.epsilon && k == 1
						println("alpha[", i, ", ", j, ", ", h, "] >= t[", i, "] + inst.s[", i, "] + inst.d_bar[", i, ",", h, ",", k, "]")
						println(alpha[i, j, h], " >= ", t[i], " + ", inst.s[i], " + ", inst.d_bar[i, h, k])
						println("- inst.M[4] * (1 - phi[", i, ", ", j, ", ", h, "]) = ", -inst.M[4], " * (1 - ", phi[i, j, h], ")")
						println("= ", -inst.M[4] * (1 - phi[i, j, h]))
						println(alpha[i, j, h], " >= ", t[i] + inst.s[i] + inst.d_bar[i, h, k])
						println(alpha[i, j, h], " >= ", t[i] + inst.s[i] + inst.d_bar[i, h, k] - inst.M[4] * (1 - phi[i, j, h]))
						println()
					end
				end
			end
		end
	end

	# c18
	println("@constraint(model, alpha[1, j, h] >= tstart[k] + inst.d_bar[1, h, k] - inst.M[5] * (1 - phi[1, j, h]), base_name = 'c18')")
	for (i, j) in inst.A_m
		for h in inst.H_e[i][j]
			for k in inst.K
				if i == 1
					if phi[1, j, h] > params.epsilon
						println("alpha[", 1, ", ", j, ", ", h, "] >= tstart[", k, "] + inst.d_bar[1,", h, ",", k, "]")
						println(alpha[1, j, h], " >= ", tstart[k], " + ", inst.d_bar[1, h, k])
						println("- inst.M[5] * (1 - phi[", 1, ", ", j, ", ", h, "]) = ", -inst.M[5], " * (1 - ", phi[1, j, h], ")")
						println("= ", -inst.M[5] * (1 - phi[1, j, h]))
						println(alpha[1, j, h], " >= ", tstart[i] + inst.d_bar[1, h, k])
						println(alpha[i, j, h], " >= ", tstart[i] + inst.d_bar[1, h, k] - inst.M[5] * (1 - phi[1, j, h]))
						println()
					end
				end
			end
		end
	end

	# c19
	println(
		"@constraint(model, t[j] >= alpha[i, j, h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.d_bar[j, h, k] - inst.M[6] * (2 - phi[i, j, h] - x[i, j, k]), base_name = 'c19')",
	)
	for (i, j) in inst.A_m
		for k in inst.K
			for h in inst.H_e[i][j]
				if j in inst.V_p_d
					if phi[i, j, h] > params.epsilon && x[i, j, k] > params.epsilon
						println(
							"t[",
							j,
							"] >= alpha[",
							i,
							", ",
							j,
							", ",
							h,
							"] + inst.O[(",
							inst.f[i][h],
							", ",
							inst.f[j][h],
							", ",
							h,
							")] + inst.d_bar[",
							j,
							"][",
							h,
							"][",
							k,
							"]",
						)
						println(t[j], " >= ", alpha[i, j, h], " + ", inst.O[(inst.f[i][h], inst.f[j][h], h)], " + ", inst.d_bar[j, h, k])
						println(t[j], " >= ", alpha[i, j, h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.d_bar[j, h, k])
						println(
							"- inst.M[6] * (2 - phi[",
							i,
							", ",
							j,
							", ",
							h,
							"] - x[",
							1,
							", ",
							j,
							", ",
							k,
							"])",
							" = ",
							inst.M[6],
							" * (2 - ",
							phi[i, j, h],
							" - ",
							x[i, j, k],
							")",
						)
						println(-inst.M[6] * (2 - phi[i, j, h] - x[i, j, k]))
						println(
							t[j],
							" >= ",
							alpha[i, j, h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.d_bar[j, h, k] -
							inst.M[6] * (2 - phi[i, j, h] - x[i, j, k]),
						)
						println()
					end
				end
			end
		end
	end

	# c20
	println(
		"@constraint(model, gamma[i, j, iprime, jprime, h] + gamma[iprime, jprime, i, j, h] >= phi[i, j, h] + phi[iprime, jprime, h] - 1, base_name = 'c20')",
	)
	for (i, j) in inst.A_m
		for (iprime, jprime) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
				if (i, j) != (iprime, jprime)
					if phi[i, j, h] > params.epsilon && phi[iprime, jprime, h] > params.epsilon &&
					   (gamma[i, j, iprime, jprime, h] > params.epsilon || gamma[iprime, jprime, i, j, h] > params.epsilon)
						println(
							"gamma[",
							i,
							", ",
							j,
							", ",
							iprime,
							", ",
							jprime,
							", ",
							h,
							"] + gamma[",
							iprime,
							", ",
							jprime,
							", ",
							i,
							", ",
							j,
							", ",
							h,
							"] >= phi[",
							i,
							", ",
							j,
							", ",
							h,
							"] + phi[",
							iprime,
							", ",
							jprime,
							", ",
							h,
							"] - 1",
						)
						println(
							gamma[i, j, iprime, jprime, h],
							" + ",
							gamma[iprime, jprime, i, j, h],
							" >= ",
							phi[i, j, h],
							" + ",
							phi[iprime, jprime, h],
							" - 1",
						)
						println(
							gamma[i, j, iprime, jprime, h] + gamma[iprime, jprime, i, j, h],
							" >= ",
							phi[i, j, h] + phi[iprime, jprime, h] - 1,
						)
						println()
					end
				end
			end
		end
	end

	# c21
	println("@constraint(model, gamma[i, j, iprime, jprime, h] <= phi[i, j, h], base_name = 'c21')")
	for (i, j) in inst.A_m
		for (iprime, jprime) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
				if (i, j) != (iprime, jprime)
					if gamma[i, j, iprime, jprime, h] > params.epsilon && phi[i, j, h] > params.epsilon
						println("gamma[", i, ", ", j, ", ", iprime, ", ", jprime, ", ", h, "] <= phi[", i, ", ", j, ", ", h, "]")
						println(gamma[i, j, iprime, jprime, h], " <= ", phi[i, j, h])
						println()
					end
				end
			end
		end
	end


	# c22
	println("@constraint(model, gamma[iprime, jprime, i, j, h] <= phi[i, j, h], base_name = 'c22')")
	for (i, j) in inst.A_m
		for (iprime, jprime) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
				if (i, j) != (iprime, jprime)
					if gamma[iprime, jprime, i, j, h] > params.epsilon && phi[i, j, h] > params.epsilon
						println("gamma[", iprime, ", ", jprime, ", ", i, ", ", j, ", ", h, "] <= phi[", i, ", ", j, ", ", h, "]")
						println(gamma[iprime, jprime, i, j, h], " <= ", phi[i, j, h])
						println()
					end
				end
			end
		end
	end

	# c23 - test
	println("@constraint(model, gamma[i, j, iprime, jprime, h] + gamma[iprime, jprime, i, j, h] <= 1, base_name = 'c23')")
	for (i, j) in inst.A_m
		for (iprime, jprime) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
				if (i, j) != (iprime, jprime)
					if gamma[i, j, iprime, jprime, h] > params.epsilon || gamma[iprime, jprime, i, j, h] > params.epsilon
						println(
							"gamma[",
							i,
							", ",
							j,
							", ",
							iprime,
							", ",
							jprime,
							", ",
							h,
							"] + gamma[",
							iprime,
							", ",
							jprime,
							", ",
							i,
							", ",
							j,
							", ",
							h,
							"] <= 1",
						)
						println(gamma[i, j, iprime, jprime, h], " + ", gamma[iprime, jprime, i, j, h], " <= ", 1)
						println(gamma[i, j, iprime, jprime, h] + gamma[iprime, jprime, i, j, h], " <= ", 1)
						println()
					end
				end
			end
		end
	end

	# c24
	println(
		"@constraint(model, alpha[iprime, jprime, h] >= alpha[i, j, h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.O[(inst.f[j][h], inst.f[iprime][h], h)] - inst.M[7] * (1 - gamma[i, j, iprime, jprime, h]), base_name = 'c24')",
	)
	for (i, j) in inst.A_m
		for (iprime, jprime) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime], inst.H_e[j][iprime])
				if (i, j) != (iprime, jprime)
					if gamma[i, j, iprime, jprime, h] > params.epsilon
						println(
							"alpha[",
							iprime,
							", ",
							jprime,
							", ",
							h,
							"] >= alpha[",
							i,
							", ",
							j,
							", ",
							h,
							"] + inst.O[(",
							inst.f[i][h],
							", ",
							inst.f[j][h],
							", ",
							h,
							")] + inst.O[(",
							inst.f[j][h],
							", ",
							inst.f[iprime][h],
							", ",
							h,
							")]",
						)
						println(
							alpha[iprime, jprime, h],
							" >= ",
							alpha[i, j, h],
							" + ",
							inst.O[(inst.f[i][h], inst.f[j][h], h)],
							" + ",
							inst.O[(inst.f[j][h], inst.f[iprime][h], h)],
						)
						println(
							alpha[iprime, jprime, h],
							" >= ",
							alpha[i, j, h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.O[(inst.f[j][h], inst.f[iprime][h], h)],
						)
						println("- inst.M[7] * (1 - gamma[", i, ", ", j, ", ", iprime, ", ", jprime, ", ", h, "])")
						println(-inst.M[7], " * ", "(1 - ", gamma[i, j, iprime, jprime, h], ")")
						println(-inst.M[7] * (1 - gamma[i, j, iprime, jprime, h]))
						println(
							alpha[iprime, jprime, h],
							" >= ",
							alpha[i, j, h] + inst.O[(inst.f[i][h], inst.f[j][h], h)] + inst.O[(inst.f[j][h], inst.f[iprime][h], h)] -
							inst.M[7] * (1 - gamma[i, j, iprime, jprime, h]),
						)
						println()
					end
				end
			end
		end
	end

	# c25
	println("@constraint(model, alpha[i, j, h] >= inst.O[(1, inst.f[i][h], h)] - inst.M[8] * (1 - phi[i, j, h]), base_name = 'c25')")
	for (i, j) in inst.A_m
		for h in inst.H_e[i][j]
			if phi[i, j, h] > params.epsilon
				println("alpha[", i, ", ", j, ", ", h, "] >= inst.O[(", 1, ", ", inst.f[i][h], ", ", h, ")]")
				println(alpha[i, j, h], " >= ", inst.O[(1, inst.f[i][h], h)])
				println("- inst.M[8] * (1 - phi[", i, ", ", j, ", ", h, "])")
				println(-inst.M[8], " * ", "(1 - ", phi[i, j, h], ")")
				println(-inst.M[8] * (1 - phi[i, j, h]))
				println(alpha[i, j, h], " >= ", inst.O[(1, inst.f[i][h], h)] - inst.M[8] * (1 - phi[i, j, h]))
				println()
			end
		end
	end

	# c26
	println(
		"@constraint(model, tfinal[k] >= t[i] + inst.s[i] + inst.d[i, 2*inst.n+2, k] - inst.M[2] * (1 - x[i, 2*inst.n+2, k]), base_name = 'c26')",
	)
	for k in inst.K
		for (i, p) in inst.A
			if p == 2 * inst.n + 2 && i != 1
				if x[i, 2*inst.n+2, k] > params.epsilon
					println(
						"tfinal[",
						k,
						"] >= t[",
						i,
						"] + inst.s[",
						i,
						"] + inst.d[",
						i,
						", ",
						2 * inst.n + 2,
						", ",
						k,
						"]: ",
						tfinal[k],
						" >= ",
						t[i],
						" + ",
						inst.s[i],
						" + ",
						inst.d[i, 2*inst.n+2, k],
					)
					println(
						"- inst.M[2] * (1 - x[",
						i,
						", ",
						2 * inst.n + 2,
						", ",
						k,
						"])",
						" - ",
						inst.M[2],
						" * (1 - ",
						x[i, 2*inst.n+2, k],
						")",
					)
					println(-inst.M[2] * (1 - x[i, 2*inst.n+2, k]))
					println(tfinal[k], " >= ", t[i] + inst.s[i] + inst.d[i, 2*inst.n+2, k] - inst.M[2] * (1 - x[i, 2*inst.n+2, k]))
					println()
				end
			end
		end
	end

	# c27
	println(
		"@constraint(model, tfinal[k] >= alpha[i, 2*inst.n+2, h] + inst.O[(inst.f[i][h], inst.f[2*inst.n+2][h], h)] + inst.d_bar[2*inst.n+2, h, k] - inst.M[4] * (2 - phi[i, 2*inst.n+2, h] - x[i, 2*inst.n+2, k]), base_name = 'c27')",
	)
	for (i, p) in inst.A_m
		if p == 2 * inst.n + 2
			for k in inst.K
				for h in inst.H_e[i][p]
					if phi[i, 2*inst.n+2, h] > params.epsilon && x[i, 2*inst.n+2, k] > params.epsilon
						println(
							"tfinal[",
							k,
							"] >= alpha[",
							i,
							", ",
							2 * inst.n + 2,
							", ",
							h,
							"] + inst.O[(",
							inst.f[i][h],
							", ",
							inst.f[2*inst.n+2][h],
							", ",
							h,
							")] + inst.d_bar[",
							2 * inst.n + 2,
							",",
							h,
							",",
							k,
							"]: ",
							tfinal[k],
							" >= ",
							alpha[i, 2*inst.n+2, h],
							" + ",
							inst.O[(inst.f[i][h], inst.f[2*inst.n+2][h], h)],
							" + ",
							inst.d_bar[2*inst.n+2, h, k],
						)
						println(
							"- inst.M[4] * (2 - phi[",
							i,
							", ",
							2 * inst.n + 2,
							", ",
							h,
							"] - x[",
							i,
							", ",
							2 * inst.n + 2,
							", ",
							k,
							"])",
							" - ",
							inst.M[4],
							" * (2 - ",
							phi[i, 2*inst.n+2, h],
							" - ",
							x[i, 2*inst.n+2, k],
							")",
						)
						println(-inst.M[4] * (2 - phi[i, 2*inst.n+2, h] - x[i, 2*inst.n+2, k]))
						println(
							tfinal[k],
							" >= ",
							alpha[i, 2*inst.n+2, h] + inst.d_bar[2*inst.n+2, h, k] -
							inst.M[4] * (2 - phi[i, 2*inst.n+2, h] - x[i, 2*inst.n+2, k]),
						)
						println()
					end
				end
			end
		end
	end

	# c28
	println("@constraint(model, C[k] >= tfinal[k] - tstart[k], base_name = 'c28')")
	for k in inst.K
		println("C[", k, "] >= tfinal[", k, "] - tstart[", k, "]")
		println(C[k], " >= ", tfinal[k], " - ", tstart[k])
		println(C[k], " >= ", tfinal[k] - tstart[k])
		println()
	end

	# c29
	println("@constraint(model, inst.e[i] <= t[i] <= inst.l[i], base_name = 'c29')")
	for i in inst.V_p_d
		println("inst.e[", i, "] <= t[", i, "] <= inst.l[", i, "]")
		println(inst.e[i], " <= ", t[i], " <= ", inst.l[i])
		println()
	end

	# c30
	println("@constraint(model, inst.jobs[1].earl <= tstart[k], base_name = 'c30')")
	println("@constraint(model, tstart[k] <= tfinal[k], base_name = 'c30')")
	println("@constraint(model, tfinal[k] <= inst.jobs[1].lat, base_name = 'c30')")
	for k in inst.K
		println("inst.jobs[1].earl <= tstart[", k, "] <= tfinal[", k, "] <= ", inst.jobs[1].lat)
		println(inst.jobs[1].earl, " <= ", tstart[k], " <= ", tfinal[k], " <= ", inst.jobs[1].lat)
		println()
	end
end # function detailed_analysis()