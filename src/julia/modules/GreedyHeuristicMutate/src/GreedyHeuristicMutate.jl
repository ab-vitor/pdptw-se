module GreedyHeuristicMutate

using Data
using Parameters
using Solutions
using Random

struct PossibleMachineTravel
	found::Bool # used to check if a possible machine travel was found
	deltaT::Float64 # the time between the moment after service time and the next vehicle stop
	h::Int64 # index of the machine used
	hPos::Int64 # index of where this machine travel will be placed in current machine h
	st::Float64 # start time of the machine travel
	orig::Int64 # origin node in V_prime
	dest::Int64 # destiny node in V_prime
end

mutable struct InsertionData
	feasible::Bool # used to check if the object is a feasible insertionData
	cost::Float64 # cost added to current solution value
	pPos::Int64 # position where the pickup node will be placed
	dPos::Int64 # position where the delivery node will be placed
	pJob::Int64 # index of the pickup job in V_prime
	dJob::Int64 # index of the delivert job in V_prime
	k::Int64 # index of which vehicle is used
	machineTravels::Vector{PossibleMachineTravel} # all machine travels added after pPos-1
end

mutable struct CheckInsertionData
	feasible::Bool
	twViol::Bool
	capViol::Bool
	cost::Float64
	loadCost::Float64
	availableVehicle::Bool
end

function findNextActiveMachineTravel(machine::Vector{MachineTravel}, pos::Ref{Int64})
	trv = machine[pos[]]
	while !trv.active
		pos[] += 1
		trv = machine[pos[]]
	end
	return trv
end # function findNextActiveMachineTravel

function analysePossibleMachineTravelFromLastComputedPossibleMachineTravel(
	prevStop::VehicleStop,
	currStop::VehicleStop,
	k::Int64,
	currTime::Float64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possibleMachineTravels::Vector{Vector},
	h::Int64,
	bestPossibleMachineTravel::Ref{PossibleMachineTravel},
	startHPos::Ref{Int64},
)
	lastPossibleMachineTravel = possibleMachineTravels[h][end]
	startHPos[] = lastPossibleMachineTravel.hPos
	trv1 = lastPossibleMachineTravel
	trv2 = findNextActiveMachineTravel(machines[h], startHPos)

	trv1End = trv1.st + inst.O[(inst.f[trv1.orig][h], inst.f[trv1.dest][h], h)]
	hArr = trv1End + inst.O[(inst.f[trv1.dest][h], inst.f[prevStop.node][h], h)]
	kArr = currTime + inst.d_bar[prevStop.node, h, k]
	newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)]
	if startHPos[] == length(machines[h]) || newTrvEnd + inst.O[(inst.f[currStop.node][h], inst.f[trv2.orig][h], h)] <= trv2.st
		deltaT = newTrvEnd - currTime
		deltaT += inst.d_bar[currStop.node, h, k]
		if !bestPossibleMachineTravel[].found || deltaT < bestPossibleMachineTravel[].deltaT
			bestPossibleMachineTravel[] = PossibleMachineTravel(true, deltaT, h, startHPos[], max(hArr, kArr), prevStop.node, currStop.node)
		end
	end
end # function analysePossibleMachineTravelFromLastComputedPossibleMachineTravel()

function getBestVehicleTravelTime(
	prevStop::VehicleStop,
	currStop::VehicleStop,
	k::Int64,
	currTime::Float64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possibleMachineTravels::Vector{Vector},
)
	if prevStop.job.point.z == currStop.job.point.z
		return inst.d[prevStop.node, currStop.node, k]
	end

	bestPossibleMachineTravel = Ref(PossibleMachineTravel(false, 0, 0, 0, 0, 0, 0))
	for h in inst.H_e[prevStop.node][currStop.node]
		startHPos = Ref(1)
		if length(possibleMachineTravels[h]) > 0
			analysePossibleMachineTravelFromLastComputedPossibleMachineTravel(
				prevStop,
				currStop,
				k,
				currTime,
				inst,
				machines,
				possibleMachineTravels,
				h,
				bestPossibleMachineTravel,
				startHPos,
			)
		end
		currHPos = Ref(startHPos[])
		nextHPos = Ref(currHPos[] + 1)
		while nextHPos[] <= length(machines[h])
			trv1 = findNextActiveMachineTravel(machines[h], currHPos)
			nextHPos[] = currHPos[] + 1

			trv2 = findNextActiveMachineTravel(machines[h], nextHPos)

			if currHPos[] == 1
				trv1End = trv1.st
				hArr = trv1End + inst.O[(1, inst.f[prevStop.node][h], h)]
			else
				trv1End = trv1.st + inst.O[(inst.f[trv1.orig][h], inst.f[trv1.dest][h], h)]
				hArr = trv1End + inst.O[(inst.f[trv1.dest][h], inst.f[prevStop.node][h], h)]
			end
			kArr = currTime + inst.d_bar[prevStop.node, h, k]
			newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)]
			if nextHPos[] == length(machines[h]) || newTrvEnd + inst.O[(inst.f[currStop.node][h], inst.f[trv2.orig][h], h)] <= trv2.st
				deltaT = newTrvEnd - currTime
				deltaT += inst.d_bar[currStop.node, h, k]
				if !bestPossibleMachineTravel[].found || deltaT < bestPossibleMachineTravel[].deltaT
					bestPossibleMachineTravel[] =
						PossibleMachineTravel(true, deltaT, h, nextHPos[], max(hArr, kArr), prevStop.node, currStop.node)
				end
			end
			currHPos[] += 1
			nextHPos[] += 1
		end
	end
	if !bestPossibleMachineTravel[].found
		# Shouldn't be executed
		println("Houston, we have a problem")
	end
	push!(possibleMachineTravels[bestPossibleMachineTravel[].h], bestPossibleMachineTravel[])

	return bestPossibleMachineTravel[].deltaT
end # function getBestVehicleTravelTime()

function getVehicleTravelTime(
	prevStop::VehicleStop,
	currStop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machineTravels::Vector{PossibleMachineTravel},
	lastMachTrv::Ref{Int64},
	lastMachTrvForH::Vector{Int64},
)
	if prevStop.job.point.z == currStop.job.point.z
		currStop.mach = 0
		return inst.d[prevStop.node, currStop.node, k]
	end

	machTrv = machineTravels[lastMachTrv[]]
	currStop.mach = machTrv.h
	currStop.machInd = machTrv.hPos + lastMachTrvForH[machTrv.h] - 1
	return machTrv.deltaT

end # function getVehicleTravelTime()

function advanceBestTime(
	time::Float64,
	prevStop::VehicleStop,
	currStop::VehicleStop,
	k::Int64,
	inst::InstanceData,
	machines::Vector{Vector{MachineTravel}},
	possibleMachineTravels::Vector{Vector},
)
	time += inst.s[prevStop.node]
	time += getBestVehicleTravelTime(prevStop, currStop, k, time, inst, machines, possibleMachineTravels)
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
	lastMachTrvForH::Vector{Int64},
)
	time += inst.s[prevStop.node]
	time += getVehicleTravelTime(prevStop, currStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
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

function reactivateMachineTravels(k::Int64, sol::Solution, pPos::Int64)
	for h in 1:length(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if sol.machines[h][i].vehicle == k && sol.machines[h][i].vehicleInd >= pPos
				sol.machines[h][i].active = true
			end
		end
	end
end # function reactivateMachineTravels()

function reactivateNextTravels(k::Int64, sol::Solution, curr::Int64)
	for h in 1:length(sol.machines)
		for i in length(sol.machines[h]):-1:1
			if sol.machines[h][i].vehicle == k && sol.machines[h][i].vehicleInd >= curr
				sol.machines[h][i].active = true
			end
		end
	end
end # function reactivateNextTravels()

function checkInsertion(
	sol::Solution,
	k::Int64,
	pPos::Int64,
	dPos::Int64,
	pJob::Int64,
	dJob::Int64,
	inst::InstanceData,
	possibleMachineTravels::Vector{Vector},
)
	feasible = true
	availableVehicle = true
	cost = 0
	loadCost = 0

	prev = pPos - 1
	curr = pPos
	prevStop = sol.vehicles[k][prev]
	currStop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prevStop.servST
	time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels)
	load = prevStop.load + currStop.job.dem

	if time > currStop.job.lat || load > inst.Q[k]
		feasible = false
		cost += max(0, time - currStop.job.lat)
		availableVehicle = availableVehicle && !(load > maximum(inst.Q))
		loadCost = max(loadCost, (load - inst.Q[k]) * inst.Q[k])
	end

	prevStop = currStop
	if pPos != dPos
		currStop = sol.vehicles[k][curr]
		time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels)
		load += currStop.job.dem
		if time > currStop.job.lat || load > inst.Q[k]
			feasible = false
			cost += max(0, time - currStop.job.lat)
			availableVehicle = availableVehicle && !(load > maximum(inst.Q))
			loadCost = max(loadCost, (load - inst.Q[k]) * inst.Q[k])
		end

		prev += 1
		curr += 1
		while curr < dPos
			prevStop = sol.vehicles[k][prev]
			currStop = sol.vehicles[k][curr]
			time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels)
			load += currStop.job.dem
			if time > currStop.job.lat || load > inst.Q[k]
				feasible = false
				cost += max(0, time - currStop.job.lat)
				availableVehicle = availableVehicle && !(load > maximum(inst.Q))
				loadCost = max(loadCost, (load - inst.Q[k]) * inst.Q[k])
			end
			prev += 1
			curr += 1
		end
		prevStop = sol.vehicles[k][prev]
	end

	currStop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels)
	load += currStop.job.dem
	if time > currStop.job.lat
		feasible = false
		cost += max(0, time - currStop.job.lat)
	end

	prevStop = currStop
	currStop = sol.vehicles[k][curr]
	time = advanceBestTime(time, prevStop, currStop, k, inst, sol.machines, possibleMachineTravels)
	load += currStop.job.dem
	if time > currStop.job.lat
		feasible = false
		cost += max(0, time - currStop.job.lat)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prevStop = sol.vehicles[k][prev]
		currStop = sol.vehicles[k][curr]
		time += inst.s[prevStop.node]
		time += getBestVehicleTravelTime(prevStop, currStop, k, time, inst, sol.machines, possibleMachineTravels)
		# if time <= currStop.job.earl
		#   return true, 0
		# end
		time = max(time, currStop.job.earl)
		if time > currStop.job.lat
			feasible = false
			cost += max(0, time - currStop.job.lat)
		end
		prev += 1
		curr += 1
	end
	if feasible
		return CheckInsertionData(feasible, cost > 0, loadCost > 0, time - sol.vehicles[k][end].servST, 0, availableVehicle)
	end

	return CheckInsertionData(feasible, cost > 0, loadCost > 0, cost, loadCost, availableVehicle)
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
		for i in eachindex(sol.machines[h])[2:end-1]
			machTrv = sol.machines[h][i]
			sol.vehicles[machTrv.vehicle][machTrv.vehicleInd].machInd = i
		end
	end
end # function updateMachinesIndexes

function insertMachineTravel(
	sol::Solution,
	machineTravels::Vector{PossibleMachineTravel},
	lastMachTrv::Ref{Int64},
	lastMachTrvForH::Vector{Int64},
	vehicleInd::Int64,
	k::Int64,
)
	machTrv = machineTravels[lastMachTrv[]]
	insert!(
		sol.machines[machTrv.h],
		machTrv.hPos + lastMachTrvForH[machTrv.h] - 1,
		MachineTravel(k, vehicleInd, machTrv.orig, machTrv.dest, machTrv.st, true),
	)
	lastMachTrv[] += 1
	lastMachTrvForH[machTrv.h] += 1
end # function insertMachineTravel()

function updateSolution(sol::Solution, insData::InsertionData, inst::InstanceData)
	k = insData.k
	pPos = insData.pPos
	dPos = insData.dPos
	pJob = insData.pJob
	dJob = insData.dJob
	machineTravels = insData.machineTravels

	deactivateMachineTravels(k, sol, pPos)

	lastMachTrv = Ref(1)
	lastMachTrvForH = Int64[1 for _ in inst.H]

	prev = pPos - 1
	curr = pPos
	prevStop = sol.vehicles[k][prev]
	pickupStop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prevStop.servST
	time = advanceTime(time, prevStop, pickupStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load = prevStop.load + pickupStop.job.dem

	pickupStop.servST = time
	pickupStop.load = load
	if pickupStop.mach != 0
		insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr, k)
	end

	prevStop = pickupStop
	if pPos != dPos
		currStop = sol.vehicles[k][curr]
		time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
		load += currStop.job.dem

		currStop.servST = time
		currStop.load = load
		if currStop.mach != 0
			insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
		end

		prev += 1
		curr += 1
		while curr < dPos
			prevStop = sol.vehicles[k][prev]
			currStop = sol.vehicles[k][curr]
			time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
			load += currStop.job.dem

			currStop.servST = time
			currStop.load = load
			if currStop.mach != 0
				insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
			end

			prev += 1
			curr += 1
		end
		prevStop = sol.vehicles[k][prev]
	end

	deliveryStop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advanceTime(time, prevStop, deliveryStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load += deliveryStop.job.dem

	deliveryStop.servST = time
	deliveryStop.load = load
	if deliveryStop.mach != 0
		insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
	end

	prevStop = deliveryStop
	currStop = sol.vehicles[k][curr]
	time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load += currStop.job.dem

	currStop.servST = time
	if currStop.mach != 0
		insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 2, k)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prevStop = sol.vehicles[k][prev]
		currStop = sol.vehicles[k][curr]
		time += inst.s[prevStop.node]
		time += getVehicleTravelTime(prevStop, currStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
		# if time <= currStop.job.earl
		#   reactivateNextTravels(k, sol, curr)
		#   break
		# end
		time = max(time, currStop.job.earl)
		currStop.servST = time
		if currStop.mach != 0
			insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 2, k)
		end
		prev += 1
		curr += 1
	end

	insert!(sol.vehicles[k], dPos, deliveryStop)
	insert!(sol.vehicles[k], pPos, pickupStop)
	removeDeactivatedTravels(sol)
	updateMachinesIndexes(sol)

	return sol
end # function updateSolution()

function smallest_greater_capacity(vehicle_types::Vector{Vehicle}, load::Int64)
	idx = searchsortedfirst(vehicle_types, load; lt = (x, y) -> x.cap < y)
	return vehicle_types[idx].cap
end

function updateSolutionWithRelaxation(sol::Solution, rlxData::InsertionData, inst::InstanceData)
	k = rlxData.k
	pPos = rlxData.pPos
	dPos = rlxData.dPos
	pJob = rlxData.pJob
	dJob = rlxData.dJob
	machineTravels = rlxData.machineTravels

	deactivateMachineTravels(k, sol, pPos)

	lastMachTrv = Ref(1)
	lastMachTrvForH = Int64[1 for _ in inst.H]

	prev = pPos - 1
	curr = pPos
	prevStop = sol.vehicles[k][prev]
	pickupStop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prevStop.servST
	time = advanceTime(time, prevStop, pickupStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load = Int64(prevStop.load + pickupStop.job.dem)
	if time > pickupStop.job.lat
		delta = ceil(time) - inst.jobs[inst.refs[pickupStop.node]].lat
		inst.jobs[inst.refs[pickupStop.node]].lat += delta
		inst.jobs[inst.refs[pickupStop.node]].earl += delta
	end
	if load > inst.Q[k]
		new_cap = smallest_greater_capacity(inst.vehicle_types, load)
		inst.vehicles[k].cap = new_cap
		inst.Q[k] = new_cap
	end

	pickupStop.servST = time
	pickupStop.load = load
	if pickupStop.mach != 0
		insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr, k)
	end

	prevStop = pickupStop
	if pPos != dPos
		currStop = sol.vehicles[k][curr]
		time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
		load += currStop.job.dem
		if time > currStop.job.lat
			delta = ceil(time) - inst.jobs[inst.refs[currStop.node]].lat
			inst.jobs[inst.refs[currStop.node]].lat += delta
			inst.jobs[inst.refs[currStop.node]].earl += delta
		end
		if load > inst.Q[k]
			new_cap = smallest_greater_capacity(inst.vehicle_types, load)
			inst.vehicles[k].cap = new_cap
			inst.Q[k] = new_cap
		end

		currStop.servST = time
		currStop.load = load
		if currStop.mach != 0
			insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
		end

		prev += 1
		curr += 1
		while curr < dPos
			prevStop = sol.vehicles[k][prev]
			currStop = sol.vehicles[k][curr]
			time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
			load += currStop.job.dem
			if time > currStop.job.lat
				delta = ceil(time) - inst.jobs[inst.refs[currStop.node]].lat
				inst.jobs[inst.refs[currStop.node]].lat += delta
				inst.jobs[inst.refs[currStop.node]].earl += delta
			end
			if load > inst.Q[k]
				new_cap = smallest_greater_capacity(inst.vehicle_types, load)
				inst.vehicles[k].cap = new_cap
				inst.Q[k] = new_cap
			end

			currStop.servST = time
			currStop.load = load
			if currStop.mach != 0
				insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
			end

			prev += 1
			curr += 1
		end
		prevStop = sol.vehicles[k][prev]
	end

	deliveryStop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advanceTime(time, prevStop, deliveryStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load += deliveryStop.job.dem
	if time > deliveryStop.job.lat
		delta = ceil(time) - inst.jobs[inst.refs[deliveryStop.node]].lat
		inst.jobs[inst.refs[deliveryStop.node]].lat += delta
		inst.jobs[inst.refs[deliveryStop.node]].earl += delta
	end

	deliveryStop.servST = time
	deliveryStop.load = load
	if deliveryStop.mach != 0
		insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 1, k)
	end

	prevStop = deliveryStop
	currStop = sol.vehicles[k][curr]
	time = advanceTime(time, prevStop, currStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
	load += currStop.job.dem
	if time > currStop.job.lat
		delta = ceil(time) - inst.jobs[inst.refs[currStop.node]].lat
		inst.jobs[inst.refs[currStop.node]].lat += delta
		inst.jobs[inst.refs[currStop.node]].earl += delta
	end

	currStop.servST = time
	if currStop.mach != 0
		insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 2, k)
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prevStop = sol.vehicles[k][prev]
		currStop = sol.vehicles[k][curr]
		time += inst.s[prevStop.node]
		time += getVehicleTravelTime(prevStop, currStop, k, inst, machineTravels, lastMachTrv, lastMachTrvForH)
		# if time <= currStop.job.earl
		#   reactivateNextTravels(k, sol, curr)
		#   break
		# end
		time = max(time, currStop.job.earl)
		if time > currStop.job.lat
			delta = ceil(time) - inst.jobs[inst.refs[currStop.node]].lat
			inst.jobs[inst.refs[currStop.node]].lat += delta
			inst.jobs[inst.refs[currStop.node]].earl += delta
		end
		currStop.servST = time
		if currStop.mach != 0
			insertMachineTravel(sol, machineTravels, lastMachTrv, lastMachTrvForH, curr + 2, k)
		end
		prev += 1
		curr += 1
	end

	insert!(sol.vehicles[k], dPos, deliveryStop)
	insert!(sol.vehicles[k], pPos, pickupStop)
	removeDeactivatedTravels(sol)
	updateMachinesIndexes(sol)
	inst.jobs[1].earl = 0

	return sol
end # function updateSolutionWithRelaxation()

function tightestTimeWindows(inst::InstanceData)
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> (inst.jobs[inst.refs[i]].lat - inst.jobs[inst.refs[i]].earl))

	return reqs
end # function tightest_time_windows()

function earliestTimeWindows(inst::InstanceData)
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> inst.jobs[inst.refs[i]].lat)

end # function earliest_time_windows()

function initVehicleRoutes(inst::InstanceData)
	# Start depot -> 1 in inst.Vprime, which is equivalent to 0 in paper
	firstVehicleStop = VehicleStop(1, inst.jobs[inst.refs[1]], 0, 0, 0, 0)
	# End depot -> 2*inst.n+2 in inst.Vprime, which is equivalent to 2*n+1 in paper
	lastVehicleStop = VehicleStop(2 * inst.n + 2, inst.jobs[inst.refs[2*inst.n+2]], 0, 0, 0, 0)

	vehicleRoutes = Vector[VehicleStop[copy(firstVehicleStop), copy(lastVehicleStop)] for _ in inst.K]

	return vehicleRoutes
end # function initVehicleRoutes()

function initMachineTravels(inst::InstanceData)
	# Insert a dummy MachineTravel in each machine travels list with start time at 0 (code simplification)
	dummyMachineTravel = MachineTravel(0, 0, 0, 0, 0.0, true)
	machineRoutes = Vector[MachineTravel[copy(dummyMachineTravel), copy(dummyMachineTravel)] for _ in inst.H]

	return machineRoutes
end # function initMachineTravels()

function getServiceOrder(inst::InstanceData, params::ParameterData)
	if params.greedy_service_order == "tightest_tw"
		return tightestTimeWindows(inst)
	elseif params.greedy_service_order == "earliest_tw"
		return earliestTimeWindows(inst)
	end

	return inst.V_p # just in case
end # function getServiceOrder()

function initSolution(inst::InstanceData)
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
		initialStats,
	)
end # function initSolution()

function flatChronollogically(possibleMachineTravels::Vector{Vector})
	machineTravels = collect(Iterators.flatten(possibleMachineTravels))
	sort!(machineTravels, by = i -> (i.st))

	return machineTravels
end # function flatChronollogically()

function updateBestRelaxData(
	checkInsData::CheckInsertionData,
	bestRelaxData::InsertionData,
	pPos::Int64,
	dPos::Int64,
	pJob::Int64,
	dJob::Int64,
	k::Int64,
	possibleMachineTravels::Vector{Vector},
)
	feasible = checkInsData.feasible
	twViol = checkInsData.twViol
	capViol = checkInsData.capViol
	cost = checkInsData.cost
	loadCost = checkInsData.loadCost
	if twViol && capViol && cost + loadCost < bestRelaxData.cost
		machineTravels = flatChronollogically(possibleMachineTravels)
		bestRelaxData = InsertionData(feasible, cost + loadCost, pPos, dPos, pJob, dJob, k, machineTravels)
	elseif cost > 0 && cost < bestRelaxData.cost
		machineTravels = flatChronollogically(possibleMachineTravels)
		bestRelaxData = InsertionData(feasible, cost, pPos, dPos, pJob, dJob, k, machineTravels)
	elseif loadCost > 0 && loadCost < bestRelaxData.cost
		machineTravels = flatChronollogically(possibleMachineTravels)
		bestRelaxData = InsertionData(feasible, loadCost, pPos, dPos, pJob, dJob, k, machineTravels)
	end
	return bestRelaxData
end # function updateBestRelaxData()

function getInsertionWithLessIncreaseInCompTime(inst::InstanceData, sol::Solution, pJob::Int64, dJob::Int64)
	bestInsData = InsertionData(false, 0, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	bestRelaxData = InsertionData(false, Inf64, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	for k in inst.K
		for pPos in 2:length(sol.vehicles[k])
			for dPos in pPos:length(sol.vehicles[k])
				possibleMachineTravels = Vector[PossibleMachineTravel[] for _ in inst.H]
				deactivateMachineTravels(k, sol, pPos)
				checkInsData = checkInsertion(sol, k, pPos, dPos, pJob, dJob, inst, possibleMachineTravels)
				reactivateMachineTravels(k, sol, pPos)
				if !checkInsData.feasible && checkInsData.availableVehicle
					bestRelaxData = updateBestRelaxData(checkInsData, bestRelaxData, pPos, dPos, pJob, dJob, k, possibleMachineTravels)
					continue
				elseif !checkInsData.availableVehicle
					continue
				end

				if !bestInsData.feasible || checkInsData.cost < bestInsData.cost
					machineTravels = flatChronollogically(possibleMachineTravels)
					bestInsData = InsertionData(true, checkInsData.cost, pPos, dPos, pJob, dJob, k, machineTravels)
				end
			end
		end
	end
	return bestInsData, bestRelaxData
end # function getInsertionWithLessIncreaseInCompTime()

function removeDummyObjects!(sol::Solution, inst::InstanceData)
	for h in inst.H
		popfirst!(sol.machines[h])
		pop!(sol.machines[h])
	end

	for k in inst.K
		for i in 1:length(sol.vehicles[k])
			if sol.vehicles[k][i].mach != 0
				sol.vehicles[k][i].machInd -= 1
			end
		end
	end
end # function removeDummyObjects!()

function greedyHeuristicMutate(inst::InstanceData, params::ParameterData)
	sol = initSolution(inst)
	nonServicedReqs = copy(getServiceOrder(inst, params))
	idxReqToServe = 1
	failedRedos = 0
	lastIdxReqToServeFailed = 0
	appliedRelaxation = false
	while idxReqToServe <= length(nonServicedReqs) && failedRedos <= inst.n
		pJob = nonServicedReqs[idxReqToServe]
		dJob = pJob + inst.n

		bestInsData, bestRelaxData = getInsertionWithLessIncreaseInCompTime(inst, sol, pJob, dJob)

		if bestInsData.feasible
			sol = updateSolution(sol, bestInsData, inst)
			idxReqToServe += 1
		elseif params.make_instance_feasible
			appliedRelaxation = true
			sol = updateSolutionWithRelaxation(sol, bestRelaxData, inst)
			idxReqToServe += 1
		else
			lastIdxReqToServeFailed = idxReqToServe
			sol = initSolution(inst)
			failedReq = nonServicedReqs[idxReqToServe]
			popat!(nonServicedReqs, idxReqToServe)
			pushfirst!(nonServicedReqs, failedReq)
			idxReqToServe = 1
			failedRedos += 1
		end
	end

	removeDummyObjects!(sol, inst)

	sol.completionTimes = Float64[rt[length(rt)].servST for rt in sol.vehicles]
	sol.value = sum(sol.completionTimes)
	printDetailMeloFormulationSolution(inst, sol)
	println(inst.name, ": ", sol.value)
	if validateSolution(inst, sol, params)
		sol.feasible = true
		println("Everything is awesome!")
		if params.make_instance_feasible && params.methodCode == "greedy"
			if appliedRelaxation
				println("Updating instance...")
			end
			instanceDataToCsvFiles(inst, params, "g")
		end
	else
		sol.feasible = false
		println("Infeasible solution :(")
	end
	return sol

end # function greedyHeuristicMutate()

end # module GreedyHeuristicMutate
