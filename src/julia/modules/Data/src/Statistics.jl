function chi_squared_statistic(zs::Vector{Int64}, inst::InstanceData)

	observed_frequencies = [count(x -> x == i, zs) for i in 0:length(inst.machines[1].points)-1]
	total_obs = length(zs)

	num_intervals = length(observed_frequencies)
	expected_frequency = total_obs / num_intervals

	chi_squared_statistic = sum((observed_frequencies .- expected_frequency) .^ 2 / expected_frequency)

	return chi_squared_statistic
end # function chi_squared_statistic()

function compare_orig_instance_with_modified(origInst::InstanceData, modInst::InstanceData)
	tw_shifts = Float64[]
	for i in eachindex(origInst.jobs)
		push!(tw_shifts, (modInst.jobs[i].lat - origInst.jobs[i].lat) / origInst.jobs[i].lat)
	end

	changedVehicles = 0
	for k in origInst.K
		changedVehicles += abs(origInst.vehicles[k].cap - modInst.vehicles[k].cap) / origInst.vehicles[k].cap
	end

	zs = Int64[modInst.jobs[modInst.refs[i]].point.z for i in modInst.V]

	req_loc_split_in_regions = 0
	for i in modInst.V_p
		if modInst.jobs[modInst.refs[i]].point.z != modInst.jobs[modInst.refs[i+modInst.n]].point.z
			req_loc_split_in_regions += 1
		end
	end

	println(
		modInst.group,
		";",
		modInst.name,
		";",
		round(mean(tw_shifts), digits = 4),
		";",
		round(changedVehicles / length(origInst.vehicles), digits = 4),
		";",
		round(mean(zs), digits = 4),
		";",
		round(std(zs), digits = 4),
		";",
		round(var(zs), digits = 4),
		";",
		round(chi_squared_statistic(zs, modInst), digits = 4),
		";",
		round(req_loc_split_in_regions / length(modInst.V_p), digits = 4),
	)
end # function compare_orig_instance_with_modified()

function mean_time_window_size(inst::InstanceData)
	time_window_sizes = Int64[]
	for i in eachindex(inst.jobs)
		push!(time_window_sizes, inst.jobs[i].lat - inst.jobs[i].earl)
	end

	println(inst.group, ";", inst.name, ";", round(mean(time_window_sizes), digits = 4))
end # function mean_time_window_size()

function is_tw_cap_changed(origInst::InstanceData, modInst::InstanceData)::Nothing
	tw_changed = 0
	for i in eachindex(origInst.jobs)
		if origInst.jobs[i].earl != modInst.jobs[i].earl || origInst.jobs[i].lat != modInst.jobs[i].lat
			tw_changed = 1
			break
		end
	end

	cap_changed = 0
	for k in origInst.K
		if origInst.vehicles[k].cap != modInst.vehicles[k].cap
			cap_changed = 1
			break
		end
	end

	println(modInst.group, ";", modInst.name, ";", tw_changed, ";", cap_changed)
	return nothing
end # function is_tw_cap_changed()