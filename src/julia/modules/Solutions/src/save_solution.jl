
function save_summarized_solution(sol::Solution, inst::InstanceData, params::ParameterData)
	println("\n[$(Dates.Time(Dates.now()))] Saving solution to file:", params.sol_file_name)
	dir = dirname(params.sol_file_name)
	if !isdir(dir)
		mkpath(dir)
	end
	file = open(params.sol_file_name, "w")
	write(file, uppercase(inst.name))
	write(file, '\n')
	for k in inst.K
		write(file, "Vehicle " * string(inst.vehicles[k].id) * ":\n\t")
		rt = sol.vehicles[k]
		write(file, "Start = " * string(round(rt[1].serv_start_time, digits = 2)) * "\n\t")
		for fid in eachindex(rt)
			write(file, string(rt[fid].job.id) * " ")
		end
		write(file, '\n')
	end
	write(file, '\n')
	for h in inst.H
		write(file, "Machine " * string(inst.machines[h].id) * ":\n\t")
		mch = sol.machines[h]
		for fid in eachindex(mch)
			write(file, "(", string(inst.jobs[inst.refs[mch[fid].orig]].id) * "," * string(inst.jobs[inst.refs[mch[fid].dest]].id) * ") ")
		end
		write(file, '\n')
	end

	write(file, "\nValue = $(sol.value)\n")
	close(file)
end # function save_summarized_solution()

function save_solution_timeline(sol::Solution, inst::InstanceData, gp::ParameterData, suff::String="")::Nothing
	println("\n[$(Dates.Time(Dates.now()))] Saving solution timeline to file: ", gp.timeline_file_name)

	dir = dirname(gp.timeline_file_name)
	if !isdir(dir)
		mkpath(dir)
	end
	timeline_file_name = string(gp.timeline_file_name[1:end-4], suff, ".txt")
	file = open(timeline_file_name, "w")
	orig_stdout = stdout
	redirect_stdout(file)
	print_timeline_solution(inst, sol)
	close(file)
	redirect_stdout(orig_stdout)
	return nothing
end