function update_sol_from_LP_sol!(
	sol::Solution,
	LP_sol::LPSolution,
	inst::InstanceData,
)::Nothing
	for k in inst.K
		rt = sol.vehicles[k]
		if length(rt) > 2
			rt[1].serv_start_time = LP_sol.tstart[k]
			for stop in rt[2:end-1]
				stop.serv_start_time = LP_sol.t[stop.node]
			end
			rt[end].serv_start_time = LP_sol.tfinal[k]
		end
		sol.completion_times[k] = LP_sol.C[k]
	end

	for h in inst.H
		mach = sol.machines[h]
		for mtrv in mach
			mtrv.st = LP_sol.alpha[mtrv.orig, mtrv.dest, h]
		end
	end

	sol.feasible = true
	sol.value = LP_sol.obj_value
	return nothing
end # function update_sol_from_LP_sol!()
