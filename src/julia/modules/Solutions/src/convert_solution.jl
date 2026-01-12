function updateSolFromLPSol!(
	sol::Solution,
	lpSol::LPSolution,
	inst::InstanceData,
	params::ParameterData,
)::Nothing
	for k in inst.K
		rt = sol.vehicles[k]
		if length(rt) > 2
			rt[1].servST = lpSol.tstart[k]
			for stop in rt[2:end-1]
				stop.servST = lpSol.t[stop.node]
			end
			rt[end].servST = lpSol.tfinal[k]
		end
		sol.completionTimes[k] = lpSol.C[k]
	end

	for h in inst.H
		mach = sol.machines[h]
		for mtrv in mach
			mtrv.st = lpSol.alpha[mtrv.orig, mtrv.dest, h]
		end
	end

	sol.feasible = true
	sol.value = lpSol.objValue
	return nothing
end # function updateSolFromLPSol!()
