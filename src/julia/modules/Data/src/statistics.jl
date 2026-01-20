function compare_orig_instance_with_modified(orig_inst::InstanceData, mod_inst::InstanceData)::Nothing
	tw_shifts = Float64[]
	for i in eachindex(orig_inst.jobs)
		push!(tw_shifts, (mod_inst.jobs[i].lat - orig_inst.jobs[i].lat) / orig_inst.jobs[i].lat)
	end

	cap_changes = 0
	for k in orig_inst.K
		cap_changes += abs(orig_inst.vehicles[k].cap - mod_inst.vehicles[k].cap) / orig_inst.vehicles[k].cap
	end

	req_loc_split_in_regions = 0
	for i in mod_inst.V_p
		if mod_inst.jobs[mod_inst.refs[i]].point.z != mod_inst.jobs[mod_inst.refs[i+mod_inst.n]].point.z
			req_loc_split_in_regions += 1
		end
	end

	println(
		mod_inst.group,
		";",
		mod_inst.name,
		";",
		round(mean(tw_shifts), digits = 4),
		";",
		round(cap_changes / length(orig_inst.vehicles), digits = 4),
	)
end # function compare_orig_instance_with_modified()

function is_tw_cap_changed(orig_inst::InstanceData, mod_inst::InstanceData)::Nothing
	tw_changed = 0
	for i in eachindex(orig_inst.jobs)
		if orig_inst.jobs[i].earl != mod_inst.jobs[i].earl || orig_inst.jobs[i].lat != mod_inst.jobs[i].lat
			tw_changed = 1
			break
		end
	end

	cap_changed = 0
	for k in orig_inst.K
		if orig_inst.vehicles[k].cap != mod_inst.vehicles[k].cap
			cap_changed = 1
			break
		end
	end

	println(mod_inst.group, ";", mod_inst.name, ";", tw_changed, ";", cap_changed)
	return nothing
end # function is_tw_cap_changed()