mutable struct StopParams
    rule::StopRule # stopping rule
    argument::Float64 # target value or iteration/time limit
    maximum_time::Float64 # any approach stop time
end

mutable struct AllParams
    general::ParameterData
    stop::StopParams
end

mutable struct ExternalMSLPData
    best_sol::Union{Solution, Nothing} # best solution found
    curr_sol::Union{Solution, Nothing} # current solution being processed
    last_greedy_sol_value::Float64 # last greedy solution value (pure greedy or semi-greedy)

    env::Union{Gurobi.Env, Nothing} # Gurobi environment
    start_time::Float64 # start time of the MSLP run
    iteration::Int64 # current iteration number

    time_to_best::Float64 # time to best solution
    iteration_to_best::Int64 # iteration to best solution
    largest_update_offset::Int64 # largest offset between best solution updates

    LP_runs::Int64 # number of LP runs
    LP_impr::Int64 # number of LP improvements
    sum_LP_impr_percentage::Float64 # sum of LP improvement percentages
    infeasible_sol::Int64 # number of infeasible solutions
    total_time_elapsed::Float64 # total time elapsed
    percentage_infeasible_sol::Float64 # percentage of infeasible solutions
    percentage_LP_impr::Float64 # percentage of LP improvements
    mean_LP_impr_percentage::Float64 # mean LP improvement percentage

    count_improvements::Int64

    function ExternalMSLPData(
        best_sol::Union{Solution, Nothing} = nothing,
        curr_sol::Union{Solution, Nothing} = nothing,
        last_greedy_sol_value::Float64 = 0.0,
        env::Union{Gurobi.Env, Nothing} = nothing,
        start_time::Float64 = 0.0,
        iteration::Int64 = 0,
        time_to_best::Float64 = 0.0,
        iteration_to_best::Int64 = 0,
        largest_update_offset::Int64 = 0,
        LP_runs::Int64 = 0,
        LP_impr::Int64 = 0,
        sum_LP_impr_percentage::Float64 = 0.0,
        infeasible_sol::Int64 = 0,
        total_time_elapsed::Float64 = 0.0,
        percentage_infeasible_sol::Float64 = 0.0,
        percentage_LP_impr::Float64 = 0.0,
        mean_LP_impr_percentage::Float64 = 0.0,
        count_improvements::Int64 = 0,
    )
        new(
            best_sol,
            curr_sol,
            last_greedy_sol_value,
            env,
            start_time,
            iteration,
            time_to_best,
            iteration_to_best,
            largest_update_offset,
            LP_runs,
            LP_impr,
            sum_LP_impr_percentage,
            infeasible_sol,
            total_time_elapsed,
            percentage_infeasible_sol,
            percentage_LP_impr,
            mean_LP_impr_percentage,
            count_improvements
        )
    end
end


function load_stop_params(params::ParameterData)
	stop_rule = parse(StopRule, params.mslpr)
	if stop_rule == TARGET
		stop_argument = parse(Float64, params.mslpa)
	else
		stop_argument = parse(Int64, params.mslpa)
	end

	maximum_time = params.max_time
	if maximum_time <= 0
		error("Maximum time must be larger than 0.0. Given $maximum_time.")
	end

	stop_params = StopParams(stop_rule, stop_argument, maximum_time)
	return stop_params
end

