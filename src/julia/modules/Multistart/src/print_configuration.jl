function print_configuration(inst::InstanceData, all_params::AllParams)::Nothing
	print("""
	------------------------------------------------------
	"\n[$(Dates.Time(Dates.now()))] Running Multi Start Heuristic"
	> Experiment started at $(Dates.now())
	> Instance: $(inst.full_name)
	> Algorithm Parameters:
	""")

	println()
	output_string = ""
    output_string *= "\n\t>Stop params:\n"
	for field in fieldnames(StopParams)
		output_string *= "\t\t>  - $field $(getfield(all_params.stop, field))\n"
	end
    output_string *= "\n\t>General params:\n"
	for field in fieldnames(ParameterData)
		output_string *= "\t\t>  - $field $(getfield(all_params.general, field))\n"
	end
	println(output_string)
	println("------------------------------------------------------")
    return nothing
end
