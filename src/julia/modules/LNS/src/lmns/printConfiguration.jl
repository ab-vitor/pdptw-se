function printConfiguration(inst::InstanceData, allParams::AllParams)::Nothing
	print("""
	------------------------------------------------------
	"\n[$(Dates.Time(Dates.now()))] Running Multi Start Heuristic"
	> Experiment started at $(Dates.now())
	> Instance: $(inst.fullname)
	> Algorithm Parameters:
	""")

	println()
	output_string = ""
    output_string *= "Stop params:\n"
	for field in fieldnames(StopParams)
		output_string *= "\t-> $field $(getfield(allParams.stop, field))\n"
	end
    output_string *= "\nGeneral params:\n"
	for field in fieldnames(ParameterData)
		output_string *= "\t-> $field $(getfield(allParams.general, field))\n"
	end
	println(output_string)
	println("------------------------------------------------------")
    return nothing
end
