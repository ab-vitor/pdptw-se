function findActiveMachineTravel(machine::Vector{MachineTravel}, pos::Ref{Int64}, k::Int64, p_pos::Int64, i::Int64 = 1)::MachineTravel
	if pos[] > length(machine)
		return MachineTravel(k, p_pos)
	end
	trv = machine[pos[]]
	while trv.vehicle == k &&
			  trv.vehicle_index >= p_pos &&
			  pos[] < length(machine)
		pos[] += i
		trv = machine[pos[]]
	end
	return trv
end # function findActiveMachineTravel()

function findFeasMtrvToInsertInMachine(
	machine::Vector{MachineTravel},
	h::Int64,
	start::Int64,
	k::Int64,
	p_pos::Int64,
	depTime::Float64,
	lbNewTrvEnd::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	vehicle_index::Int64,
	inst::InstanceData,
)::PossibleMachineTravel
	dummyMtrv = PossibleMachineTravel(false, 0, 0, 0, 0, 0, 0, 0)
	prevActiveMtrvPos = start - 1
	for posToInsert in eachindex(machine)[start:end]
		trv = machine[posToInsert]
		if trv.vehicle != k || trv.vehicle_index < p_pos
			if lbNewTrvEnd + inst.O[(inst.f[curr_stop.node][h], inst.f[trv.orig][h], h)] <= trv.st
				if prevActiveMtrvPos == 0
					initStationDepTime = inst.e[inst.depot_begin]
					hArr = initStationDepTime + inst.O[(inst.initial_station, inst.f[prev_stop.node][h], h)]
				else
					prevActTrv = machine[prevActiveMtrvPos]
					prevActTrvEnd = prevActTrv.st + inst.O[(inst.f[prevActTrv.orig][h], inst.f[prevActTrv.dest][h], h)]
					hArr = prevActTrvEnd + inst.O[(inst.f[prevActTrv.dest][h], inst.f[prev_stop.node][h], h)]
				end
				kArr = depTime + inst.d_bar[prev_stop.node, h, k]
				newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
				kArrAtCurrNode = newTrvEnd + inst.d_bar[curr_stop.node, h, k]
				if kArrAtCurrNode > curr_stop.job.lat
					return dummyMtrv
				elseif newTrvEnd + inst.O[(inst.f[curr_stop.node][h], inst.f[trv.orig][h], h)] <= trv.st
					deltaT = kArrAtCurrNode - depTime
					return PossibleMachineTravel(true, deltaT, h, posToInsert, max(hArr, kArr), prev_stop.node, curr_stop.node, vehicle_index)
				end
			end
			prevActiveMtrvPos = posToInsert
		end
	end

	if prevActiveMtrvPos == 0
		posToInsert = 1
		initStationDepTime = inst.e[inst.depot_begin]
		hArr = initStationDepTime + inst.O[(inst.initial_station, inst.f[prev_stop.node][h], h)]
		kArr = depTime + inst.d_bar[prev_stop.node, h, k]
		newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
		kArrAtCurrNode = newTrvEnd + inst.d_bar[curr_stop.node, h, k]
		if kArrAtCurrNode > curr_stop.job.lat
			return dummyMtrv
		else
			deltaT = kArrAtCurrNode - depTime
			return PossibleMachineTravel(true, deltaT, h, posToInsert, max(hArr, kArr), prev_stop.node, curr_stop.node, vehicle_index)
		end
	end

	posToInsert = length(machine) + 1
	prevActTrv = machine[prevActiveMtrvPos]
	prevActTrvEnd = prevActTrv.st + inst.O[(inst.f[prevActTrv.orig][h], inst.f[prevActTrv.dest][h], h)]
	hArr = prevActTrvEnd + inst.O[(inst.f[prevActTrv.dest][h], inst.f[prev_stop.node][h], h)]
	kArr = depTime + inst.d_bar[prev_stop.node, h, k]
	newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
	kArrAtCurrNode = newTrvEnd + inst.d_bar[curr_stop.node, h, k]
	if kArrAtCurrNode > curr_stop.job.lat
		return dummyMtrv
	end

	deltaT = kArrAtCurrNode - depTime
	return PossibleMachineTravel(true, deltaT, h, posToInsert, max(hArr, kArr), prev_stop.node, curr_stop.node, vehicle_index)
end # function findFeasMtrvToInsertInMachine()

function analysePossibleMachineTravelFromLastComputedPossibleMachineTravel(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	curr_time::Float64,
	inst::InstanceData,
	machine::Vector{MachineTravel},
	possibleMachineTravels::Vector{Vector},
	h::Int64,
	bestPossibleMachineTravel::Ref{PossibleMachineTravel},
	start_h_pos::Ref{Int64},
	vehicle_index::Int64,
	p_pos::Int64,
)::Bool
	lastPMtrv = possibleMachineTravels[h][end]
	start_h_pos[] = lastPMtrv.h_pos
	lastPMtrvEnd = lastPMtrv.st + inst.O[(inst.f[lastPMtrv.orig][h], inst.f[lastPMtrv.dest][h], h)]
	hArr = lastPMtrvEnd + inst.O[(inst.f[lastPMtrv.dest][h], inst.f[prev_stop.node][h], h)]
	kArr = curr_time + inst.d_bar[prev_stop.node, h, k]
	newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
	kArrAtCurrNode = newTrvEnd + inst.d_bar[curr_stop.node, h, k]
	if kArrAtCurrNode > curr_stop.job.lat
		return true
	end
	nextTrv = findActiveMachineTravel(machine, start_h_pos, k, p_pos)
	if !(nextTrv.vehicle == k && nextTrv.vehicle_index >= p_pos)
		if newTrvEnd + inst.O[(inst.f[curr_stop.node][h], inst.f[nextTrv.orig][h], h)] <= nextTrv.st
			deltaT = kArrAtCurrNode - curr_time
			if deltaT < bestPossibleMachineTravel[].deltaT
				bestPossibleMachineTravel[] =
					PossibleMachineTravel(true, deltaT, h, start_h_pos[], max(hArr, kArr), prev_stop.node, curr_stop.node, vehicle_index)
			end
			return true
		end
		return false
	else
		deltaT = kArrAtCurrNode - curr_time
		if deltaT < bestPossibleMachineTravel[].deltaT
			bestPossibleMachineTravel[] =
				PossibleMachineTravel(true, deltaT, h, start_h_pos[], max(hArr, kArr), prev_stop.node, curr_stop.node, vehicle_index)
		end
		return true
	end

end # function analysePossibleMachineTravelFromLastComputedPossibleMachineTravel()

function getBestMachineTravelTime(
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	depTime::Float64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possibleMachineTravels::Vector{Vector},
	vehicle_index::Int64,
	p_pos::Int64,
)::Float64
	bestPossibleMachineTravel = Ref(PossibleMachineTravel(false, Inf64, 0, 0, 0, 0, 0, 0))
	for h in inst.H_e[prev_stop.node][curr_stop.node]
		lbNewTrvEnd = depTime + inst.d_bar[prev_stop.node, h, k] + inst.O[(inst.f[prev_stop.node][h], inst.f[curr_stop.node][h], h)]
		if lbNewTrvEnd + inst.d_bar[curr_stop.node, h, k] > curr_stop.job.lat
			continue
		end

		start_h_pos = Ref(1)
		if length(possibleMachineTravels[h]) > 0 &&
		   analysePossibleMachineTravelFromLastComputedPossibleMachineTravel(
			prev_stop,
			curr_stop,
			k,
			depTime,
			inst,
			machines[h],
			possibleMachineTravels,
			h,
			bestPossibleMachineTravel,
			start_h_pos,
			vehicle_index,
			p_pos,
		)
			continue
		end

		mtrv = findFeasMtrvToInsertInMachine(
			machines[h], h, start_h_pos[],
			k, p_pos, depTime, lbNewTrvEnd,
			prev_stop, curr_stop, vehicle_index, inst,
		)
		if mtrv.found && mtrv.deltaT < bestPossibleMachineTravel[].deltaT
			bestPossibleMachineTravel[] = mtrv
		end
	end
	if !bestPossibleMachineTravel[].found
		return Inf64
		# # Shouldn't be executed
		# println("Houston, we have a problem")
		# exit(0)
	end
	push!(possibleMachineTravels[bestPossibleMachineTravel[].h], bestPossibleMachineTravel[])

	return bestPossibleMachineTravel[].deltaT
end # function getBestMachineTravelTime()


function advanceBestTime(
	time::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possibleMachineTravels::Vector{Vector},
	vehicle_index::Int64,
	p_pos::Int64,
)::Float64
	time += inst.s[prev_stop.node]
	if prev_stop.job.point.z == curr_stop.job.point.z
		time += inst.d[prev_stop.node, curr_stop.node, k]
	else
		time += getBestMachineTravelTime(prev_stop, curr_stop, k, time, inst, machines, possibleMachineTravels, vehicle_index, p_pos)
	end
	time = max(time, curr_stop.job.earl)
	return time
end # function advanceBestTime()

function advanceTime(
	time::Float64,
	prev_stop::VehicleStop,
	curr_stop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machineTravels::Vector{PossibleMachineTravel},
	lastMachTrv::Ref{Int64},
)::Float64
	time += inst.s[prev_stop.node]
	if prev_stop.job.point.z == curr_stop.job.point.z
		curr_stop.mach = 0
		time += inst.d[prev_stop.node, curr_stop.node, k]
	else
		machTrv = machineTravels[lastMachTrv[]]
		curr_stop.mach = machTrv.h
		lastMachTrv[] += 1
		time += machTrv.deltaT
	end
	time = max(time, curr_stop.job.earl)
	return time
end # function advanceTime()

function deactivateMachineTravels(k::Int64, sol::Solution, p_pos::Int64)
	for h in 1:length(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if sol.machines[h][i].vehicle == k && sol.machines[h][i].vehicle_index >= p_pos
				sol.machines[h][i].active = false
			end
		end
	end
end # function deactivateMachineTravels()

function checkInsertion(
	sol::Solution,
	k::Int64,
	p_pos::Int64,
	dPos::Int64,
	pJob::Int64,
	dJob::Int64,
	inst::InstanceData,
)::CheckInsertionData

	possibleMachineTravels = Vector[PossibleMachineTravel[] for _ in inst.H]

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	curr_stop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prev_stop.servST
	time = advanceBestTime(time, prev_stop, curr_stop, k, inst, sol.machines, possibleMachineTravels, curr, p_pos)
	load = prev_stop.load + curr_stop.job.dem

	if time > curr_stop.job.lat || load > inst.Q[k]
		return CheckInsertionData(false, 0, possibleMachineTravels)
	end

	prev_stop = curr_stop
	if p_pos != dPos
		curr_stop = sol.vehicles[k][curr]
		time = advanceBestTime(time, prev_stop, curr_stop, k, inst, sol.machines, possibleMachineTravels, curr + 1, p_pos)
		load += curr_stop.job.dem
		if time > curr_stop.job.lat || load > inst.Q[k]
			return CheckInsertionData(false, 0, possibleMachineTravels)
		end

		prev += 1
		curr += 1
		while curr < dPos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advanceBestTime(time, prev_stop, curr_stop, k, inst, sol.machines, possibleMachineTravels, curr + 1, p_pos)
			load += curr_stop.job.dem
			if time > curr_stop.job.lat || load > inst.Q[k]
				return CheckInsertionData(false, 0, possibleMachineTravels)
			end
			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	curr_stop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advanceBestTime(time, prev_stop, curr_stop, k, inst, sol.machines, possibleMachineTravels, curr + 1, p_pos)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		return CheckInsertionData(false, 0, possibleMachineTravels)
	end

	prev_stop = curr_stop
	curr_stop = sol.vehicles[k][curr]
	time = advanceBestTime(time, prev_stop, curr_stop, k, inst, sol.machines, possibleMachineTravels, curr + 2, p_pos)
	load += curr_stop.job.dem
	if time > curr_stop.job.lat
		return CheckInsertionData(false, 0, possibleMachineTravels)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
		# if curr_stop.job.earl == 411 && p_pos == 3 && dPos == 3
		# 	println("stophere")
		# end
		time = advanceBestTime(time, prev_stop, curr_stop, k, inst, sol.machines, possibleMachineTravels, curr + 2, p_pos)
		if time > curr_stop.job.lat
			return CheckInsertionData(false, 0, possibleMachineTravels)
		end
		prev += 1
		curr += 1
	end

	cost = time - sol.vehicles[k][end].servST
	return CheckInsertionData(true, cost, possibleMachineTravels)
end # function checkInsertion()

function removeDeactivatedTravels(sol::Solution)
	for h in 1:length(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if !sol.machines[h][i].active
				splice!(sol.machines[h], i)
			end
		end
	end
end # function removeDeactivatedTravels()

function updateMachinesIndexes(sol::Solution)
	for h in 1:length(sol.machines)
		for i in eachindex(sol.machines[h])[1:end]
			machTrv = sol.machines[h][i]
			sol.vehicles[machTrv.vehicle][machTrv.vehicle_index].mach_index = i
		end
	end
end # function updateMachinesIndexes

function insertMachineTravels(
	sol::Solution,
	machineTravels::Vector{PossibleMachineTravel},
	k::Int64,
)
	active = true
	for i in length(machineTravels):-1:1
		machTrv = machineTravels[i]
		insert!(
			sol.machines[machTrv.h],
			machTrv.h_pos,
			MachineTravel(k, machTrv.vehicle_index, machTrv.orig, machTrv.dest, machTrv.st, active),
		)
	end
end # function insertMachineTravels()

function updateSolution(sol::Solution, insData::InsertionData, inst::InstanceData)::Solution
	k = insData.k
	p_pos = insData.p_pos
	dPos = insData.dPos
	pJob = insData.pJob
	dJob = insData.dJob
	machineTravels = flatChronollogically(insData.machineTravels)

	deactivateMachineTravels(k, sol, p_pos)

	lastMachTrv = Ref(1)

	prev = p_pos - 1
	curr = p_pos
	prev_stop = sol.vehicles[k][prev]
	pickupStop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prev_stop.servST
	time = advanceTime(time, prev_stop, pickupStop, k, inst, machineTravels, lastMachTrv)
	load = prev_stop.load + pickupStop.job.dem

	pickupStop.servST = time
	pickupStop.load = load

	prev_stop = pickupStop
	if p_pos != dPos
		curr_stop = sol.vehicles[k][curr]
		time = advanceTime(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv)
		load += curr_stop.job.dem

		curr_stop.servST = time
		curr_stop.load = load

		prev += 1
		curr += 1
		while curr < dPos
			prev_stop = sol.vehicles[k][prev]
			curr_stop = sol.vehicles[k][curr]
			time = advanceTime(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv)
			load += curr_stop.job.dem

			curr_stop.servST = time
			curr_stop.load = load

			prev += 1
			curr += 1
		end
		prev_stop = sol.vehicles[k][prev]
	end

	deliveryStop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advanceTime(time, prev_stop, deliveryStop, k, inst, machineTravels, lastMachTrv)
	load += deliveryStop.job.dem

	deliveryStop.servST = time
	deliveryStop.load = load

	prev_stop = deliveryStop
	curr_stop = sol.vehicles[k][curr]
	time = advanceTime(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv)
	load += curr_stop.job.dem

	curr_stop.servST = time

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prev_stop = sol.vehicles[k][prev]
		curr_stop = sol.vehicles[k][curr]
		time = advanceTime(time, prev_stop, curr_stop, k, inst, machineTravels, lastMachTrv)
		curr_stop.servST = time
		prev += 1
		curr += 1
	end

	insert!(sol.vehicles[k], dPos, deliveryStop)
	insert!(sol.vehicles[k], p_pos, pickupStop)
	insertMachineTravels(sol, machineTravels, k)
	removeDeactivatedTravels(sol)
	sol.completionTimes[k] = sol.vehicles[k][end].servST
	sol.value += insData.cost

	return sol
end # function updateSolution()

function tightestTimeWindows(inst::InstanceData)::Vector{Int64}
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> (inst.l[i] - inst.e[i]))

	return reqs
end # function tightestTimeWindows()

function earliestTimeWindows(inst::InstanceData)::Vector{Int64}
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> inst.l[i])

end # function earliest_time_windows()

function randomOrderNodes(inst::InstanceData, params::ParameterData)::Vector{Int64}
	rkvector = rand(params.rng, Float64, inst.n)
	orderNodes = sortperm(rkvector) .+ 1

	return orderNodes
end # function randomOrderNodes

function initVehicleRoutes(inst::InstanceData)::Vector{Vector{VehicleStop}}
	# Start depot -> 1 in inst.Vprime, which is equivalent to 0 in paper
	firstVehicleStop = VehicleStop(1, inst.jobs[inst.refs[1]], 0, 0, 0, 0)
	# End depot -> 2*inst.n+2 in inst.Vprime, which is equivalent to 2*n+1 in paper
	lastVehicleStop = VehicleStop(2 * inst.n + 2, inst.jobs[inst.refs[2*inst.n+2]], 0, 0, 0, 0)

	vehicleRoutes = Vector{VehicleStop}[[copy(firstVehicleStop), copy(lastVehicleStop)] for _ in inst.K]

	return vehicleRoutes
end # function initVehicleRoutes()

function initMachineTravels(inst::InstanceData)::Vector{Vector{MachineTravel}}
	# Insert a dummy MachineTravel in each machine travels list with start time at 0 (code simplification)
	machineRoutes = Vector{MachineTravel}[[] for _ in inst.H]

	return machineRoutes
end # function initMachineTravels()

function getServiceOrder(inst::InstanceData, params::ParameterData)::Vector{Int64}
	if params.greedy_service_order == "tightest_tw"
		return tightestTimeWindows(inst)
	elseif params.greedy_service_order == "earliest_tw"
		return earliestTimeWindows(inst)
	elseif params.greedy_service_order == "random"
		return randomOrderNodes(inst, params)
	end

	return inst.V_p # just in case
end # function getServiceOrder()

function initSolution(inst::InstanceData)::Solution
	initialVehicleRoutes = initVehicleRoutes(inst)
	initialMachineTravels = initMachineTravels(inst)
	initialCompletionTimes = Float64[0 for _ in inst.K]
	initialStats = StatsSolution()

	return Solution(
		initialVehicleRoutes,
		initialMachineTravels,
		initialCompletionTimes,
		false,
		0.0,
		initialStats)
end # function initSolution()

function flatChronollogically(
	possibleMachineTravels::Vector{Vector{PossibleMachineTravel}},
)::Vector{PossibleMachineTravel}
	machineTravels = collect(Iterators.flatten(possibleMachineTravels))
	sort!(machineTravels, by = i -> (i.st))

	return machineTravels
end # function flatChronollogically()
