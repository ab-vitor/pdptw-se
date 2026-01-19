function depot_flow_and_precedence_const(inst::InstanceData, sol::Solution, jobs_completed)
	for k in inst.K
		rt = sol.vehicles[k]
		if rt[1].job.id != 0
			println("Vehicle ", inst.vehicles[k].id, " doesn't start at depot")
			return false
		end
		jobs_completed[rt[1].node] = Any[true, k]
		if rt[end].job.id != 0
			println("Vehicle ", inst.vehicles[k].id, " doesn't end at depot")
			return false
		end
		jobs_completed[rt[end].node] = Any[true, k]

		for i in 2:length(rt)-1
			cstop = rt[i]
			if jobs_completed[cstop.node][1]
				println("Task was already done by vehicle ", jobs_completed[cstop.node][2])
				return false
			end
			if cstop.job.did == 0 # if delivery
				if jobs_completed[cstop.node-inst.n][2] == k && !jobs_completed[cstop.node-inst.n][1]
					println("Delivery job ", cstop.job.id, " was done before pickup", cstop.job.pid)
					return false
				end
				if jobs_completed[cstop.node-inst.n][2] != k && jobs_completed[cstop.node-inst.n][1]
					println(
						"Pickup job ",
						cstop.job.pid,
						" was done by another vehicle (pv=",
						jobs_completed[cstop.node-inst.n][2],
						") != (dv=",
						k,
						")",
					)
					return false
				end
			end
			jobs_completed[rt[i].node] = Any[true, k]
		end
	end

	return true
end # function depot_flow_and_precedence_const()

function all_jobs_completed_const(inst::InstanceData, jobs_completed)
	for i in inst.Vprime
		if !jobs_completed[i][1]
			println("Task ", inst.jobs[inst.refs[i]].id, " was not done")
			return false
		end
	end
	return true
end # function all_jobs_completed_const()

function capacity_const(inst::InstanceData, sol::Solution, params::ParameterData)
	for k in inst.K
		rt = sol.vehicles[k]
		for i in eachindex(rt)[2:end]
			if abs(rt[i].load - (rt[i-1].load + rt[i].job.dem)) > params.epsilon_cap
				println(
					"Vehicle load just after leaving node ",
					rt[i].job.id,
					" is different than the expected (",
					rt[i-1].load + rt[i].job.dem,
					")",
				)
				return false
			end
			if rt[i].load + params.epsilon_cap < 0 || rt[i].load > inst.vehicles[k].cap + params.epsilon_cap
				println(
					"Vehicle capacity was violated at position ",
					i,
					" of vehicle ",
					inst.vehicles[k].id,
					". Curr load: ",
					rt[i-1].load,
					"; Next demand: ",
					rt[i].job.dem,
					"; Vehicle capacity: ",
					inst.vehicles[k].cap,
				)
				return false
			end
		end
	end
	return true
end # function capacity_const()

function consecutive_stops_vehicles_const(inst::InstanceData, sol::Solution, params::ParameterData)
	for k in inst.K
		rt = sol.vehicles[k]
		for i in eachindex(rt)[2:end]
			cur = rt[i-1]
			nxt = rt[i]
			if nxt.job.point.z == cur.job.point.z &&
			   nxt.serv_start_time + params.epsilon < cur.serv_start_time + inst.s[cur.node] + inst.d[cur.node, nxt.node, k]
				println(
					"It's impossible to start the service time of request ",
					cur.job.id,
					" at ",
					cur.serv_start_time,
					" and arrive at ",
					nxt.serv_start_time,
					" in job ",
					nxt.job.id,
				)
				return false
			end
		end
	end

	return true
end # function consecutive_stops_vehicles_const()

function consecutive_travels_machines_const(inst::InstanceData, sol::Solution, params::ParameterData)
	for h in inst.H
		mach = sol.machines[h]
		if length(mach) == 0
			continue
		end
		if h in inst.H_e[1][mach[1].orig] && mach[1].st + params.epsilon < inst.O[(1, inst.f[mach[1].orig][h], h)]
			println(
				"Start time of travel 1 (",
				mach[1].st,
				") in machine ",
				h,
				" was before the machine arrives at the travel's origin (",
				inst.O[(1, inst.f[mach[1].orig][h], h)],
				")",
			)
			return false
		end
	end
	for h in inst.H
		mach = sol.machines[h]

		for i in eachindex(mach)[2:end]
			cur = mach[i-1]
			nxt = mach[i]
			if h in inst.H_e[cur.orig][cur.dest] && h in inst.H_e[cur.dest][nxt.orig] &&
			   nxt.st + params.epsilon <
			   cur.st + inst.O[(inst.f[cur.orig][h], inst.f[cur.dest][h], h)] + inst.O[(inst.f[cur.dest][h], inst.f[nxt.orig][h], h)]
				println(
					"Start time of travel ",
					i,
					" (",
					nxt.st,
					") in machine ",
					inst.machines[h].id,
					" was before the machine arrives at the travel's origin (",
					cur.st + inst.O[(inst.f[cur.orig][h], inst.f[cur.dest][h], h)] + inst.O[(inst.f[cur.dest][h], inst.f[nxt.orig][h], h)],
					")",
				)
				return false
			end
		end
	end

	return true
end # function consecutive_travels_machines_const()

function time_window_const(inst::InstanceData, sol::Solution, params::ParameterData)
	for k in inst.K
		for stop in sol.vehicles[k]
			if stop.serv_start_time > stop.job.lat + params.epsilon
				println(
					"Vehicle ",
					k,
					" arrived at job ",
					stop.job.id,
					" after (",
					stop.serv_start_time,
					") the end of time window (",
					stop.job.lat,
					")",
				)
				return false
			end
		end
	end

	return true
end # function time_window_const()

function vehicle_machine_travel_synchronization_const(inst::InstanceData, sol::Solution, params::ParameterData)
	for h in inst.H
		for travel in sol.machines[h]
			cStop = sol.vehicles[travel.vehicle][travel.vehicle_index-1]
			nStop = sol.vehicles[travel.vehicle][travel.vehicle_index]
			if travel.st + params.epsilon < cStop.serv_start_time + inst.s[travel.orig] + inst.d_bar[travel.orig, h, travel.vehicle]
				println(
					"Start time of the travel ",
					(cStop.job.id, nStop.job.id),
					" is before vehicle ",
					inst.vehicles[travel.vehicle].id,
					" arrives at the machine ",
					inst.machines[h].id,
					". (",
					travel.st,
					") < (",
					cStop.serv_start_time + inst.s[travel.orig] + inst.d_bar[travel.orig, h, travel.vehicle],
					")",
				)
				return false
			end
			if nStop.serv_start_time + params.epsilon <
			   travel.st + inst.O[(inst.f[travel.orig][h], inst.f[travel.dest][h], h)] + inst.d_bar[travel.dest, h, travel.vehicle]
				println(
					"Arrival time of vehicle ",
					inst.vehicles[travel.vehicle].id,
					" after the travel ",
					(cStop.job.id, nStop.job.id),
					" at machine ",
					inst.machines[h].id,
					" is before the given arrival time. (",
					travel.st + inst.O[(inst.f[travel.orig][h], inst.f[travel.dest][h], h)] + inst.d_bar[travel.dest, h, travel.vehicle],
					") < (",
					nStop.serv_start_time,
					")",
				)
				return false
			end
		end
	end

	return true
end # function vehicle_machine_travel_synchronization_const

function completion_times_const(inst::InstanceData, sol::Solution, params::ParameterData)
	for k in inst.K
		completion_time = sol.vehicles[k][end].serv_start_time - sol.vehicles[k][1].serv_start_time
		if abs(completion_time - sol.completion_times[k]) > params.epsilon
			println("Completion time calculated (", completion_time, ") is different from expected (", sol.completion_times[k], ")")
			return false
		end
	end

	return true
end

function validate_solution(inst::InstanceData, sol::Solution, params::ParameterData, partialValidation::Bool = false)

	jobs_completed = [Any[false, 0] for i in inst.Vprime] # for each node: 1st visited; 2nd which vehicle
	if !depot_flow_and_precedence_const(inst, sol, jobs_completed)
		return false
	end

	if !partialValidation && !all_jobs_completed_const(inst, jobs_completed)
		return false
	end

	if !capacity_const(inst, sol, params)
		return false
	end

	if !consecutive_stops_vehicles_const(inst, sol, params)
		return false
	end

	if !consecutive_travels_machines_const(inst, sol, params)
		return false
	end

	if !time_window_const(inst, sol, params)
		return false
	end

	if !vehicle_machine_travel_synchronization_const(inst, sol, params)
		return false
	end

	if !completion_times_const(inst, sol, params)
		return false
	end

	return true
end # validate_solution