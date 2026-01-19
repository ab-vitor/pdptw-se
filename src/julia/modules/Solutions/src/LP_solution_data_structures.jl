mutable struct LPSolution
	t::Containers.DenseAxisArray
	tstart::Containers.DenseAxisArray
	tfinal::Containers.DenseAxisArray
	C::Containers.DenseAxisArray
	alpha::Containers.SparseAxisArray
	status::TerminationStatusCode
	optimal::Int64
	tle::Int64
	obj_value::Float64
	best_bound::Float64
	num_nodes::Int64
	time::Float64
	gap::Float64
end # mutable struct LPSolution