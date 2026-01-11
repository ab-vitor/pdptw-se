function meloObjectiveFunction(model::Model, C::Containers.DenseAxisArray)
	# c32
	@objective(model, Min, sum(C))
end # function meloObjectiveFunction()