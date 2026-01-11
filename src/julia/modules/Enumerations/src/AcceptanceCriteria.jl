"""
	@enum AcceptanceCriteria

Defines the acceptance criteria of a solution in a metaheuristic. Currently used in LMNS
- HILL_CLIMBING: only accepts better solutions.
- METROPOLIS: always accepts better solutions, but can accept a worse solution 
	with probability exp(-(fn-fs)/T), where fn is the solution value of the neighbor, 
	fs is the solution value of the current solution, and T is the temperature.
- SIMULATED_ANNEALING: borrows the metropolis criteria, but adjusts the temperature
	over time, "cooling" down, i.e., reducing the probability of accepting worse solutions.
"""
@enum AcceptanceCriteria begin
	HILL_CLIMBING = 1
	METROPOLIS = 2
	SIMULATED_ANNEALING = 3
end

"""
	function parse(::Type{AcceptanceCriteria}, value::String)::AcceptanceCriteria

Parse `value` into a `AcceptanceCriteria`.
"""
function parse(::Type{AcceptanceCriteria}, value::String)::AcceptanceCriteria
	local_value = uppercase(strip(value)[1])
	if local_value == 'H'
		return HILL_CLIMBING
    elseif local_value == 'M'
        return METROPOLIS
	elseif local_value == 'S'
        return SIMULATED_ANNEALING
	end

	throw(ArgumentError("cannot parse $value as AcceptanceCriteria"))
end