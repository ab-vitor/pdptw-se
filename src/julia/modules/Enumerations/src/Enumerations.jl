module Enumerations

import Base: parse

export StopRule, SolverMethod, parse

export TARGET, MAXTIME, ITERATIONS, FEASIBILITY

export AUTOMATIC, PRIMAL_SIMPLEX, DUAL_SIMPLEX, 
    BARRIER, CONCURRENT, DETERMINISTIC_CONCURRENT


include("StopRule.jl")
include("SolverMethod.jl")

end # module Enumerations