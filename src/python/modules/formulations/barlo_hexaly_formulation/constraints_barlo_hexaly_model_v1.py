from typing import List, Optional
from modules.data import InstanceData
from modules.parameters import ParameterData
from hexaly.optimizer import HxModel, HxExpression
from .entities_barlo_hexaly_formulation import (
    BarloHxRoutingVars,
    BarloHxSchedulingVars,
)


def link_trajectories_to_routes(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
) -> None:
    routes_array: HxExpression = rtvars.routes_array

    trajectories: List[HxExpression] = rtvars.trajectories
    origins_A_m: HxExpression = rtvars.origins_A_m
    destinies_A_m: HxExpression = rtvars.destinies_A_m

    offset: int = 1

    for h in inst.H:
        trajectory = trajectories[h]
        c = model.count(trajectory)

        def link_trajectory_route_function(i: HxExpression) -> HxExpression:
            orig = model.at(origins_A_m, trajectory[i])
            dest = model.at(destinies_A_m, trajectory[i])
            orig_offset = orig - offset
            dest_offset = dest - offset
            nb_not_found = -1

            # Case 1: arc from depot_begin
            is_arc_from_depot_begin = orig == inst.depot_begin
            route_dest_offset_index = model.find(routes_array, dest_offset)
            dest_offset_index = model.iif(
                route_dest_offset_index != nb_not_found,
                model.index(
                    model.at(routes_array, route_dest_offset_index), dest_offset
                ),
                nb_not_found,
            )

            # Case 2: arc to depot_end
            is_arc_to_depot_end = dest == inst.depot_end
            route_orig_offset_index = model.find(routes_array, orig_offset)
            orig_offset_index = model.iif(
                route_orig_offset_index != nb_not_found,
                model.index(
                    model.at(routes_array, route_orig_offset_index), orig_offset
                ),
                nb_not_found,
            )
            last_index_route_orig_offset = model.iif(
                route_orig_offset_index != nb_not_found,
                model.count(model.at(routes_array, route_orig_offset_index)) - 1,
                nb_not_found,
            )

            # Case 3: intermediate link
            # expressions already defined

            return model.iif(
                is_arc_from_depot_begin,
                dest_offset_index == 0,
                model.iif(
                    is_arc_to_depot_end,
                    model.and_(
                        route_orig_offset_index >= 0,
                        orig_offset_index == last_index_route_orig_offset,
                    ),
                    model.and_(
                        route_orig_offset_index == route_dest_offset_index,
                        orig_offset_index + 1 == dest_offset_index,
                    ),
                ),
            )

        link_trajectory_route_lambda = model.lambda_function(
            link_trajectory_route_function
        )
        model.constraint(model.and_(model.range(0, c), link_trajectory_route_lambda))

    return None


def link_routes_to_trajectories(
    inst: InstanceData, model: HxModel, rtvars: BarloHxRoutingVars
) -> None:

    routes: List[HxExpression] = rtvars.routes

    trajectories_array: HxExpression = rtvars.trajectories_array
    idx_A_m: HxExpression = rtvars.idx_A_m
    diff_region: HxExpression = rtvars.diff_region

    offset: int = 1

    for k in inst.K:
        route = routes[k]
        c = model.count(route)

        def link_route_trajectory_function(i: HxExpression) -> HxExpression:
            is_first = model.eq(i, 0)
            is_last = model.eq(i, c - 1)
            nb_not_found = -1

            u = model.iif(
                is_first,
                inst.depot_begin,
                route[i - 1] + offset,
            )
            v = route[i] + offset

            last_v = inst.depot_end

            arc_exists = model.at(diff_region, u, v)
            arc_idx = model.at(idx_A_m, u, v)
            arc_found = model.find(trajectories_array, arc_idx) != nb_not_found

            last_arc_exists = model.at(diff_region, v, last_v)
            last_arc_idx = model.at(idx_A_m, v, last_v)
            last_arc_found = (
                model.find(trajectories_array, last_arc_idx) != nb_not_found
            )

            return model.iif(
                is_last,
                model.and_(
                    model.iif(arc_exists, arc_found, True),
                    model.iif(last_arc_exists, last_arc_found, True),
                ),
                model.iif(arc_exists, arc_found, True),
            )

        link_route_trajectory_lambda = model.lambda_function(
            link_route_trajectory_function
        )
        link_route_trajectory = model.and_(
            model.range(0, c), link_route_trajectory_lambda
        )
        model.constraint(link_route_trajectory)


def barlo_hexaly_routing_constraints(
    inst: InstanceData,
    params: ParameterData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
) -> None:
    """
    Routing constraints for both vehicles and machines
    """
    routes: List[HxExpression] = rtvars.routes
    routes_array: HxExpression = rtvars.routes_array
    trajectories: List[HxExpression] = rtvars.trajectories
    demands: HxExpression = rtvars.demands
    routes_loads: List[Optional[HxExpression]] = rtvars.routes_loads

    offset: int = 1

    # All customers must be visited by exactly one vehicle
    model.constraint(model.partition(routes))

    # Pickups and deliveries
    for i in inst.V_p:
        p: int = i - offset
        d: int = p + inst.n
        pick_up_list_index = model.find(routes_array, p)
        delivery_list_index = model.find(routes_array, d)
        model.constraint(pick_up_list_index == delivery_list_index)

        pick_up_list = model.at(routes_array, pick_up_list_index)
        delivery_list = model.at(routes_array, delivery_list_index)
        model.constraint(model.index(pick_up_list, p) < model.index(delivery_list, d))

    # Capacity constraint
    for k in inst.K:
        route = routes[k]
        c = model.count(route)

        demand_lambda = model.lambda_function(
            lambda i, prev: prev + demands[route[i] + offset]
        )
        routes_loads[k] = model.array(model.range(0, c), demand_lambda, 0)

        load_lambda = model.lambda_function(lambda i: routes_loads[k][i] <= inst.Q[k])
        model.constraint(model.and_(model.range(0, c), load_lambda))

    # At most one machine-arc visited by one machine
    model.constraint(model.disjoint(trajectories))

    # Link each trajectory to a valid position in the routes
    link_trajectories_to_routes(inst, model, rtvars)
    link_routes_to_trajectories(inst, model, rtvars)

    return None




def constraints_machine_travels_start_times(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
) -> None:
    routes_array: HxExpression = rtvars.routes_array
    trajectories: List[HxExpression] = rtvars.trajectories

    tstart_array: HxExpression = schvars.tstart_array
    t_array: HxExpression = schvars.t_array
    alpha_array: HxExpression = schvars.alpha_array

    # Routing data transformed into hexaly array
    origins_A_m: HxExpression = rtvars.origins_A_m
    destinies_A_m: HxExpression = rtvars.destinies_A_m

    # Scheduling data transformed into hexaly array
    service_time: HxExpression = schvars.service_time
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix

    offset: int = 1

    for h in inst.H:
        trajectory: HxExpression = trajectories[h]
        c: HxExpression = model.count(trajectory)

        def machine_travels_start_times_function(i: HxExpression) -> HxExpression:
            orig: HxExpression = model.at(origins_A_m, trajectory[i])
            dest: HxExpression = model.at(destinies_A_m, trajectory[i])
            orig_offset: HxExpression = model.sub(orig, offset)
            dest_offset: HxExpression = model.sub(dest, offset)

            nb_not_found: int = -1

            index_route_orig: HxExpression = model.find(routes_array, orig_offset)
            index_route_dest: HxExpression = model.find(routes_array, dest_offset)

            found_orig = model.neq(index_route_orig, nb_not_found)
            is_orig_depot_begin: HxExpression = model.eq(orig, inst.depot_begin)
            found_dest: HxExpression = model.neq(index_route_dest, nb_not_found)

            vehicle_arrival_time_from_depot: HxExpression = model.iif(
                model.and_(
                    is_orig_depot_begin,
                    found_dest,
                ),
                model.sum(
                    model.at(tstart_array, index_route_dest),
                    model.at(d_bar_matrix, orig, h, index_route_dest),
                ),
                0,
            )

            vehicle_arrival_time_general_case: HxExpression = model.iif(
                found_orig,
                model.sum(
                    model.at(t_array, orig_offset),
                    model.at(service_time, orig),
                    model.at(d_bar_matrix, orig, h, index_route_orig),
                ),
                0,
            )

            vehicle_arrival_time: HxExpression = model.iif(
                found_orig,
                vehicle_arrival_time_general_case,
                vehicle_arrival_time_from_depot,
            )

            is_first: HxExpression = model.eq(i, 0)
            last_i: HxExpression = model.sub(i, 1)

            prev_orig: HxExpression = model.at(origins_A_m, trajectory[last_i])
            prev_dest: HxExpression = model.at(destinies_A_m, trajectory[last_i])

            machine_arrival_time: HxExpression = model.iif(
                is_first,
                model.at(
                    O_matrix, inst.initial_station, model.at(f_matrix, orig, h), h
                ),
                model.sum(
                    model.at(alpha_array, trajectory[last_i]),
                    model.at(
                        O_matrix,
                        model.at(f_matrix, prev_orig, h),
                        model.at(f_matrix, prev_dest, h),
                        h,
                    ),
                    model.at(
                        O_matrix,
                        model.at(f_matrix, prev_dest, h),
                        model.at(f_matrix, orig, h),
                        h,
                    ),
                ),
            )

            machine_travel_start_time = model.max(
                machine_arrival_time, vehicle_arrival_time, 
            )
            return model.geq(
                model.at(alpha_array, trajectory[i]), machine_travel_start_time
            )

        machine_travels_start_times_lambda: HxExpression = model.lambda_function(
            machine_travels_start_times_function
        )
        force_alpha_machine_travels_start_times = model.and_(
            model.range(0, c), machine_travels_start_times_lambda
        )
        model.constraint(force_alpha_machine_travels_start_times)


def constraints_service_start_times(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
) -> None:

    routes: HxExpression = rtvars.routes
    trajectories_array: HxExpression = rtvars.trajectories_array

    tstart_array: HxExpression = schvars.tstart_array
    t_array: List[HxExpression] = schvars.t_array
    alpha_array: List[HxExpression] = schvars.alpha_array

    # Routing data transformed into hexaly array
    idx_A_m: HxExpression = rtvars.idx_A_m
    diff_region: HxExpression = rtvars.diff_region

    # Scheduling data transformed into hexaly array
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix
    service_time: HxExpression = schvars.service_time
    earliest: HxExpression = schvars.earliest
    latest: HxExpression = schvars.latest
    d_matrix: HxExpression = schvars.d_matrix

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        def service_start_times_function(i: HxExpression) -> HxExpression:
            is_first: HxExpression = model.eq(i, 0)
            last_i: HxExpression = model.sub(i, 1)

            curr: HxExpression = route[i]
            prev: HxExpression = route[last_i]
            curr_offset: HxExpression = model.sum(curr, offset)
            prev_offset: HxExpression = model.sum(prev, offset)

            time_window_earliest_time: HxExpression = model.at(earliest, curr_offset)
            time_window_latest_time: HxExpression = model.at(latest, curr_offset)

            using_machine: HxExpression = model.at(
                diff_region, prev_offset, curr_offset
            )
            using_machine_from_depot: HxExpression = model.at(
                diff_region, inst.depot_begin, curr_offset
            )

            index_arc_in_A_m: HxExpression = model.at(idx_A_m, prev_offset, curr_offset)
            index_arc_in_A_m_from_depot: HxExpression = model.at(
                idx_A_m, inst.depot_begin, curr_offset
            )

            index_machine_arc_in_A_m: HxExpression = model.find(
                trajectories_array, index_arc_in_A_m
            )
            index_machine_arc_in_A_m_from_depot: HxExpression = model.find(
                trajectories_array, index_arc_in_A_m_from_depot
            )

            using_machine_arrival_time_from_depot = model.iif(
                using_machine_from_depot,
                model.sum(
                    model.at(
                        alpha_array,
                        index_arc_in_A_m_from_depot,
                    ),
                    model.at(
                        O_matrix,
                        model.at(
                            f_matrix,
                            inst.depot_begin,
                            index_machine_arc_in_A_m_from_depot,
                        ),
                        model.at(
                            f_matrix,
                            curr_offset,
                            index_machine_arc_in_A_m_from_depot,
                        ),
                        index_machine_arc_in_A_m_from_depot,
                    ),
                    model.at(
                        d_bar_matrix,
                        curr_offset,
                        index_machine_arc_in_A_m_from_depot,
                        k,
                    ),
                ),
                0,
            )

            using_machine_arrival_time_general_case: HxExpression = model.iif(
                using_machine,
                model.sum(
                    model.at(
                        alpha_array,
                        index_arc_in_A_m,
                    ),
                    model.at(
                        O_matrix,
                        model.at(
                            f_matrix,
                            prev_offset,
                            index_machine_arc_in_A_m,
                        ),
                        model.at(
                            f_matrix,
                            curr_offset,
                            index_machine_arc_in_A_m,
                        ),
                        index_machine_arc_in_A_m,
                    ),
                    model.at(
                        d_bar_matrix,
                        curr_offset,
                        index_machine_arc_in_A_m,
                        k,
                    ),
                ),
                0,
            )

            using_machine_arrival_time: HxExpression = model.iif(
                is_first,
                using_machine_arrival_time_from_depot,
                using_machine_arrival_time_general_case,
            )

            no_machine_arrival_time_from_depot: HxExpression = model.sum(
                model.at(tstart_array, k),
                model.at(d_matrix, inst.depot_begin, curr_offset, k),
            )
            no_machine_arrival_time_general_case: HxExpression = model.sum(
                model.at(t_array, prev),
                model.at(service_time, prev_offset),
                model.at(d_matrix, prev_offset, curr_offset, k),
            )

            no_machine_arrival_time: HxExpression = model.iif(
                is_first,
                no_machine_arrival_time_from_depot,
                no_machine_arrival_time_general_case,
            )

            service_start_time = model.max(
                time_window_earliest_time,
                no_machine_arrival_time,
                using_machine_arrival_time,
            )

            return model.and_(
                model.geq(model.at(t_array, curr), service_start_time),
                model.leq(
                    model.at(t_array, model.at(route, i)),
                    time_window_latest_time,
                ),
            )

        service_start_times_lambda: HxExpression = model.lambda_function(
            service_start_times_function
        )
        force_service_start_times = model.and_(
            model.range(0, c),
            service_start_times_lambda,
        )
        model.constraint(force_service_start_times)


def constraints_tfinal(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
) -> None:
    routes: HxExpression = rtvars.routes
    trajectories_array: HxExpression = rtvars.trajectories_array

    tstart: List[HxExpression] = schvars.tstart
    tfinal: List[HxExpression] = schvars.tfinal
    t_array: HxExpression = schvars.t_array
    alpha_array: HxExpression = schvars.alpha_array

    # Routing data transformed into hexaly array
    idx_A_m: HxExpression = rtvars.idx_A_m

    # Scheduling data transformed into hexaly array
    service_time: HxExpression = schvars.service_time
    d_matrix: HxExpression = schvars.d_matrix
    d_bar_matrix: HxExpression = schvars.d_bar_matrix
    O_matrix: HxExpression = schvars.O_matrix
    f_matrix: HxExpression = schvars.f_matrix

    offset: int = 1

    for k in inst.K:
        route: HxExpression = routes[k]
        c: HxExpression = model.count(route)

        last_index: HxExpression = model.sub(c, 1)
        last_orig: HxExpression = model.sum(model.at(route, last_index), offset)
        index_A_m = model.at(idx_A_m, last_orig, inst.depot_end)

        machine_last_arc: HxExpression = model.find(trajectories_array, index_A_m)
        nb_not_found: int = -1
        arrival_time_from_machine: HxExpression = model.iif(
            model.neq(machine_last_arc, nb_not_found),
            model.sum(
                model.at(alpha_array, index_A_m),
                model.at(
                    O_matrix,
                    model.at(f_matrix, last_orig, machine_last_arc),
                    model.at(f_matrix, inst.depot_end, machine_last_arc),
                    machine_last_arc,
                ),
                model.at(
                    d_bar_matrix,
                    model.at(f_matrix, inst.depot_end, machine_last_arc),
                    machine_last_arc,
                    k,
                ),
            ),
            tstart[k],
        )

        arrival_time_from_last_node: HxExpression = model.sum(
            model.at(t_array, model.at(route, last_index)),
            model.at(
                service_time,
                last_orig,
            ),
            model.at(
                d_matrix,
                last_orig,
                inst.depot_end,
                k,
            ),
        )

        arrival_time_from_last_node: HxExpression = model.iif(
            model.gt(c, 0),
            model.geq(
                tfinal[k],
                model.max(arrival_time_from_last_node, arrival_time_from_machine),
            ),
            True,
        )
        model.constraint(arrival_time_from_last_node)

        model.constraint(model.geq(tfinal[k], tstart[k]))


def constraints_completion_time(
    inst: InstanceData,
    model: HxModel,
    schvars: BarloHxSchedulingVars,
) -> None:
    tstart: List[HxExpression] = schvars.tstart
    tfinal: List[HxExpression] = schvars.tfinal

    C: List[HxExpression] = schvars.C

    for k in inst.K:
        model.constraint(model.geq(C[k], model.sub(tfinal[k], tstart[k])))


def barlo_hexaly_scheduling_constraints(
    inst: InstanceData,
    model: HxModel,
    rtvars: BarloHxRoutingVars,
    schvars: BarloHxSchedulingVars,
    params: ParameterData,
) -> None:
    """
    Scheduling constraints envolving vehicles and machines
    """

    constraints_machine_travels_start_times(inst, model, rtvars, schvars)
    constraints_service_start_times(inst, model, rtvars, schvars)

    constraints_tfinal(inst, model, rtvars, schvars)
    constraints_completion_time(inst, model, schvars)
