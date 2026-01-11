mutable struct MIPVarsSolution
	x::Union{Nothing, Containers.SparseAxisArray}
	z::Union{Nothing, Containers.DenseAxisArray}
	t::Union{Nothing, Containers.DenseAxisArray}
	tstart::Union{Nothing, Containers.DenseAxisArray}
	tfinal::Union{Nothing, Containers.DenseAxisArray}
	C::Union{Nothing, Containers.DenseAxisArray}
	phi::Union{Nothing, Containers.SparseAxisArray}
	gamma::Union{Nothing, Containers.SparseAxisArray}
	alpha::Union{Nothing, Containers.SparseAxisArray}

	function MIPVarsSolution(
		x::Union{Nothing, Containers.SparseAxisArray} = nothing,
		z::Union{Nothing, Containers.DenseAxisArray} = nothing,
		t::Union{Nothing, Containers.DenseAxisArray} = nothing,
		tstart::Union{Nothing, Containers.DenseAxisArray} = nothing,
		tfinal::Union{Nothing, Containers.DenseAxisArray} = nothing,
		C::Union{Nothing, Containers.DenseAxisArray} = nothing,
		phi::Union{Nothing, Containers.SparseAxisArray} = nothing,
		gamma::Union{Nothing, Containers.SparseAxisArray} = nothing,
		alpha::Union{Nothing, Containers.SparseAxisArray} = nothing,
	)
		return new(x, z, t, tstart, tfinal, C, phi, gamma, alpha)
	end
end # mutable struct MIPVarsSolution

mutable struct MIPStats
	status::TerminationStatusCode
	optimal::Int64
	tle::Int64
	objValue::Float64
	bestbound::Float64
	numnodes::Int64
	time::Float64
	gap::Float64
	function MIPStats(
		status::TerminationStatusCode = INFEASIBLE,
		optimal::Int64 = 0,
		tle::Int64 = 0,
		objValue::Float64 = Inf64,
		bestbound::Float64 = 0.0,
		numnodes::Int64 = 0,
		time::Float64 = 0.0,
		gap::Float64 = 0.0,
	)
		return new(status, optimal, tle, objValue, bestbound, numnodes, time, gap)
	end
end # mutable struct MIPStats

mutable struct MIPSolution
	vars::MIPVarsSolution
	stats::MIPStats
	function MIPSolution(
		vars::MIPVarsSolution = MIPVarsSolution(),
		stats::MIPStats = MIPStats(),
	)
		return new(vars, stats)
	end
end # mutable struct MIPSolution

mutable struct LPSolution
	t::Containers.DenseAxisArray
	tstart::Containers.DenseAxisArray
	tfinal::Containers.DenseAxisArray
	C::Containers.DenseAxisArray
	alpha::Containers.SparseAxisArray
	status::TerminationStatusCode
	optimal::Int64
	tle::Int64
	objValue::Float64
	bestbound::Float64
	numnodes::Int64
	time::Float64
	gap::Float64
end # mutable struct LPSolution