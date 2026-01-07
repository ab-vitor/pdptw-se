library(dplyr)
library(ggplot2)
library(svglite)
library(readr)
library(tidyselect)

benchmarks <- c("benchmark_multi_island_v5","benchmark_multi_floor_v3")
benchmarks_desc <- c("Multi-island","Multi-floor")
names_regions <- c("Islands", "Floors")
variations <- c("multi_island", "multi_floor")
method_file_suff_path <- c(
  "mip_grb_valid_inequalities/official/set_01/sol_chars_form_melo.csv", 
  "multistartlp/official/set_01/sol_chars_heur_mslp.csv"
)
method_output_prefix_file_path <- c(
  "sol_chars_form_melo",
  "sol_chars_heur_mslp"
)
method_names <- c("mip_vi", "mslp")
root_dir_exp <- "official_experiments"

output_dir <- "official_experiments/data/solution_chars"

columns_max_value <- rep.int(0, 13)
columns_min_value <- rep.int(0, 13)

columns_sol_chars <- c(
  "n_vehicles_used",
  "n_machines_used",
  "max_max_load_all_vehicles",
  "min_max_load_all_vehicles",
  "mean_max_load_all_vehicles",
  "min_completion_time",
  "max_completion_time",
  "mean_completion_time",
  "avrg_machines_travel_time_with_vehicle",
  "avrg_machines_travel_time_only_with_vehicle",
  "avrg_machines_travel_time_no_vehicle",
  "avrg_vehicles_waiting_time_for_a_machine_travel",
  "avrg_vehicles_waiting_time_for_a_service"
)


columns_desc <-
  c(
    "Vehicle Utilization (%)",
    "Machine Utilization (%)",
    "Max of Maximum Capacity Utilization (%)",
    "Min of Maximum Capacity Utilization (%)",
    "Mean of Maximum Capacity Utilization (%)",
    "Minimum completion time (%)",
    "Maximum completion time (%)",
    "Mean completion time (%)",
    "Mean machine active time (%)",
    "Mean machine active time carrying a vehicle (%)",
    "Mean machine active time with dead freight (%)",
    "Mean vehicles waiting time for a machine travel (%)",
    "Mean vehicles waiting time for a service (%)"
  )

for (j in seq_along(benchmarks)) {
  benchmark <- benchmarks[j]
  var <- variations[j]
  for (l in seq_along(method_names)){
    file_name_method <- method_file_suff_path[l]
    file_path <- file.path("..", benchmark, root_dir_exp, file_name_method)
    csvr_df_complete <- read.csv(
      file = file_path,
      sep = ";"
    )
    
    csvr_df <- csvr_df_complete %>%
      mutate(
        n_reqs = substr(group, 1, 2),
        n_regions = substr(group, 9, 10),
        n_machs = substr(group, 13, 14),
        type = substr(name, 3, 3)
      ) %>%
      select(group, name, type, feasible, n_reqs, n_regions, n_machs, any_of(columns_sol_chars))
    
    df_file_name <- paste0(method_output_prefix_file_path[l], "_", var, ".csv")
    df_file_path <- file.path(output_dir, df_file_name)
    write_delim(
      csvr_df,
      file = df_file_path,
      delim = ";"
    )
    
  }
}