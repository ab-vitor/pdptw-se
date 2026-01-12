
function saveSolutionToFile(sol::Solution, inst::InstanceData, params::ParameterData)
	println("\n[$(Dates.Time(Dates.now()))] Saving solution to file:", params.solfilename)
	dir = dirname(params.solfilename)
	if !isdir(dir)
		mkpath(dir)
	end
	file = open(params.solfilename, "w")
	write(file, uppercase(inst.name))
	write(file, '\n')
	for k in inst.K
		write(file, "Vehicle " * string(inst.vehicles[k].id) * ":\n\t")
		rt = sol.vehicles[k]
		write(file, "Start = " * string(round(rt[1].servST, digits = 2)) * "\n\t")
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
end # function saveSolutionToFile()

function saveSolutionTimeline(sol::Solution, inst::InstanceData, gp::ParameterData, suff::String="")::Nothing
	println("\n[$(Dates.Time(Dates.now()))] Saving solution timeline to file: ", gp.timelineFilename)

	dir = dirname(gp.timelineFilename)
	if !isdir(dir)
		mkpath(dir)
	end
	timelineFilename = string(gp.timelineFilename[1:end-4], suff, ".txt")
	file = open(timelineFilename, "w")
	orig_stdout = stdout
	redirect_stdout(file)
	print_timeline_solution(inst, sol)
	close(file)
	redirect_stdout(orig_stdout)
	return nothing
end