function findActiveMachineTravel(machine::Vector{MachineTravel}, pos::Ref{Int64}, k::Int64, pPos::Int64, i::Int64 = 1)::MachineTravel
	if pos[] > length(machine)
		return MachineTravel(k, pPos)
	end
	trv = machine[pos[]]
	while trv.vehicle == k &&
			  trv.vehicleInd >= pPos &&
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
	pPos::Int64,
	depTime::Float64,
	lbNewTrvEnd::Float64,
	prevStop::VehicleStop,
	currStop::VehicleStop,
	vehicleInd::Int64,
	inst::InstanceData,
)::PossibleMachineTravel
	dummyMtrv = PossibleMachineTravel(false, 0, 0, 0, 0, 0, 0, 0)
	prevActiveMtrvPos = start - 1
	for posToInsert in eachindex(machine)[start:end]
		trv = machine[posToInsert]
		if trv.vehicle != k || trv.vehicleInd < pPos
			if lbNewTrvEnd + inst.O[(inst.f[currStop.node][h], inst.f[trv.orig][h], h)] <= trv.st
				if prevActiveMtrvPos == 0
					initStationDepTime = inst.e[inst.depot_begin]
					hArr = initStationDepTime + inst.O[(inst.initial_station, inst.f[prevStop.node][h], h)]
				else
					prevActTrv = machine[prevActiveMtrvPos]
					prevActTrvEnd = prevActTrv.st + inst.O[(inst.f[prevActTrv.orig][h], inst.f[prevActTrv.dest][h], h)]
					hArr = prevActTrvEnd + inst.O[(inst.f[prevActTrv.dest][h], inst.f[prevStop.node][h], h)]
				end
				kArr = depTime + inst.d_bar[prevStop.node, h, k]
				newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)]
				kArrAtCurrNode = newTrvEnd + inst.d_bar[currStop.node, h, k]
				if kArrAtCurrNode > currStop.job.lat
					return dummyMtrv
				elseif newTrvEnd + inst.O[(inst.f[currStop.node][h], inst.f[trv.orig][h], h)] <= trv.st
					deltaT = kArrAtCurrNode - depTime
					return PossibleMachineTravel(true, deltaT, h, posToInsert, max(hArr, kArr), prevStop.node, currStop.node, vehicleInd)
				end
			end
			prevActiveMtrvPos = posToInsert
		end
	end

	if prevActiveMtrvPos == 0
		posToInsert = 1
		initStationDepTime = inst.e[inst.depot_begin]
		hArr = initStationDepTime + inst.O[(inst.initial_station, inst.f[prevStop.node][h], h)]
		kArr = depTime + inst.d_bar[prevStop.node, h, k]
		newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)]
		kArrAtCurrNode = newTrvEnd + inst.d_bar[currStop.node, h, k]
		if kArrAtCurrNode > currStop.job.lat
			return dummyMtrv
		else
			deltaT = kArrAtCurrNode - depTime
			return PossibleMachineTravel(true, deltaT, h, posToInsert, max(hArr, kArr), prevStop.node, currStop.node, vehicleInd)
		end
	end

	posToInsert = length(machine) + 1
	prevActTrv = machine[prevActiveMtrvPos]
	prevActTrvEnd = prevActTrv.st + inst.O[(inst.f[prevActTrv.orig][h], inst.f[prevActTrv.dest][h], h)]
	hArr = prevActTrvEnd + inst.O[(inst.f[prevActTrv.dest][h], inst.f[prevStop.node][h], h)]
	kArr = depTime + inst.d_bar[prevStop.node, h, k]
	newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)]
	kArrAtCurrNode = newTrvEnd + inst.d_bar[currStop.node, h, k]
	if kArrAtCurrNode > currStop.job.lat
		return dummyMtrv
	end

	deltaT = kArrAtCurrNode - depTime
	return PossibleMachineTravel(true, deltaT, h, posToInsert, max(hArr, kArr), prevStop.node, currStop.node, vehicleInd)
end # function findFeasMtrvToInsertInMachine()

function analysePossibleMachineTravelFromLastComputedPossibleMachineTravel(
	prevStop::VehicleStop,
	currStop::VehicleStop,
	k::Int64,
	currTime::Float64,
	inst::InstanceData,
	machine::Vector{MachineTravel},
	possibleMachineTravels::Vector{Vector},
	h::Int64,
	bestPossibleMachineTravel::Ref{PossibleMachineTravel},
	startHPos::Ref{Int64},
	vehicleInd::Int64,
	pPos::Int64,
)::Bool
	lastPMtrv = possibleMachineTravels[h][end]
	startHPos[] = lastPMtrv.hPos
	lastPMtrvEnd = lastPMtrv.st + inst.O[(inst.f[lastPMtrv.orig][h], inst.f[lastPMtrv.dest][h], h)]
	hArr = lastPMtrvEnd + inst.O[(inst.f[lastPMtrv.dest][h], inst.f[prevStop.node][h], h)]
	kArr = currTime + inst.d_bar[prevStop.node, h, k]
	newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)]
	kArrAtCurrNode = newTrvEnd + inst.d_bar[currStop.node, h, k]
	if kArrAtCurrNode > currStop.job.lat
		return true
	end
	nextTrv = findActiveMachineTravel(machine, startHPos, k, pPos)
	if !(nextTrv.vehicle == k && nextTrv.vehicleInd >= pPos)
		if newTrvEnd + inst.O[(inst.f[currStop.node][h], inst.f[nextTrv.orig][h], h)] <= nextTrv.st
			deltaT = kArrAtCurrNode - currTime
			if deltaT < bestPossibleMachineTravel[].deltaT
				bestPossibleMachineTravel[] =
					PossibleMachineTravel(true, deltaT, h, startHPos[], max(hArr, kArr), prevStop.node, currStop.node, vehicleInd)
			end
			return true
		end
		return false
	else
		deltaT = kArrAtCurrNode - currTime
		if deltaT < bestPossibleMachineTravel[].deltaT
			bestPossibleMachineTravel[] =
				PossibleMachineTravel(true, deltaT, h, startHPos[], max(hArr, kArr), prevStop.node, currStop.node, vehicleInd)
		end
		return true
	end

end # function analysePossibleMachineTravelFromLastComputedPossibleMachineTravel()

function getBestMachineTravelTime(
	prevStop::VehicleStop,
	currStop::VehicleStop,
	k::Int64,
	depTime::Float64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possibleMachineTravels::Vector{Vector},
	vehicleInd::Int64,
	pPos::Int64,
)::Float64
	bestPossibleMachineTravel = Ref(PossibleMachineTravel(false, Inf64, 0, 0, 0, 0, 0, 0))
	for h in inst.H_e[prevStop.node][currStop.node]
		lbNewTrvEnd = depTime + inst.d_bar[prevStop.node, h, k] + inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)]
		if lbNewTrvEnd + inst.d_bar[currStop.node, h, k] > currStop.job.lat
			continue
		end

		startHPos = Ref(1)
		if length(possibleMachineTravels[h]) > 0 &&
		   analysePossibleMachineTravelFromLastComputedPossibleMachineTravel(
			prevStop,
			currStop,
			k,
			depTime,
			inst,
			machines[h],
			possibleMachineTravels,
			h,
			bestPossibleMachineTravel,
			startHPos,
			vehicleInd,
			pPos,
		)
			continue
		end

		mtrv = findFeasMtrvToInsertInMachine(
			machines[h], h, startHPos[],
			k, pPos, depTime, lbNewTrvEnd,
			prevStop, currStop, vehicleInd, inst,
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
	prevStop::VehicleStop,
	currStop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possibleMachineTravels::Vector{Vector},
	vehicleInd::Int64,
	pPos::Int64,
)::Float64
	time += inst.s[prevStop.node]
	if prevStop.job.point.z == currStop.job.point.z
		time += inst.d[prevStop.node, currStop.node, k]
	else
		time += getBestMachineTravelTime(prevStop, currStop, k, time, inst, machines, possibleMachineTravels, vehicleInd, pPos)
	end
	time = max(time, currStop.job.earl)
	return time
end # function advanceBestTime()

function advanceTime(
	time::Float64,
	prevStop::VehicleStop,
	currStop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machineTravels::Vector{PossibleMachineTravel},
	lastMachTrv::Ref{Int64},
)::Float64
	time += inst.s[prevStop.node]
	if prevStop.job.point.z == currStop.job.point.z
		currStop.mach = 0
		time += inst.d[prevStop.node, currStop.node, k]
	else
		machTrv = machineTravels[lastMachTrv[]]
		currStop.mach = machTrv.h
		lastMachTrv[] += 1
		time += machTrv.deltaT
	end
	time = max(time, currStop.job.earl)
	return time
end # function advanceTime()

function deactivateMachineTravels(k::Int64, sol::Solution, pPos::Int64)
	for h in 1:length(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if sol.machines[h][i].vehicle == k && sol.machines[h][i].vehicleInd >= pPos
				sol.machines[h][i].active = false
			end
		end
	end
end # function deactivateMachineTravels()

function checkInsertion(
	sol::Solution,
	k::Int64,
	pPos::Int64,
	dPos::Int64,
	pJob::Int64,
	dJob::Int64,
	inst::InstanceData,
)::CheckInsertionData

	possibleMachineTravels = Vector[PossibleMachineTravel[] for _ in inst.H]

	prev = pPos - 1
	curr = pPos
	prevStop = sol.vehicles[k][prev]
	currStop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prevStop.servST
	time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels, curr, pPos)
	load = prevStop.load + currStop.job.dem

	if time > currStop.job.lat || load > inst.Q[k]
		return CheckInsertionData(false, 0, possibleMachineTravels)
	end

	prevStop = currStop
	if pPos != dPos
		currStop = sol.vehicles[k][curr]
		time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels, curr + 1, pPos)
		load += currStop.job.dem
		if time > currStop.job.lat || load > inst.Q[k]
			return CheckInsertionData(false, 0, possibleMachineTravels)
		end

		prev += 1
		curr += 1
		while curr < dPos
			prevStop = sol.vehicles[k][prev]
			currStop = sol.vehicles[k][curr]
			time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels, curr + 1, pPos)
			load += currStop.job.dem
			if time > currStop.job.lat || load > inst.Q[k]
				return CheckInsertionData(false, 0, possibleMachineTravels)
			end
			prev += 1
			curr += 1
		end
		prevStop = sol.vehicles[k][prev]
	end

	currStop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels, curr + 1, pPos)
	load += currStop.job.dem
	if time > currStop.job.lat
		return CheckInsertionData(false, 0, possibleMachineTravels)
	end

	prevStop = currStop
	currStop = sol.vehicles[k][curr]
	time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels, curr + 2, pPos)
	load += currStop.job.dem
	if time > currStop.job.lat
		return CheckInsertionData(false, 0, possibleMachineTravels)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prevStop = sol.vehicles[k][prev]
		currStop = sol.vehicles[k][curr]
		# if currStop.job.earl == 411 && pPos == 3 && dPos == 3
		# 	println("stophere")
		# end
		time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels, curr + 2, pPos)
		if time > currStop.job.lat
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
			sol.vehicles[machTrv.vehicle][machTrv.vehicleInd].machInd = i
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
			machTrv.hPos,
			MachineTravel(k, machTrv.vehicleInd, machTrv.orig, machTrv.dest, machTrv.st, active),
		)
	end
end # function insertMachineTravels()

function updateSolution(sol::Solution, insData::InsertionData, inst::InstanceData)::Solution
	k = insData.k
	pPos = insData.pPos
	dPos = insData.dPos
	pJob = insData.pJob
	dJob = insData.dJob
	machineTravels = flatChronollogically(insData.machineTravels)

	deactivateMachineTravels(k, sol, pPos)

	lastMachTrv = Ref(1)

	prev = pPos - 1
	curr = pPos
	prevStop = sol.vehicles[k][prev]
	pickupStop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prevStop.servST
	time = advanceTime(time, prevStop, pickupStop, k, inst, machineTravels, lastMachTrv)
	load = prevStop.load + pickupStop.job.dem

	pickupStop.servST = time
	pickupStop.load = load

	prevStop = pickupStop
	if pPos != dPos
		currStop = sol.vehicles[k][curr]
		time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv)
		load += currStop.job.dem

		currStop.servST = time
		currStop.load = load

		prev += 1
		curr += 1
		while curr < dPos
			prevStop = sol.vehicles[k][prev]
			currStop = sol.vehicles[k][curr]
			time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv)
			load += currStop.job.dem

			currStop.servST = time
			currStop.load = load

			prev += 1
			curr += 1
		end
		prevStop = sol.vehicles[k][prev]
	end

	deliveryStop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advanceTime(time, prevStop, deliveryStop, k, inst, machineTravels, lastMachTrv)
	load += deliveryStop.job.dem

	deliveryStop.servST = time
	deliveryStop.load = load

	prevStop = deliveryStop
	currStop = sol.vehicles[k][curr]
	time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv)
	load += currStop.job.dem

	currStop.servST = time

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prevStop = sol.vehicles[k][prev]
		currStop = sol.vehicles[k][curr]
		time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv)
		currStop.servST = time
		prev += 1
		curr += 1
	end

	insert!(sol.vehicles[k], dPos, deliveryStop)
	insert!(sol.vehicles[k], pPos, pickupStop)
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
