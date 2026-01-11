module Enumerations

import Base: parse

export StopRule, DestroyOperator, AcceptanceCriteria, SolverMethod, parse

export TARGET, MAXTIME, ITERATIONS, FEASIBILITY, GENERATIONS

export RANDOM_REQUEST_REMOVAL, RANDOM_ROUTE_REMOVAL,
	SHAW_REMOVAL, PROXIMITY_BASED_REMOVAL,
    TIME_BASED_REMOVAL, DEMAND_BASED_REMOVAL

export HILL_CLIMBING, METROPOLIS, SIMULATED_ANNEALING

export AUTOMATIC, PRIMAL_SIMPLEX, DUAL_SIMPLEX, 
    BARRIER, CONCURRENT, DETERMINISTIC_CONCURRENT


include("StopRule.jl")
include("LMNSDestroyOperators.jl")
include("AcceptanceCriteria.jl")
include("SolverMethod.jl")

end # module Enumerations