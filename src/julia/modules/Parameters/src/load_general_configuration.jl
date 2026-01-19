import Base: parse

function parse(::Type{String}, value::String)::String
	return value
end

function load_general_configuration!(gen_config_file_path::String, params::ParameterData)::Nothing
	# Create a dictionaty with fields and their types.
	param_names_types = Dict(
		[name => typ for (name, typ) in zip(fieldnames(ParameterData),
		ParameterData.types)]
	)

	param_given = Dict([name => false for name in keys(param_names_types)])

	lines = Array{String, 1}()
	try
		open(gen_config_file_path) do file
			lines = readlines(file)
		end
	catch err
		throw(LoadError(gen_config_file_path, 0,
			"cannot read '$gen_config_file_path'"))
	end

	if length(lines) == 0
		throw(LoadError(gen_config_file_path, 0,
			"cannot read '$gen_config_file_path'"))
	end

	for (line_number, line) in enumerate(lines)
		line = strip(line)
		if length(line) == 0 || line[1] == '#'
			continue
		end

		println("Loading line $line_number: $line")

		param_name = ""
		value = 0
		try
			param_name, value = split(line)

			field = Symbol(param_name)
			if field in fieldnames(ParameterData)
				data = params
			else
				throw(KeyError(""))
			end


			setfield!(data, field, parse(param_names_types[field], String(value)))
			param_given[field] = true
		catch err
			if isa(err, BoundsError)
				throw(
					LoadError(
						gen_config_file_path,
						line_number,
						"error line " *
						"$line_number of '$gen_config_file_path': " *
						"missing parameter or value",
					),
				)

			elseif isa(err, KeyError)
				throw(LoadError(gen_config_file_path, line_number,
					"parameter '$param_name' unknown"))

			elseif isa(err, ArgumentError)
				throw(LoadError(gen_config_file_path, line_number,
					"invalid value for '$param_name': $value"))
			else
				throw(err)
			end
		end
	end
	
	return nothing
end
