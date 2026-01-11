module GreedyHeuristicEjectionChain

using Data
using Parameters
using Solutions
using Random

mutable struct DelayVehicle
	node::Int64
	pos::Int64
	delay::Float64
	newArrT::Float64
end

mutable struct DelayMachine
	orig::Int64
	dest::Int64
	pos::Int64
	delay::Float64
	newSt::Float64
end

mutable struct DelayEffects
	found::Bool # if the inserted machine travel pushed foward next machine travel
	delay::Float64 # delay time
	vehicles::Vector{Dict{Int64, DelayVehicle}} # new arrival times for each vehicle stop if exists
	machines::Vector{Dict{Tuple{Int64, Int64}, DelayMachine}} # new start times for each machine travel if exists
end

mutable struct PossibleMachineTravel
	found::Bool # used to check if a possible machine travel was found
	deltaT::Float64 # the time between the moment after service time and the next vehicle stop
	h::Int64 # index of the machine used
	hPos::Int64 # index of where this machine travel will be placed in current machine h
	st::Float64 # start time of the machine travel
	orig::Int64 # origin node in V_prime
	dest::Int64 # destiny node in V_prime
	delayEffects::DelayEffects # if this machine travel delayed next machine travel, the delay effects are registered here
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

function dummyDelayEffects()
	return DelayEffects(false, 0, [], [])
end # function dummyDelayEffects()

function checkDelayFeasibility(h::Int64, delay::Float64, mtrv::MachineTravel, inst::InstanceData, sol::Solution, delayEffects::DelayEffects)
	k = mtrv.vehicle
	curr = copy(mtrv.vehicleInd)
	prevStop = sol.vehicles[k][curr-1]
	currStop = sol.vehicles[k][curr]
	time = mtrv.st + delay

	delayEffects.machines[h][(prevStop.node, currStop.node)] = DelayMachine(prevStop.node, currStop.node, currStop.machInd, delay, time)
	time += inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)] + inst.d_bar[currStop.node, h, k]
	if time <= currStop.job.earl
		return true
	end

	if time > currStop.job.lat
		return false
	end

	newDelay = time - currStop.servST
	delayEffects.vehicles[k][currStop.node] = DelayVehicle(currStop.node, curr, newDelay, time)
	prev = copy(curr)
	curr += 1
	while curr <= length(sol.vehicles[k])
		prevStop = sol.vehicles[k][prev]
		currStop = sol.vehicles[k][curr]
		time += inst.s[prevStop.node]
		if prevStop.job.point.z == currStop.job.point.z
			time += inst.d[prevStop.node, currStop.node, k]
		else
			machTrv = sol.machines[currStop.mach][currStop.machInd]
			time += inst.d_bar[prevStop.node, currStop.mach, k]

			if time <= machTrv.st
				return true
			end
			newDelay = time - machTrv.st
			if !checkDelayFeasibility(currStop.mach, newDelay, machTrv, inst, sol, delayEffects)
				return false
			end
			time += inst.O[(inst.f[machTrv.orig][currStop.mach], inst.f[machTrv.dest][currStop.mach], currStop.mach)]
			time += inst.d_bar[currStop.node, currStop.mach, k]
		end

		if time <= currStop.job.earl || time <= currStop.servST
			return true
		end

		if time > currStop.job.lat
			return false
		end

		newDelay = time - currStop.servST
		delayEffects.vehicles[k][currStop.node] = DelayVehicle(currStop.node, curr, newDelay, time)

		prev += 1
		curr += 1
	end

	return true
end # function checkDelayFeasibility()

function findNextActiveMachineTravel(machine::Vector{MachineTravel}, pos::Ref{Int64})
	trv = machine[pos[]]
	while !trv.active
		pos[] += 1
		trv = machine[pos[]]
	end
	return trv
end # function findNextActiveMachineTravel()

function searchDelayMTrv(possibleMachineTravels::Vector{Vector}, orig::Int64, dest::Int64, hmtrv::Int64)
	for h in eachindex(possibleMachineTravels)
		if length(possibleMachineTravels[h]) > 0
			for possibleMachineTravel in possibleMachineTravels[h]
				if possibleMachineTravel.delayEffects.found && haskey(possibleMachineTravel.delayEffects.machines[hmtrv], (orig, dest))
					return possibleMachineTravel.delayEffects.machines[hmtrv][(orig, dest)].delay
				end
			end
		end
	end
	return 0.0
end # function searchDelayMTrv()

function tryInsertionWithDelay(
	currTime::Float64,
	newTrvEnd::Float64,
	newTrvSt::Float64,
	newTrvPos::Int64,
	h::Int64,
	k::Int64,
	prevStop::VehicleStop,
	currStop::VehicleStop,
	trv2::MachineTravel,
	delayTrv2::Float64,
	inst::InstanceData,
	sol::Solution,
	currHPosSt::Int64,
	nextHPosSt::Int64,
	possibleMachineTravels::Vector{Vector},
	bestPossibleMachineTravel::Ref{PossibleMachineTravel},
)
	time = newTrvEnd + inst.O[(inst.f[currStop.node][h], inst.f[trv2.orig][h], h)]
	delay = time - (trv2.st + delayTrv2)
	delayEffects = DelayEffects(true, delay, [Dict{Int64, DelayVehicle}() for _ in inst.K], [Dict{Tuple{Int64, Int64}, DelayMachine}() for _ in inst.H])
	if checkDelayFeasibility(h, delay, trv2, inst, sol, delayEffects)
		currHPos = Ref(currHPosSt)
		nextHPos = Ref(nextHPosSt)
		while nextHPos[] < length(sol.machines[h]) && delay > 0
			mtrv1 = findNextActiveMachineTravel(sol.machines[h], currHPos)
			nextHPos[] = currHPos[] + 1
			mtrv2 = findNextActiveMachineTravel(sol.machines[h], nextHPos)
			if nextHPos[] == length(sol.machines[h])
				return
			end
			time += inst.O[(inst.f[mtrv1.orig][h], inst.f[mtrv1.dest][h], h)] # machine travel
			time += inst.O[(inst.f[mtrv1.dest][h], inst.f[mtrv2.orig][h], h)] # setup travel

			delayMTrv2 = searchDelayMTrv(possibleMachineTravels, mtrv2.orig, mtrv2.dest, h)
			if time <= mtrv2.st + delayMTrv2
				deltaT = newTrvEnd - currTime
				deltaT += inst.d_bar[currStop.node, h, k]
				if !bestPossibleMachineTravel[].found || deltaT < bestPossibleMachineTravel[].deltaT
					bestPossibleMachineTravel[] = PossibleMachineTravel(true, deltaT, h, newTrvPos, newTrvSt, prevStop.node, currStop.node, delayEffects)
					break
				end
			else
				delay = time - (mtrv2.st + delayMTrv2)
				if !checkDelayFeasibility(h, delay, mtrv2, inst, sol, delayEffects)
					break
				end
			end
			currHPos[] += 1
			nextHPos[] += 1
		end
	end
end # function tryInsertionWithDelay()

function analysePossibleMachineTravelFromLastComputedPossibleMachineTravel(
	prevStop::VehicleStop,
	currStop::VehicleStop,
	k::Int64,
	currTime::Float64,
	inst::InstanceData,
	sol::Solution,
	possibleMachineTravels::Vector{Vector},
	h::Int64,
	bestPossibleMachineTravel::Ref{PossibleMachineTravel},
	startHPos::Ref{Int64},
)
	lastPossibleMachineTravel = possibleMachineTravels[h][end]
	startHPos[] = lastPossibleMachineTravel.hPos
	trv1 = lastPossibleMachineTravel
	trv2 = findNextActiveMachineTravel(sol.machines[h], startHPos)

	delayTrv1 = searchDelayMTrv(possibleMachineTravels, trv1.orig, trv1.dest, h)
	delayTrv2 = searchDelayMTrv(possibleMachineTravels, trv2.orig, trv2.dest, h)

	trv1End = trv1.st + delayTrv1 + inst.O[(inst.f[trv1.orig][h], inst.f[trv1.dest][h], h)]
	hArr = trv1End + inst.O[(inst.f[trv1.dest][h], inst.f[prevStop.node][h], h)]
	kArr = currTime + inst.d_bar[prevStop.node, h, k]
	newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)]
	if startHPos[] == length(sol.machines[h]) || newTrvEnd + inst.O[(inst.f[currStop.node][h], inst.f[trv2.orig][h], h)] <= trv2.st + delayTrv2
		deltaT = newTrvEnd - currTime
		deltaT += inst.d_bar[currStop.node, h, k]
		if !bestPossibleMachineTravel[].found || deltaT < bestPossibleMachineTravel[].deltaT
			bestPossibleMachineTravel[] = PossibleMachineTravel(true, deltaT, h, startHPos[], max(hArr, kArr), prevStop.node, currStop.node, dummyDelayEffects())
		end
	else
		tryInsertionWithDelay(currTime, newTrvEnd, max(hArr, kArr), startHPos[], h, k, prevStop, currStop, trv2, delayTrv2, inst, sol, startHPos[], startHPos[] + 1, possibleMachineTravels, bestPossibleMachineTravel)
	end
end # function analysePossibleMachineTravelFromLastComputedPossibleMachineTravel()

function getBestVehicleTravelTime(prevStop::VehicleStop, currStop::VehicleStop, k::Int64, currTime::Float64, inst::InstanceData, sol::Solution, possibleMachineTravels::Vector{Vector})
	if prevStop.job.point.z == currStop.job.point.z
		return inst.d[prevStop.node, currStop.node, k]
	end

	bestPossibleMachineTravel = Ref(PossibleMachineTravel(false, 0, 0, 0, 0, 0, 0, dummyDelayEffects()))
	for h in inst.H_e[prevStop.node][currStop.node]
		startHPos = Ref(1)
		if length(possibleMachineTravels[h]) > 0
			analysePossibleMachineTravelFromLastComputedPossibleMachineTravel(prevStop, currStop, k, currTime, inst, sol, possibleMachineTravels, h, bestPossibleMachineTravel, startHPos)
		end
		currHPos = Ref(startHPos[])
		nextHPos = Ref(currHPos[] + 1)
		while nextHPos[] <= length(sol.machines[h])
			trv1 = findNextActiveMachineTravel(sol.machines[h], currHPos)
			nextHPos[] = currHPos[] + 1

			trv2 = findNextActiveMachineTravel(sol.machines[h], nextHPos)

			delayTrv1 = searchDelayMTrv(possibleMachineTravels, trv1.orig, trv1.dest, h)
			delayTrv2 = searchDelayMTrv(possibleMachineTravels, trv2.orig, trv2.dest, h)

			if currHPos[] == 1
				trv1End = trv1.st + delayTrv1
				hArr = trv1End + inst.O[(1, inst.f[prevStop.node][h], h)]
			else
				trv1End = trv1.st + delayTrv1 + inst.O[(inst.f[trv1.orig][h], inst.f[trv1.dest][h], h)]
				hArr = trv1End + inst.O[(inst.f[trv1.dest][h], inst.f[prevStop.node][h], h)]
			end
			kArr = currTime + inst.d_bar[prevStop.node, h, k]
			newTrvEnd = max(hArr, kArr) + inst.O[(inst.f[prevStop.node][h], inst.f[currStop.node][h], h)]
			if nextHPos[] == length(sol.machines[h]) || newTrvEnd + inst.O[(inst.f[currStop.node][h], inst.f[trv2.orig][h], h)] <= trv2.st + delayTrv2
				deltaT = newTrvEnd - currTime
				deltaT += inst.d_bar[currStop.node, h, k]
				if !bestPossibleMachineTravel[].found || deltaT < bestPossibleMachineTravel[].deltaT
					bestPossibleMachineTravel[] = PossibleMachineTravel(true, deltaT, h, nextHPos[], max(hArr, kArr), prevStop.node, currStop.node, dummyDelayEffects())
				end
			else
				tryInsertionWithDelay(currTime, newTrvEnd, max(hArr, kArr), nextHPos[], h, k, prevStop, currStop, trv2, delayTrv2, inst, sol, currHPos[] + 1, nextHPos[] + 1, possibleMachineTravels, bestPossibleMachineTravel)
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

function getVehicleTravelTime(prevStop::VehicleStop, currStop::VehicleStop, k::Int64, inst::InstanceData, machineTravels::Vector{PossibleMachineTravel}, lastMachTrv::Ref{Int64}, lastMachTrvForH::Vector{Int64})
	if prevStop.job.point.z == currStop.job.point.z
		currStop.mach = 0
		return inst.d[prevStop.node, currStop.node, k]
	end

	machTrv = machineTravels[lastMachTrv[]]
	currStop.mach = machTrv.h
	currStop.machInd = machTrv.hPos + lastMachTrvForH[machTrv.h] - 1
	return machTrv.deltaT

end # function getVehicleTravelTime()

function advanceBestTime(time::Float64, prevStop::VehicleStop, currStop::VehicleStop, k::Int64, inst::InstanceData, sol::Solution, possibleMachineTravels::Vector{Vector})
	time += inst.s[prevStop.node]
	time += getBestVehicleTravelTime(prevStop, currStop, k, time, inst, sol, possibleMachineTravels)
	time = max(time, currStop.job.earl)
	return time
end # function advanceBestTime()

function advanceTime(time::Float64, prevStop::VehicleStop, currStop::VehicleStop, k::Int64, inst::InstanceData, machineTravels::Vector{PossibleMachineTravel}, lastMachTrv::Ref{Int64}, lastMachTrvForH::Vector{Int64})
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

function checkInsertion(sol::Solution, k::Int64, pPos::Int64, dPos::Int64, pJob::Int64, dJob::Int64, inst::InstanceData, possibleMachineTravels::Vector{Vector})
	prev = pPos - 1
	curr = pPos
	prevStop = sol.vehicles[k][prev]
	currStop = VehicleStop(pJob, inst.jobs[inst.refs[pJob]], 0, 0, 0, 0)

	time = prevStop.servST
	time = advanceBestTime(time, prevStop, currStop, k, inst, sol, possibleMachineTravels)
	load = prevStop.load + currStop.job.dem

	if time > currStop.job.lat || load > inst.Q[k]
		return false, 0
	end

	prevStop = currStop
	if pPos != dPos
		currStop = sol.vehicles[k][curr]
		time = advanceBestTime(time, prevStop, currStop, k, inst, sol, possibleMachineTravels)
		load += currStop.job.dem
		if time > currStop.job.lat || load > inst.Q[k]
			return false, 0
		end

		prev += 1
		curr += 1
		while curr < dPos
			prevStop = sol.vehicles[k][prev]
			currStop = sol.vehicles[k][curr]
			time = advanceBestTime(time, prevStop, currStop, k, inst, sol, possibleMachineTravels)
			load += currStop.job.dem
			if time > currStop.job.lat || load > inst.Q[k]
				return false, 0
			end
			prev += 1
			curr += 1
		end
		prevStop = sol.vehicles[k][prev]
	end

	currStop = VehicleStop(dJob, inst.jobs[inst.refs[dJob]], 0, 0, 0, 0)
	time = advanceBestTime(time, prevStop, currStop, k, inst, sol, possibleMachineTravels)
	load += currStop.job.dem
	if time > currStop.job.lat
		return false, 0
	end

	prevStop = currStop
	currStop = sol.vehicles[k][curr]
	time = advanceBestTime(time, prevStop, currStop, k, inst, sol, possibleMachineTravels)
	load += currStop.job.dem
	if time > currStop.job.lat
		return false, 0
	end

	prev += 1
	curr += 1
	while curr <= length(sol.vehicles[k])
		prevStop = sol.vehicles[k][prev]
		currStop = sol.vehicles[k][curr]
		time += inst.s[prevStop.node]
		time += getBestVehicleTravelTime(prevStop, currStop, k, time, inst, sol, possibleMachineTravels)
		# if time <= currStop.job.earl
		#   return true, 0
		# end
		time = max(time, currStop.job.earl)
		if time > currStop.job.lat
			return false, 0
		end
		prev += 1
		curr += 1
	end

	return true, time - sol.vehicles[k][end].servST

end # function checkInsertion()

function removeDeactivatedTravels(sol::Solution)
	for h in 1:length(sol.machines)
		removed = false
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

function insertMachineTravel(sol::Solution, machineTravels::Vector{PossibleMachineTravel}, lastMachTrv::Ref{Int64}, lastMachTrvForH::Vector{Int64}, vehicleInd::Int64, k::Int64)
	machTrv = machineTravels[lastMachTrv[]]
	insert!(sol.machines[machTrv.h], machTrv.hPos + lastMachTrvForH[machTrv.h] - 1, MachineTravel(k, vehicleInd, machTrv.orig, machTrv.dest, machTrv.st, true))
	lastMachTrv[] += 1
	lastMachTrvForH[machTrv.h] += 1
end # function insertMachineTravel()

function applyDelayEffects(machineTravels::Vector{PossibleMachineTravel}, sol::Solution)
	for mtrv in machineTravels
		if mtrv.delayEffects.found
			delayVehicles = mtrv.delayEffects.vehicles
			for k in eachindex(delayVehicles)
				delayVehicle = delayVehicles[k]
				if length(delayVehicle) > 0
					for (_, delayStop) in delayVehicle
						sol.vehicles[k][delayStop.pos].servST = delayStop.newArrT
					end
				end
			end
			delayMachines = mtrv.delayEffects.machines
			for h in eachindex(delayMachines)
				delayMachine = delayMachines[h]
				if length(delayMachine) > 0
					for (_, delayTravel) in delayMachine
						sol.machines[h][delayTravel.pos].st = delayTravel.newSt
					end
				end
			end
		end
	end
end # function applyDelayEffects

function updateSolution(sol::Solution, insData::InsertionData, inst::InstanceData)
	k = insData.k
	pPos = insData.pPos
	dPos = insData.dPos
	pJob = insData.pJob
	dJob = insData.dJob
	machineTravels = insData.machineTravels
	applyDelayEffects(machineTravels, sol)

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

function tightestTimeWindows(inst::InstanceData)
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> (inst.l[i] - inst.e[i]))

	return reqs
end # function tightest_time_windows()

function earliestTimeWindows(inst::InstanceData)
	reqs = copy(inst.V_p)
	sort!(reqs, by = i -> inst.l[i])

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
	dummyMachineTravel = MachineTravel(0, 0, 0, 0, 0, true)
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
		initialStats)
end # function initSolution()

function flatChronollogically(possibleMachineTravels::Vector{Vector})
	machineTravels = collect(Iterators.flatten(possibleMachineTravels))
	sort!(machineTravels, by = i -> (i.st))

	return machineTravels
end # function flatChronollogically()

function getInsertionWithLessIncreaseInCompTime(inst::InstanceData, sol::Solution, pJob::Int64, dJob::Int64)
	bestInsData = InsertionData(false, 0, 0, 0, 0, 0, 0, PossibleMachineTravel[])
	for k in inst.K
		for pPos in 2:length(sol.vehicles[k])
			for dPos in pPos:length(sol.vehicles[k])
				possibleMachineTravels = Vector[PossibleMachineTravel[] for _ in inst.H]
				deactivateMachineTravels(k, sol, pPos)
				feasible, cost = checkInsertion(sol, k, pPos, dPos, pJob, dJob, inst, possibleMachineTravels)
				reactivateMachineTravels(k, sol, pPos)
				if !feasible
					continue
				end

				if !bestInsData.feasible || cost < bestInsData.cost
					machineTravels = flatChronollogically(possibleMachineTravels)
					bestInsData = InsertionData(true, cost, pPos, dPos, pJob, dJob, k, machineTravels)
				end
			end
		end
	end
	return bestInsData
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

function greedyHeuristicEjectionChain(inst::InstanceData, params::ParameterData)
	sol = initSolution(inst)
	nonServicedReqs = copy(getServiceOrder(inst, params))
	idxReqToServe = 1
	failedRedos = 0
	lastIdxReqToServeFailed = 0

	while idxReqToServe <= length(nonServicedReqs) && failedRedos <= inst.n
		pJob = nonServicedReqs[idxReqToServe]
		dJob = pJob + inst.n

		bestInsData = getInsertionWithLessIncreaseInCompTime(inst, sol, pJob, dJob)

		if bestInsData.feasible
			sol = updateSolution(sol, bestInsData, inst)
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
	println(inst.name, ": ", sum(sol.completionTimes))
	if validateSolution(inst, sol, params)
		sol.feasible = true
		println("Everything is awesome!")
		if params.make_instance_feasible
			instanceData_to_csv_files(inst, params)
		end
	end
	return sol

end # function greedyHeuristicEjectionChain()

end # module GreedyHeuristicEjectionChain
