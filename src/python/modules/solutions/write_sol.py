import os
from datetime import datetime

from modules.parameters import ParameterData
from modules.data import InstanceData
from modules.solutions import Solution
from .print_timeline_solution import print_timeline_solution


def save_solution_to_file(
    sol: Solution, inst: InstanceData, params: ParameterData
) -> None:
    print(
        f"\n[{datetime.now().time()}] Saving solution to file: {params.sol_file_name}"
    )
    dir_path = os.path.dirname(params.sol_file_name)
    if not os.path.isdir(dir_path):
        os.makedirs(dir_path)

    with open(params.sol_file_name, "w") as file:
        file.write(inst.name.upper() + "\n")

        for k in inst.K:
            file.write(f"Vehicle {inst.vehicles[k].id}:\n\t")
            rt = sol.vehicles[k]
            file.write(
                f"Start = {round(rt[0].servST, 2)} | End = {round(rt[-1].servST, 2)}\n\t"
            )
            for stop in rt:
                file.write(f"{stop.job.id} ")
            file.write("\n")

        file.write("\n")
        for h in inst.H:
            file.write(f"Machine {inst.machines[h].id}:\n\t")
            mch = sol.machines[h]
            for travel in mch:
                file.write(f"({inst.jobs[inst.refs[travel.orig]].id},{inst.jobs[inst.refs[travel.dest]].id}) ")
            file.write("\n")

        file.write(f"\nValue = {sol.value}\n")

def save_solution_timeline(
    sol: Solution, inst: InstanceData, gp: ParameterData, suff: str = ""
) -> None:
    timestamp = datetime.now().time().strftime("%H:%M:%S")
    print(f"\n[{timestamp}] Saving solution timeline to file: {gp.timeline_file_name}")
    dir_path = os.path.dirname(gp.timeline_file_name)
    if not os.path.isdir(dir_path):
        os.makedirs(dir_path)
    timeline_filename = gp.timeline_file_name[:-4] + suff + ".txt"
    with open(timeline_filename, "w") as file:
        from contextlib import redirect_stdout

        with redirect_stdout(file):
            print_timeline_solution(inst, sol)
