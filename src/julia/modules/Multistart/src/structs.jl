struct PossibleMachineTravel
	found::Bool # used to check if a possible machine travel was found
	delta_t::Float64 # the time between the moment after service time and the next vehicle stop
	h::Int64 # index of the machine used
	h_pos::Int64 # index of where this machine travel will be placed in current machine h
	st::Float64 # start time of the machine travel
	orig::Int64 # origin node in V_prime
	dest::Int64 # destiny node in V_prime
	vehicle_index::Int64 # position in vehicle where machine travel was held
end

mutable struct InsertionData
	feasible::Bool # used to check if the object is a feasible insertionData
	cost::Float64 # cost added to current solution value
	p_pos::Int64 # position where the pickup node will be placed
	d_pos::Int64 # position where the delivery node will be placed
	p_job::Int64 # index of the pickup job in V_prime
	d_job::Int64 # index of the delivert job in V_prime
	k::Int64 # index of which vehicle is used
	machine_travels::Vector{Vector{PossibleMachineTravel}} # all machine travels added after p_pos-1
end

mutable struct CheckInsertionData
	feasible::Bool # used to check if the insertion is feasible
	cost::Float64 # cost added to current solution value
	possible_machine_travels::Vector{Vector{PossibleMachineTravel}} # all machine travels added after p_pos-1
end

