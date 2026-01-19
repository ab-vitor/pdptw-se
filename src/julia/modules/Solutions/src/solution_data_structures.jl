mutable struct VehicleStop
	node::Int64 # node id in inst.Vprime
	job::Job # the job the vehicle is doing
	serv_start_time::Float64 # the arrival time at this job
	mach::Int64 # which machine was used
	mach_index::Int64 # index in machine's travel vector
	load::Float64 # load of the vehicle
end
Base.copy(s::VehicleStop) = VehicleStop(s.node, s.job, s.serv_start_time, s.mach, s.mach_index, s.load)

mutable struct MachineTravel
	vehicle::Int64 # which vehicle is being transported
	vehicle_index::Int64 # index in vehicle's stop vector
	orig::Int64 # node id in inst.Vprime from where the vehicle has come to
	dest::Int64 # node id in inst.Vprime to where the vehicle is going to
	st::Float64 # start time of machine's travel
	active::Bool # if this machine travel should be considered
	function MachineTravel(
		vehicle::Int64 = 0,
		vehicle_index::Int64 = 0,
		orig::Int64 = 0,
		dest::Int64 = 0,
		st::Float64 = 0.0,
		active::Bool = false,
	)
		return new(
			vehicle,
			vehicle_index,
			orig,
			dest,
			st,
			active,
		)
	end
end
Base.copy(s::MachineTravel) = MachineTravel(s.vehicle, s.vehicle_index, s.orig, s.dest, s.st, s.active)

mutable struct SolutionStats
	n_vehicles_used::Float64
	n_machines_used::Float64
	max_max_load_all_vehicles::Float64
	min_max_load_all_vehicles::Float64
	mean_max_load_all_vehicles::Float64
	min_completion_time::Float64
	max_completion_time::Float64
	mean_completion_time::Float64
	machines_travel_times_with_vehicle::Vector{Float64}
	machines_travel_times_no_vehicle::Vector{Float64}
	max_load_vehicle::Vector{Float64}
	avrg_machines_travel_time_with_vehicle::Float64
	avrg_machines_travel_time_only_with_vehicle::Float64
	avrg_machines_travel_time_no_vehicle::Float64
	avrg_vehicles_waiting_time_for_a_machine_travel::Float64
	avrg_vehicles_waiting_time_for_a_service::Float64
	function SolutionStats(
		n_vehicles_used::Float64 = 0.0,
		n_machines_used::Float64 = 0.0,
		max_max_load_all_vehicles::Float64 = 0.0,
		min_max_load_all_vehicles::Float64 = 0.0,
		mean_max_load_all_vehicles::Float64 = 0.0,
		min_completion_time::Float64 = 0.0,
		max_completion_time::Float64 = 0.0,
		mean_completion_time::Float64 = 0.0,
		machines_travel_times_with_vehicle::Vector{Float64} = Float64[],
		machines_travel_times_no_vehicle::Vector{Float64} = Float64[],
		max_load_vehicle::Vector{Float64} = Float64[],
		avrg_machines_travel_time_with_vehicle::Float64 = 0.0,
		avrg_machines_travel_time_only_with_vehicle::Float64 = 0.0,
		avrg_machines_travel_time_no_vehicle::Float64 = 0.0,
		avrg_vehicles_waiting_time_for_a_machine_travel::Float64 = 0.0,
		avrg_vehicles_waiting_time_for_a_service::Float64 = 0.0)
		return new(n_vehicles_used,
			n_machines_used,
			max_max_load_all_vehicles,
			min_max_load_all_vehicles,
			mean_max_load_all_vehicles,
			min_completion_time,
			max_completion_time,
			mean_completion_time,
			machines_travel_times_with_vehicle,
			machines_travel_times_no_vehicle,
			max_load_vehicle,
			avrg_machines_travel_time_with_vehicle,
			avrg_machines_travel_time_only_with_vehicle,
			avrg_machines_travel_time_no_vehicle,
			avrg_vehicles_waiting_time_for_a_machine_travel,
			avrg_vehicles_waiting_time_for_a_service)
	end
end

import Base: show

function show(io::IO, s::SolutionStats)
    scalars = [
        "Vehicles used"                          => s.n_vehicles_used,
        "Machines used"                          => s.n_machines_used,
        "Max load (vehicles)"                    => s.max_max_load_all_vehicles,
        "Min load (vehicles)"                    => s.min_max_load_all_vehicles,
        "Mean load (vehicles)"                   => s.mean_max_load_all_vehicles,
        "Min completion time"                    => s.min_completion_time,
        "Max completion time"                    => s.max_completion_time,
        "Mean completion time"                   => s.mean_completion_time,
        "Avrg travel time (with vehicle)"        => s.avrg_machines_travel_time_with_vehicle,
        "Avrg travel time (only with vehicle)"   => s.avrg_machines_travel_time_only_with_vehicle,
        "Avrg travel time (no vehicle)"          => s.avrg_machines_travel_time_no_vehicle,
        "Avrg waiting time (machine travel)"     => s.avrg_vehicles_waiting_time_for_a_machine_travel,
        "Avrg waiting time (service)"            => s.avrg_vehicles_waiting_time_for_a_service
	]

    lists = [
        "Machines travel times (with vehicle)"   => s.machines_travel_times_with_vehicle,
        "Machines travel times (no vehicle)"     => s.machines_travel_times_no_vehicle,
        "Max load per vehicle"                   => s.max_load_vehicle
	]

    for (k, v) in scalars
        println(io, "    ", rpad(k, 40), ": ", round(100*v, digits=4))
    end

    for (k, v) in lists
        if isempty(v)
            println(io, "    ", rpad(k, 40), ": []")
        else
            println(io, "    ", rpad(k, 40), ": ", [round(100*e, digits=4) for e in v] )
        end
    end
end

mutable struct Solution
	vehicles::Vector{Vector{VehicleStop}}
	machines::Vector{Vector{MachineTravel}}
	completion_times::Vector{Float64}
	feasible::Bool
	value::Float64
	stats::SolutionStats
end