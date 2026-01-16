struct PossibleMachineTravel
	found::Bool # used to check if a possible machine travel was found
	deltaT::Float64 # the time between the moment after service time and the next vehicle stop
	h::Int64 # index of the machine used
	h_pos::Int64 # index of where this machine travel will be placed in current machine h
	st::Float64 # start time of the machine travel
	orig::Int64 # origin node in V_prime
	dest::Int64 # destiny node in V_prime
end

mutable struct InsertionData
	feasible::Bool # used to check if the object is a feasible insertionData
	cost::Float64 # cost added to current solution value
	p_pos::Int64 # position where the pickup node will be placed
	dPos::Int64 # position where the delivery node will be placed
	pJob::Int64 # index of the pickup job in V_prime
	dJob::Int64 # index of the delivert job in V_prime
	k::Int64 # index of which vehicle is used
	machineTravels::Vector{PossibleMachineTravel} # all machine travels added after p_pos-1
end

mutable struct CheckInsertionData
	feasible::Bool
	twViol::Bool
	capViol::Bool
	cost::Float64
	loadCost::Float64
	availableVehicle::Bool
end
