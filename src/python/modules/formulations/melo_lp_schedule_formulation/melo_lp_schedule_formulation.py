from gurobipy import Model, GRB, Env
import time

from modules.data import InstanceData
from modules.solutions import Solution
from modules.parameters import ParameterData
from modules.solutions import LPSolution, update_sol_from_lp_sol


def run_lp_form_to_reschedule_sol(
    env: Env, sol: Solution, inst: InstanceData, params: ParameterData
) -> Solution:
    if params.solver == "Gurobi":
        model = Model(env=env)
        if params.output_flag_grb_mslp == 0:
            model.setParam("OutputFlag", 0)
    else:
        print("No solver selected")
        return sol

    trvs = [[(trv.orig, trv.dest) for trv in sol.machines[h]] for h in inst.H]
    sigma = [[stop.node for stop in sol.vehicles[k][1:-2]] for k in inst.K]
    psi = [
        [(trv.orig, trv.dest, trv.vehicle) for trv in sol.machines[h]] for h in inst.H
    ]
    L_k = [[i for i in range(len(sol.vehicles[k]) - 2)] for k in inst.K]
    L_h = [[i for i in range(len(sol.machines[h]))] for h in inst.H]

    t = model.addVars(inst.V_p_d, lb=0, ub=inst.jobs[inst.refs[inst.depot_begin]].lat, name="t")
    tstart = model.addVars(inst.K, lb=0, ub=inst.jobs[inst.refs[inst.depot_begin]].lat, name="tstart")
    tfinal = model.addVars(inst.K, lb=0, ub=inst.jobs[inst.refs[inst.depot_begin]].lat, name="tfinal")
    C = model.addVars(inst.K, lb=0, ub=inst.jobs[inst.refs[inst.depot_begin]].lat, name="C")
    alpha = {}
    for h in inst.H:
        for i, j in trvs[h]:
            alpha[(i, j, h)] = model.addVar(
                lb=0, ub=inst.jobs[inst.refs[inst.depot_begin]].lat, name=f"alpha_{i}_{j}_{h}"
            )

    for k in inst.K:
        for i in L_k[k][1:]:
            prev_node = sigma[k][i - 1]
            curr_node = sigma[k][i]
            if (
                inst.jobs[inst.refs[prev_node]].point.z
                == inst.jobs[inst.refs[curr_node]].point.z
            ):
                model.addConstr(
                    t[curr_node]
                    >= t[prev_node]
                    + inst.s[prev_node]
                    + inst.d[prev_node, curr_node, k],
                    name="c37",
                )

    for k in inst.K:
        if (
            len(L_k[k]) > 0
            and inst.jobs[inst.refs[inst.refs[inst.depot_begin]]].point.z
            == inst.jobs[inst.refs[sigma[k][0]]].point.z
        ):
            model.addConstr(
                t[sigma[k][0]] >= tstart[k] + inst.d[1, sigma[k][0], k], name="c38"
            )

    for h in inst.H:
        for l in L_h[h]:
            (i, j, k_) = psi[h][l]
            if i != inst.depot_begin:
                model.addConstr(
                    alpha[i, j, h] >= t[i] + inst.s[i] + inst.d_bar[i, h, k_],
                    name="c39",
                )
            else:
                model.addConstr(
                    alpha[inst.depot_begin, j, h] >= tstart[k_] + inst.d_bar[inst.depot_begin, h, k_], name="c40"
                )

    for h in inst.H:
        for l in L_h[h]:
            (i, j, k_) = psi[h][l]
            if j != inst.depot_end:
                model.addConstr(
                    t[j]
                    >= alpha[i, j, h]
                    + inst.O[inst.f[i, h], inst.f[j, h], h]
                    + inst.d_bar[j, h, k_],
                    name="c41",
                )

    for h in inst.H:
        for l in L_h[h][1:]:
            prev = psi[h][l - 1]
            curr = psi[h][l]
            model.addConstr(
                alpha[curr[0], curr[1], h]
                >= alpha[prev[0], prev[1], h]
                + inst.O[inst.f[prev[0], h], inst.f[prev[1], h], h]
                + inst.O[inst.f[prev[1], h], inst.f[curr[0], h], h],
                name="c42",
            )

    for h in inst.H:
        if len(L_h[h]) > 0:
            first = psi[h][0]
            model.addConstr(
                alpha[first[0], first[1], h]
                >= inst.O[inst.initial_station, inst.f[first[0], h], h],
                name="c43",
            )

    for k in inst.K:
        if (
            len(L_k[k]) > 0
            and inst.jobs[inst.refs[sigma[k][-1]]].point.z
            == inst.jobs[inst.refs[inst.depot_end]].point.z
        ):
            model.addConstr(
                tfinal[k]
                >= t[sigma[k][-1]]
                + inst.s[sigma[k][-1]]
                + inst.d[sigma[k][-1], inst.depot_end, k],
                name="c44",
            )

    for h in inst.H:
        for l in L_h[h]:
            (i, j, k_) = psi[h][l]
            if j == inst.depot_end:
                model.addConstr(
                    tfinal[k_]
                    >= alpha[i, inst.depot_end, h]
                    + inst.O[inst.f[i, h], inst.f[inst.depot_end, h], h]
                    + inst.d_bar[inst.depot_end, h, k_],
                    name="c45",
                )

    for k in inst.K:
        model.addConstr(C[k] >= tfinal[k] - tstart[k], name="c46")

    for i in inst.V_p_d:
        model.addConstr(inst.e[i] <= t[i], name="c47_p1")
        model.addConstr(t[i] <= inst.l[i], name="c47_p2")

    for k in inst.K:
        model.addConstr(tstart[k] <= tfinal[k], name="c48_2")

    model.setObjective(sum(C[k] for k in inst.K), GRB.MINIMIZE)

    start_time = time.time()
    model.optimize()
    elapsed_time = time.time() - start_time
    print("oi")
    exit()
    status = model.Status
    opt = 0
    tle = 0
    if status == GRB.OPTIMAL:
        opt = 1
    elif status == GRB.TIME_LIMIT and model.SolCount > 0:
        tle = 1
    else:
        sol.is_feasible = False
        return sol

    obj_value = model.ObjVal
    best_bound = model.ObjBound
    numnodes = model.NodeCount
    solve_time = model.Runtime
    gap = 100 * (obj_value - best_bound) / obj_value

    # Extract values
    t_sol = {i: t[i].X for i in t}
    tstart_sol = {k: tstart[k].X for k in tstart}
    tfinal_sol = {k: tfinal[k].X for k in tfinal}
    C_sol = {k: C[k].X for k in C}
    alpha_sol = {(i, j, h): alpha[i, j, h].X for (i, j, h) in alpha}

    lp_sol = LPSolution(
        t_sol,
        tstart_sol,
        tfinal_sol,
        C_sol,
        alpha_sol,
        status,
        opt,
        tle,
        obj_value,
        best_bound,
        numnodes,
        solve_time,
        gap,
    )
    update_sol_from_lp_sol(sol, lp_sol, inst, params)

    return sol
