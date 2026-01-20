# pdptw-se

Source code, instances, data processing scripts, and detailed results for the Pickup and Delivery Problem with Time windows and Scheduling on the Edges.

This repository refers to the code and data used in the paper: "The pickup and delivery problem with time windows and scheduling on the edges", by Vítor A. Barbosa, Sunil Tiwari, and Rafael A. Melo, currently under review.

## Contents

- [General organization](#general-organization) — repository layout and key folders (instances, pdptw-se-statistics, src).
- [Julia code organiztion](#julia-code-organiztion) — structure of the Julia modules and configs.
- [How to run the Julia code](#how-to-run-the-julia-code) — required packages, run modes, and main parameters for MSLP.
- [How to run the instance generator](#how-to-run-the-instance-generator) — scripts and example commands to produce instances.
- [How to run the R code (pdptw-se-statistics)](#how-to-run-the-r-code-pdptw-se-statistics) — instructions to reproduce tables and plots.
- [Citation](#citation) — how to cite the work.
- [Questions?](#questions) — contact information.

## General organization

- `instances/`: place for the instances, instance generators, and scripts to generate all original instances.
  - `multi_floor/`: original pdptw-se instances multi-floor.
    - `orig_ams/`: original instances with all machine stations, along with map illustrations.
    - `orig_ams_fg/`: original instances modified to ensure feasibility using the greedy procedure.
  - `multi_island/`: original pdptw-se instances multi-island.
    - `orig_ams/`: original instances with all machine stations, along with map illustrations.
    - `orig_ams_fg/`: original instances modified to ensure feasibility using the greedy procedure.
  - `pdptw_100_li_lim/`: original pdptw instances with about 100 tasks (about 50 pickup and delivery requests).
    - `lc*`: clustered instances.
    - `lrc*`: randomized-clustered instances.
    - `lr*`: randomized instances (used to generate the pdptw-se instances).
  - `pdptw_200_li_lim/`: original pdptw instances with about 200 tasks (about 100 pickup and delivery requests).
    - `LC*`: clustered instances.
    - `LCR*`: randomized-clustered instances.
    - `LR*`: randomized instances (used to generate the pdptw-se instances).
- `pdptw-se-statistics/`: paper experiment data and data processing scripts along with the resulting outputs (tables, plots, etc.).
  - `inst_statistics/`: instance statistics data regarding time window and capacity changes, scripts and their output tables.
  - `official_experiments/`: data, scripts and their output tables and plots.
    - `data/`: all csv tables from experiments and other auxiliary tables.
    - `grb_vs_hx/`: for the Gurobi-Hexaly MIP comparison.
    - `grouped_mip/`: for grouping MIP results for both the Gurobi and Hexaly solvers.
    - `mip_grb_vi/`: for the MIP with valid inequalities experiments.
    - `mslp/`: for the MSLP heuristic.
    - `mslp_vs_mip/`: for the comparison between MSLP heuristic and MIP formulation.
    - `solution_chars/`: for the solution characteristics/statistics analysis.
    - `time_and_optimality_gap/`: for the time and optimality gap analysis.
- `src/`: algorithmic code.
  - `julia/`: Multi-start heuristic with a Linear Programming (LP) improvement procedure (MSLP), and the heuristic to ensure instance feasibility.

## Julia code organiztion

- The Julia code is organized in modules.
- The main file `pdptwse.jl` loads the folder `modules/`, read the input parameters, the instance data, and then runs the desired method to solve the instance. If a solution was achieved, it can be displayed in console and then it is validated.
- Each module has a main file named `<module-name>.jl` and, if needed, other auxiliary files.
- General description of each module:
  - `Parameters/`: module to read and store input parameters.
  - `Data/`: module to read and store instance data.
  - `GreedyHeuristicMutate/`: module that implements the greedy heuristic to ensure instance feasibility.
  - `Multistart`: module that implements the multi-start heuristic framework.
  - `Formulations/`: module that implements the LP improvement procedure.
  - `Solutions/`: module to define solution structures; display, convert, save, and validate solutions; and compute solution statistics.
  - `Enumerations/`: module to define enumerations used in the code.
  - `CSVUtils/`: auxiliary module to read and write CSV files.
  - `ProcUsage/`: auxiliary module to compute user and system CPU times.
- The folder `configs/` contains configuration file examples to run the code with different parameters.
  - You can duplicate and modify these files to create your own configuration files.
  - The created configuration file with a suffix different from `_example.conf` is ignored in the repository (see .gitignore).
- By default, a folder `logs/` is created to store the log files generated during the execution. We ignore this folder here in the repository (see .gitignore).
- The folder `scripts/` contains example scripts to run instance related experiments (involving time window and capacity modifications).
  - These scripts use the files `compare_instances.jl` and `is_tw_cap_changed.jl` located in the `src/julia/` folder.

## How to run the Julia code

- The Julia version used in the experiments is Julia v1.11.3. Make sure you install Julia in your machine.
- Clone the repository and navigate to the folder `src/julia/` in your terminal.
- Necessary packages and respective versions used on the experiments (maybe other versions work as well):
  - CSV v0.10.15
  - DataFrames v1.7.0
  - Gurobi v1.5.0
  - JuMP v1.23.6
  - Gurobi_jll v12.0.2
- To install the necessary packages, run Julia's package manager by typing `]` in the Julia REPL, and then run for each package:

    ```julia
    add <package_name>@<version>
    ```

- There are three main ways to run the Julia code:
  1. **Passing each parameter in the command line**: pass each parameter by writting its name with the prefix `--`, followed by the desired value (if it has a value).

        ```shell
        julia pdptwse.jl --inst_path ../../instances/multi_island/orig_ams_fg/60R_60V_04I_06M/t2/LR2_2_2 --cut_off_machs 5 --method_type heur --method_code mslp --seed 17 --greedy_service_order random --alpha 0.05 --threads 1 --output_flag_grb_MSLP 0 --mslpa 1000 --mslpr I --max_time 60 --output ./logs/ --print_sol 0 --solver_method A
        ```

  2. **Using a configuration file**: pass only the configuration file by writting `--gen_config_file_path`, followed by the relative path to the configuration file.

        ```shell
        julia pdptwse.jl --gen_config_file_path ./configs/mslp/gen_config_mslp.conf
        ```

  3. **A mix of both**: pass some parameters in the command line and others with the file. Obs.: if you pass additional parameters after `--gen_config_file_path`, it will overwrite the parameter you chose before in the configuration file. You can use it to avoid changing the configuration file too often. The last parameter value is always used.

        ```shell
        julia pdptwse.jl --inst_path ../../instances/multi_island/orig_ams_fg/60R_60V_04I_06M/t2/LR2_2_2 --cut_off_machs 5 --gen_config_file_path ./configs/mslp/gen_config_mslp.conf
        ```

- You can check the default value of each parameter in the file `src/julia/modules/Parameters/src/structures.jl`. Some of them are defined after reading all the parameters (see `function read_input_parameters(ARGS::Vector{String})::ParameterData`), like output file names, and others cannot be passed (e.g. parameter `rng`, which is defined based on the parameter `seed`).
- The `method_code == gmutate` is only used to generate the a feasible instance (see Section **How to run the instance generator**). Parameter `--make_instance_feasible` is only used with this method code to save the modified instance.
- Main parameters for the MSLP execution:
  - `--inst_path <string>`: path to the instance file.
  - `--cut_off_machs <int>`: number of machine stations to be used in the instance (to reduce the original number of machines of the instance). Obs: it selects the first `cut_off_machs` machines in the instance file.
  - `--elevator`: only pass this parameter if it is a multi-floor instance.
  - `--method_type heur`: to run a heuristic method.
  - `--method_code mslp`: to run the MSLP heuristic.
  - `--mslpr <string>`: stop rule for the MSLP heuristic. Possible values: see `src/julia/modules/Enumerations/src/StopRule.jl`.
  - `--mslpa <int>`: stop argument for the MSLP heuristic.
  - `--max_time <float>`: maximum time allowed for the execution (in seconds).
  - `--greedy_service_order <string>`: defines the order of insertion of the requests in the partial solution. Possible values: `tightest_tw` (sorts by the tightest pickup time window) and `random` (sorts randomly).
  - `--seed <int>`: seed for the random number generator.
  - `--threads <int>`: number of threads for the LP solver.
  - `--solver_method <char>`: solver method for Gurobi. Possible values: see `src/julia/modules/Enumerations/src/SolverMethod.jl`.
  - `--output_flag_grb_MSLP <int>`: output flag for Gurobi during the MSLP execution. Possible values: `0` (no output), `1` (normal output).
- The MSLP heuristic uses Gurobi as LP solver. Make sure you have Gurobi installed and properly configured in your machine.
- Furthermore, each function of the Multistart module is documented for clarification.

## How to run the instance generator

- There are two scripts to generate the instances used in the paper.
  - `bash_small_inst_gen_multi_island_ams.sh`: executes multiple times the python code `smaller_insts_gen_multi_island.py` to generate each group of multi-island instances
  - `bash_small_inst_gen_multi_floor_ams.sh`: executes multiple times the python code `smaller_insts_gen_multi_floor.py` to generate each group of multi-floor instances
- You can also run the python codes directly, passing the desired parameters as in the scripts. For example:

    ```shell
    python3.9 smaller_insts_gen_multi_island.py --group pdptw_100_li_lim --req 10 --vehi 10 --isl 4 --mach 4 --min_mach 3 --var_cap 20 --mach_spd 1 --ams --mf greedy --pre_folder orig_ams
    ```

- For more details about the instance generator parameters, you can run:

    ```shell
    python3.9 smaller_insts_gen_multi_island.py --help
    ```

## How to run the R code (pdptw-se-statistics)

- The R scripts are used to process the experiment data and generate tables and plots for the paper.
- We recommend running each R script directly in an R environment (e.g., RStudio).
- By default, the working directory is always the root folder `pdptw-se-statistics/`. Thus, you can run each script without changing the working directory.
- For the plots, the line that saves the plot is always commented by default. You can uncomment it to save the plots in your local machine.

## Citation

Please use the citation provided by GitHub (via `CITATION.cff`).

## Questions?

For any questions, please contact Vítor A. Barbosa (<vitor.alvs.brbs@gmail.com>).
