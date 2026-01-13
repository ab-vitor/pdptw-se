function compare_orig_instance_with_modified(origInst::InstanceData, modInst::InstanceData)
	tw_shifts = Float64[]
	for i in eachindex(origInst.jobs)
		push!(tw_shifts, (modInst.jobs[i].lat - origInst.jobs[i].lat) / origInst.jobs[i].lat)
	end

	cap_changes = 0
	for k in origInst.K
		cap_changes += abs(origInst.vehicles[k].cap - modInst.vehicles[k].cap) / origInst.vehicles[k].cap
	end

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
		round(cap_changes / length(origInst.vehicles), digits = 4),
	)
end # function compare_orig_instance_with_modified()

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