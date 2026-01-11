"""
	@enum StopRule

Controls stop criteria. Stops either when:
- a given number of `GENERATIONS` is given;
- or a `TARGET` value is found;
- or no `IMPROVEMENT` is found in a given number of iterations.
"""
@enum StopRule begin
	GENERATIONS = 0
	TARGET = 1
	MAXTIME = 2
	ITERATIONS = 3
	FEASIBILITY = 4
end

"""
	function parse(::Type{StopRule}, value::String)::StopRule

Parse `value` into a `StopRule`.
"""
function parse(::Type{StopRule}, value::String)::StopRule
	local_value = uppercase(strip(value)[1])
	if local_value == 'G'
		return GENERATIONS
	elseif local_value == 'T'
		return TARGET
	elseif local_value == 'M'
		return MAXTIME
	elseif local_value == 'I'
		return ITERATIONS
	elseif local_value == 'F'
		return FEASIBILITY
	end

	throw(ArgumentError("cannot parse $value as StopRule"))
end