"""
	@enum DestroyOperator

Controls the destroy operator. It can be either:
- RANDOM_REQUEST_REMOVAL: given the degree of destruction `psi`, it randomly removes `psi` requests (p & d), 
    and it also sets free whether a vehicle is active or not (1)
- RANDOM_ROUTE_REMOVAL: given the degree of destruction `psi`, randomly selects `psi` routes to remove. 
    The route should have length > 2. It also sets free whether a vehicle is active or not (1)
- SHAW_REMOVAL: randomly selects a job `i` and add to a removal list. The next `psi-1` jobs to remove are selected
    based on its degree of relatedness involving distance, time (earliness), whether they are in the same route, and 
    demand. The selected job is a `j* = argmin_{j in V_p cup V_d} {Phi_1 d_{ij} + Phi_2 |e_i - e_j| + Phi_3 l_{ij} + Phi_4 |q_i - q_j|}`,
    where, l_{ij} is -1 if they are in the same route, 1 otherwise. Note: always compared to the last job added to the list.
- PROXIMITY_BASED_REMOVAL: related with SHAW_REMOVAL, but for Phi_1 = 1, Phi_2 = Phi_3 = Phi_4 = 0.
- TIME_BASED_REMOVAL: related with SHAW_REMOVAL, but for Phi_2 = 1, Phi_1 = Phi_3 = Phi_4 = 0.
- DEMAND_BASED_REMOVAL: related with SHAW_REMOVAL, but for Phi_4 = 1, Phi_1 = Phi_2 = Phi_3 = 0.

(1) That means x[inst.depot_begin,inst.depot_end,k] in {0,1}, FORALL k in inst.K
"""
@enum DestroyOperator begin
	RANDOM_REQUEST_REMOVAL = 1
    RANDOM_ROUTE_REMOVAL = 2
    SHAW_REMOVAL = 3
    PROXIMITY_BASED_REMOVAL = 4
    TIME_BASED_REMOVAL = 5
    DEMAND_BASED_REMOVAL = 6
end

"""
	function parse(::Type{DestroyOperator}, value::String)::DestroyOperator

Parse `value` into a `DestroyOperator`.
"""
function parse(::Type{DestroyOperator}, value::String)::DestroyOperator
	local_value = uppercase(strip(value)[1])
	if local_value == 'A'
		return RANDOM_REQUEST_REMOVAL
    elseif local_value == 'B'
        return RANDOM_ROUTE_REMOVAL
	elseif local_value == 'C'
        return SHAW_REMOVAL
    elseif local_value == 'D'
        return PROXIMITY_BASED_REMOVAL
    elseif local_value == 'E'
        return TIME_BASED_REMOVAL
    elseif local_value == 'F'
        return DEMAND_BASED_REMOVAL
	end

	throw(ArgumentError("cannot parse $value as DestroyOperator"))
end