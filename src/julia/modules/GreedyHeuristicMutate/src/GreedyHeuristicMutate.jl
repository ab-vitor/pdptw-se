module GreedyHeuristicMutate

using Data
using Parameters
using Solutions
using Random

include("structures.jl")
include("init_solution.jl")
include("update_solution.jl")


function find_next_active_machine_travel(machine::Vector{MachineTravel}, pos::Ref{Int64})::MachineTravel
	trv = machine[pos[]]
	while !trv.active
		pos[] += 1
		trv = machine[pos[]]
	end
	return trv
end # function find_next_active_machine_travel

function analyse_possible_machine_travel_from_last_computed_possible_machine_travel!(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	curr_time::Float64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possible_machine_travels::Vector{Vector},
	h::Int64,
	best_possible_machine_travel::Ref{PossibleMachineTravel},
	start_h_pos::Ref{Int64},
)::Nothing
	last_possible_machine_travel = possible_machine_travels[h][end]
	start_h_pos[] = last_possible_machine_travel.h_pos
	trv_1 = last_possible_machine_travel
	trv_2 = find_next_active_machine_travel(machines[h], start_h_pos)

	trv_1_end = trv_1.st + inst.O[(inst.f[trv_1.orig][h], inst.f[trv_1.dest][h], h)]
	h_arr = trv_1_end + inst.O[(inst.f[trv_1.dest][h], inst.f[prev_stop.node][h], h)]
	k_arr = curr_time + inst.d_bar[prev_stop.node, h, k]
	new_trv_end = max(h_arr, k_arr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
	if start_h_pos[] == length(machines[h]) || new_trv_end + inst.O[(inst.f[curr_stop.node][h], inst.f[trv_2.orig][h], h)] <= trv_2.st
		deltaT = new_trv_end - curr_time
		deltaT += inst.d_bar[curr_stop.node, h, k]
		if !best_possible_machine_travel[].found || deltaT < best_possible_machine_travel[].deltaT
			best_possible_machine_travel[] = PossibleMachineTravel(true, deltaT, h, start_h_pos[], max(h_arr, k_arr), prev_stop.node, curr_stop.node)
		end
	end
	return nothing
end # function analyse_possible_machine_travel_from_last_computed_possible_machine_travel!()

function get_best_vehicle_travel_time(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	curr_time::Float64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possible_machine_travels::Vector{Vector},
)::Float64
	if prev_stop.job.point.z == curr_stop.job.point.z
		return inst.d[prev_stop.node, curr_stop.node, k]
	end

	best_possible_machine_travel = Ref(PossibleMachineTravel(false, 0, 0, 0, 0, 0, 0))
	for h in inst.H_e[prev_stop.node][curr_stop.node]
		start_h_pos = Ref(1)
		if length(possible_machine_travels[h]) > 0
			analyse_possible_machine_travel_from_last_computed_possible_machine_travel!(
				prev_stop,
				curr_stop,
				k,
				curr_time,
				inst,
				machines,
				possible_machine_travels,
				h,
				best_possible_machine_travel,
				start_h_pos,
			)
		end
		curr_h_pos = Ref(start_h_pos[])
		next_h_pos = Ref(curr_h_pos[] + 1)
		while next_h_pos[] <= length(machines[h])
			trv_1 = find_next_active_machine_travel(machines[h], curr_h_pos)
			next_h_pos[] = curr_h_pos[] + 1

			trv_2 = find_next_active_machine_travel(machines[h], next_h_pos)

			if curr_h_pos[] == 1
				trv_1_end = trv_1.st
				h_arr = trv_1_end + inst.O[(inst.initial_station, inst.f[prev_stop.node][h], h)]
			else
				trv_1_end = trv_1.st + inst.O[(inst.f[trv_1.orig][h], inst.f[trv_1.dest][h], h)]
				h_arr = trv_1_end + inst.O[(inst.f[trv_1.dest][h], inst.f[prev_stop.node][h], h)]
			end
			k_arr = curr_time + inst.d_bar[prev_stop.node, h, k]
			new_trv_end = max(h_arr, k_arr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
			if next_h_pos[] == length(machines[h]) || new_trv_end + inst.O[(inst.f[curr_stop.node][h], inst.f[trv_2.orig][h], h)] <= trv_2.st
				deltaT = new_trv_end - curr_time
				deltaT += inst.d_bar[curr_stop.node, h, k]
				if !best_possible_machine_travel[].found || deltaT < best_possible_machine_travel[].deltaT
					best_possible_machine_travel[] =
						PossibleMachineTravel(true, deltaT, h, next_h_pos[], max(h_arr, k_arr), prev_stop.node, curr_stop.node)
				end
			end
			curr_h_pos[] += 1
			next_h_pos[] += 1
		end
	end
	if !best_possible_machine_travel[].found
		# Shouldn't be executed
		error("Error in get_best_vehicle_travel_time(): it should be always possible to schedule a new machine travel (time windows are checked later)")
	end
	push!(possible_machine_travels[best_possible_machine_travel[].h], best_possible_machine_travel[])

	return best_possible_machine_travel[].deltaT
end # function get_best_vehicle_travel_time()

function get_vehicle_travel_time(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machine_travels::Vector{PossibleMachineTravel},
	last_mach_trv::Ref{Int64},
	last_mach_trv_for_h::Vector{Int64},
)
	if prev_stop.job.point.z == curr_stop.job.point.z
		curr_stop.mach = 0
		return inst.d[prev_stop.node, curr_stop.node, k]
	end

	machTrv = machine_travels[last_mach_trv[]]
	curr_stop.mach = machTrv.h
	curr_stop.mach_index = machTrv.h_pos + last_mach_trv_for_h[machTrv.h] - 1
	return machTrv.deltaT

end # function get_vehicle_travel_time()

function advance_best_time(
	time::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possible_machine_travels::Vector{Vector},
)
	time += inst.s[prev_stop.node]
	time += get_best_vehicle_travel_time(prev_stop, curr_stop, k, time, inst, machines, possible_machine_travels)
	time = max(time, curr_stop.job.earl)
	return time
end # function advance_best_time()

function advance_time(
	time::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machine_travels::Vector{PossibleMachineTravel},
	last_mach_trv::Ref{Int64},
	last_mach_trv_for_h::Vector{Int64},
)::Float64
	time += inst.s[prev_stop.node]
	time += get_vehicle_travel_time(prev_stop, curr_stop, k, inst, machine_travels, last_mach_trv, last_mach_trv_for_h)
	time = max(time, curr_stop.job.earl)
	return time
end # function advance_time()

function check_insertion(
	sol::Solution,
	k::Int64,
	p_pos::Int64,
	d_pos::Int64,
	p_job::Int64,
	dJob::Int64,
	inst::InstanceData,
	possible_machine_travels::Vector{Vector},
)::CheckInsertionData
	feasible = true
	availableVehicle = true
	cost = 0
	loadCost = 0

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	curr_stop = VehicleStop(p_job, inst.jobs[inst.refs[p_job]], 0, 0, 0, 0)

	time = prev_stop.servST
	time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
	load = prev_stop.load + curr_stop.job.dem

	if time > curr_stop.job.lat || load > inst.Q[k]
		feasible = false
		cost += max(0, time - curr_stop.job.lat)
		availableVehicle = availableVehicle && !(load > maximum(inst.Q))
		loadCost = max(loadCost, (load - inst.Q[k]) * inst.Q[k])
	end

	prev_stop = curr_stop
	if p_pos != d_pos
		curr_stop = sol.vehicles[k][curr]
		time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
		load += curr_stop.job.dem
		if time > curr_stop.job.lat || load > inst.Q[k]
			feasible = false
			cost += max(0, time - curr_stop.job.lat)
			availableVehicle = availableVehicle && !(load > maximum(inst.Q))
			loadCost = max(loadCost, (load - inst.Q[k]) * inst.Q[k])
		end

		prev += 1
		curr += 1
		while curr < d_pos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
			load += curr_stop.job.dem
			if time > curr_stop.job.lat || load > inst.Q[k]
				feasible = false
				cost += max(0, time - curr_stop.job.lat)
				availableVehicle = availableVehicle && !(load > maximum(inst.Q))
				loadCost = max(loadCost, (load - inst.Q[k]) * inst.Q[k])
			end	
			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	curr_stop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		feasible = false
		cost += max(0, time - curr_stop.job.lat)
	end

	prev_stop = curr_stop
	curr_stop = sol.vehicles[k][curr]
	time = advance_best_time(time, prev_stop, curr_stop, k, inst, sol.machines, possible_machine_travels)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		feasible = false
		cost += max(0, time - curr_stop.job.lat)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
	time += inst.s[prev_stop.node]
	time += get_best_vehicle_travel_time(prev_stop, curr_stop, k, time, inst, sol.machines, possible_machine_travels)
		time = max(time, curr_stop.job.earl)
		if time > curr_stop.job.lat
			feasible = false
			cost += max(0, time - curr_stop.job.lat)
		end
		prev += 1
		curr += 1
	end
	if feasible
		return CheckInsertionData(feasible, cost > 0, loadCost > 0, time - sol.vehicles[k][end].servST, 0, availableVehicle)
	end

	return CheckInsertionData(feasible, cost > 0, loadCost > 0, cost, loadCost, availableVehicle)
end # function check_insertion()




function flat_chronologically(possible_machine_travels::Vector{Vector})
	machine_travels = collect(Iterators.flatten(possible_machine_travels))
	sort!(machine_travels, by = i -> (i.st))

	return machine_travels
end # function flat_chronologically()

function update_best_relax_data(
	checkInsData::CheckInsertionData,
	bestRelaxData::InsertionData,
	p_pos::Int64,
	d_pos::Int64,
	p_job::Int64,
	dJob::Int64,
	k::Int64,
	possible_machine_travels::Vector{Vector},
)
	feasible = checkInsData.feasible
	twViol = checkInsData.twViol
	capViol = checkInsData.capViol
	cost = checkInsData.cost
	loadCost = checkInsData.loadCost
	if twViol && capViol && cost + loadCost < bestRelaxData.cost
		machine_travels = flat_chronologically(possible_machine_travels)
		bestRelaxData = InsertionData(feasible, cost + loadCost, p_pos, d_pos, p_job, dJob, k, machine_travels)
	elseif cost > 0 && cost < bestRelaxData.cost
		machine_travels = flat_chronologically(possible_machine_travels)
		bestRelaxData = InsertionData(feasible, cost, p_pos, d_pos, p_job, dJob, k, machine_travels)
	elseif loadCost > 0 && loadCost < bestRelaxData.cost
		machine_travels = flat_chronologically(possible_machine_travels)
		bestRelaxData = InsertionData(feasible, loadCost, p_pos, d_pos, p_job, dJob, k, machine_travels)
	end
	return bestRelaxData
end # function update_best_relax_data()

function get_insertion_with_less_increase_in_comp_time(inst::InstanceData, sol::Solution, p_job::Int64, dJob::Int64)
	bestInsData = InsertionData(false, 0, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	bestRelaxData = InsertionData(false, Inf64, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	for k in inst.K
		for p_pos in 2:length(sol.vehicles[k])
			for d_pos in p_pos:length(sol.vehicles[k])
				possible_machine_travels = Vector[PossibleMachineTravel[] for _ in inst.H]
				deactivate_machine_travels(k, sol, p_pos)
				checkInsData = check_insertion(sol, k, p_pos, d_pos, p_job, dJob, inst, possible_machine_travels)
				reactivate_machine_travels(k, sol, p_pos)
				if !checkInsData.feasible && checkInsData.availableVehicle
					bestRelaxData = update_best_relax_data(checkInsData, bestRelaxData, p_pos, d_pos, p_job, dJob, k, possible_machine_travels)
					continue
				elseif !checkInsData.availableVehicle
					continue
				end

				if !bestInsData.feasible || checkInsData.cost < bestInsData.cost
					machine_travels = flat_chronologically(possible_machine_travels)
					bestInsData = InsertionData(true, checkInsData.cost, p_pos, d_pos, p_job, dJob, k, machine_travels)
				end
			end
		end
	end
	return bestInsData, bestRelaxData
end # function get_insertion_with_less_increase_in_comp_time()

function remove_dummy_objects!(sol::Solution, inst::InstanceData)
	for h in inst.H
		popfirst!(sol.machines[h])
		pop!(sol.machines[h])
	end

	for k in inst.K
		for i in 1:length(sol.vehicles[k])
			if sol.vehicles[k][i].mach != 0
				sol.vehicles[k][i].mach_index -= 1
			end
		end
	end
end # function remove_dummy_objects!()

function greedy_heuristic_mutate(inst::InstanceData, params::ParameterData)
	sol = init_solution(inst)
	nonServicedReqs = copy(get_service_order(inst, params))
	idxReqToServe = 1
	failedRedos = 0
	lastIdxReqToServeFailed = 0
	appliedRelaxation = false
	while idxReqToServe <= length(nonServicedReqs) && failedRedos <= inst.n
		p_job = nonServicedReqs[idxReqToServe]
		dJob = p_job + inst.n

		bestInsData, bestRelaxData = get_insertion_with_less_increase_in_comp_time(inst, sol, p_job, dJob)

		if bestInsData.feasible
			sol = update_solution(sol, bestInsData, inst)
			idxReqToServe += 1
		elseif params.make_instance_feasible
			appliedRelaxation = true
			sol = update_solution_with_relaxation(sol, bestRelaxData, inst)
			idxReqToServe += 1
		else
			lastIdxReqToServeFailed = idxReqToServe
			sol = init_solution(inst)
			failedReq = nonServicedReqs[idxReqToServe]
			popat!(nonServicedReqs, idxReqToServe)
			pushfirst!(nonServicedReqs, failedReq)
			idxReqToServe = 1
			failedRedos += 1
		end
	end

	remove_dummy_objects!(sol, inst)

	sol.completionTimes = Float64[rt[length(rt)].servST for rt in sol.vehicles]
	sol.value = sum(sol.completionTimes)
	print_timeline_solution(inst, sol)
	println(inst.name, ": ", sol.value)
	if validate_solution(inst, sol, params)
		sol.feasible = true
		println("Feasible solution! :D")
		if params.make_instance_feasible && params.methodCode == "greedy"
			if appliedRelaxation
				println("Updating instance...")
			end
			instanceDataToCsvFiles(inst, params, "g")
		end
	else
		sol.feasible = false
		println("Infeasible solution! :(")
	end
	return sol

end # function greedy_heuristic_mutate()

end # module GreedyHeuristicMutate
