function printStopDetail(stop::VehicleStop)::Nothing
	println("\tid: ", stop.job.id)
	println("\t\tnode: ", stop.node)
	println("\t\t(x, y, z): ", (stop.job.point.x, stop.job.point.y, stop.job.point.z))
	println("\t\tdem: ", stop.job.dem)
	println("\t\tearl: ", stop.job.earl)
	println("\t\tlat: ", stop.job.lat)
	println("\t\tservt: ", stop.job.servt)
	println("\t\tpid: ", stop.job.pid)
	println("\t\tdid: ", stop.job.did)
	println("\t\tserv_start_time: ", stop.serv_start_time)
	println("\t\t(h, h_ind): ", (stop.mach - 1, stop.mach_index))
	println("\t\tload: ", stop.load)
	println()
	return nothing
end # function printTaskDetail()

function printVehicleDetail(inst::InstanceData, sol::Solution, k)::Nothing
	vehicle = sol.vehicles[k]
	zk = vehicle[1].job.point.z
	printStopDetail(vehicle[1])
	timer = vehicle[1].serv_start_time
	for i in eachindex(vehicle)[2:end]
		timer += vehicle[i-1].job.servt
		println("\tFinished service at time: ", timer)
		println()
		if zk != vehicle[i].job.point.z
			h = vehicle[i].mach
			println("\tUsing Machine: ", inst.machines[h].id)
			println(
				"\t\tTask ",
				vehicle[i-1].job.id,
				" -> Machine ",
				inst.machines[h].id,
				" (Station ",
				inst.f[vehicle[i-1].node][h],
				"): ",
				inst.d_bar[vehicle[i-1].node, h, k],
			)
			timer += inst.d_bar[vehicle[i-1].node, h, k]
			println("\t\tVehicle arrival at machine station: ", timer)
			println("\t\tWaiting time until machine travel: ", round(sol.machines[h][vehicle[i].mach_index].st - timer, digits = 2))
			println()
			timer = sol.machines[h][vehicle[i].mach_index].st
			println("\t\tMachine travel start time: ", timer)
			println(
				"\t\tRegion ",
				zk,
				" -> Region ",
				vehicle[i].job.point.z,
				": ",
				inst.O[(inst.f[vehicle[i-1].node][h], inst.f[vehicle[i].node][h], h)],
			)
			timer += inst.O[(inst.f[vehicle[i-1].node][h], inst.f[vehicle[i].node][h], h)]
			println("\t\tMachine arrival at machine station: ", timer)
			println()
			println(
				"\t\tMachine ",
				inst.machines[h].id,
				" (Station ",
				inst.f[vehicle[i].node][h],
				")-> Task ",
				vehicle[i].job.id,
				": ",
				inst.d_bar[vehicle[i].node, h, k],
			)
			timer += inst.d_bar[vehicle[i].node, h, k]
			println("\t\tVehicle arrival at task: ", timer)
			println("\t\tWaiting time until service start time: ", round(vehicle[i].serv_start_time - timer, digits = 2))
			println()
			printStopDetail(vehicle[i])
		else
			println("\tTask ", vehicle[i-1].job.id, " -> Task ", vehicle[i].job.id, ": ", inst.d[vehicle[i-1].node, vehicle[i].node, k])
			timer += inst.d[vehicle[i-1].node, vehicle[i].node, k]
			println("\tVehicle arrival at task: ", timer)
			println("\tWaiting time until service start time: ", round(vehicle[i].serv_start_time - timer, digits = 2))
			println()
			printStopDetail(vehicle[i])
		end
		timer = vehicle[i].serv_start_time
		zk = vehicle[i].job.point.z
	end
	return nothing
end # function printVehicleDetail()

function printTravelDetail(inst::InstanceData, travel::MachineTravel, h::Int64)::Nothing
	println("\tvehicle: ", travel.vehicle - 1)
	println("\tvehicle_index: ", travel.vehicle_index)
	println("\t(orig, dest): ", (inst.jobs[inst.refs[travel.orig]].id, inst.jobs[inst.refs[travel.dest]].id))
	println("\t(origRegion, destRegion): ", (inst.jobs[inst.refs[travel.orig]].point.z, inst.jobs[inst.refs[travel.dest]].point.z))
	println("\tst: ", travel.st)
	println("\tduration: ", inst.O[(inst.f[travel.orig][h], inst.f[travel.dest][h], h)])
	return nothing
end # function 

function printMachineDetail(inst::InstanceData, machine::Vector{MachineTravel}, h::Int64)::Nothing
	previous_f = 1
	for travel in machine
		println("\tsetup duration: ", inst.O[(previous_f, inst.f[travel.orig][h], h)])
		previous_f = inst.f[travel.dest][h]
		println()

		printTravelDetail(inst, travel, h)
		println()
	end
	return nothing
end # function printMachineDetail()

function print_timeline_solution(inst::InstanceData, sol::Solution)::Nothing
	println("---------------------| VEHICLES |---------------------\n")
	for k in inst.K
		if length(sol.vehicles[k]) > 2
			println("Vehicle ", inst.vehicles[k].id, " :")
			printVehicleDetail(inst, sol, k)
			println()
		end
	end
	println("---------------------| MACHINES |---------------------\n")
	for h in inst.H
		if length(sol.machines[h]) > 0
			println("Machine ", inst.machines[h].id, " :")
			printMachineDetail(inst, sol.machines[h], h)
			println()
		end
	end
	println("-------------------| COMPL. TIMES |-------------------\n")
	for k in inst.K
		println("Vehicle ", inst.vehicles[k].id, " : ", sol.completion_times[k])
	end

	println("-------------------| STATISTICS |-------------------\n")
	println(sol.stats)

	println("----------------------------------------------------\n")

	println("TOTAL: ", sum(sol.completion_times))
	println()
	return nothing
end # function print_timeline_solution()