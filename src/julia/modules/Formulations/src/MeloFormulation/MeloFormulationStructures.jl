mutable struct MIPModel
	model::Model
	x::Containers.SparseAxisArray
	z::Containers.DenseAxisArray
	t::Containers.DenseAxisArray
	tstart::Containers.DenseAxisArray
	tfinal::Containers.DenseAxisArray
	C::Containers.DenseAxisArray
	phi::Containers.SparseAxisArray
	gamma::Containers.SparseAxisArray
	alpha::Containers.SparseAxisArray
end # mutable struct MIPModel
