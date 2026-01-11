"""
	@enum SolverMethod

    Algorithm used to solve continuous models.
    See Gurobi docs.
"""
@enum SolverMethod begin
	AUTOMATIC = -1
	PRIMAL_SIMPLEX = 0
	DUAL_SIMPLEX = 1
	BARRIER = 2
	CONCURRENT = 3
    DETERMINISTIC_CONCURRENT = 4
end

"""
	function parse(::Type{SolverMethod}, value::String)::SolverMethod

Parse `value` into a `SolverMethod`.
"""
function parse(::Type{SolverMethod}, value::String)::SolverMethod
	local_value = uppercase(strip(value))
	if local_value == "A"
		return AUTOMATIC
	elseif local_value == "P"
		return PRIMAL_SIMPLEX
	elseif local_value == "D"
		return DUAL_SIMPLEX
	elseif local_value == "B"
		return BARRIER
	elseif local_value == "C"
		return CONCURRENT
    elseif local_value == "DC"
		return DETERMINISTIC_CONCURRENT
	end

	throw(ArgumentError("cannot parse $value as SolverMethod"))
end