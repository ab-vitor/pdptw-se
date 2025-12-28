library(dplyr)

# Parameters
benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_set <- "official_experiments/multistartlp/official"
csv_input_filename <- "csvresults_heur_mslp.csv"
prefix_output_1 <- "grouped_avrg_group_instname_alpha"
prefix_output_2 <- "grouped_avrg_alpha"
exp_set <- c("set_01", "set_01")


# Loop over all benchmarks
for (j in seq_along(benchmarks)) {
  # --- Input ---
  input_path <- file.path("..", benchmarks[j], prefix_set, exp_set[j], csv_input_filename)
  csv_results_complete <- read.csv(input_path, sep = ";")
  
  csv_results <- csv_results_complete %>%
    select(name, group, type, alpha, seed, value, feasible, totalTimeElapsed, fullname)
  
  csv_results <- csv_results %>%
    mutate(
      n_req = as.numeric(substr(group, 1, 2)),
      n_reg = as.numeric(substr(group, 9, 10)),
      n_mach = as.numeric(substr(group, 13, 14))
    )
  
  group_by_seed <- csv_results %>%
    group_by(seed) %>%
    summarise(
      count = n()
    )
  
  group_by_seed <- csv_results %>%
    group_by(seed) %>%
    summarise(
      count = n()
    )
  
  group_by_type <- csv_results %>%
    group_by(type) %>%
    summarise(
      count = n()
    )
  
  group_by_n_req <- csv_results %>%
    group_by(n_req) %>%
    summarise(
      count = n()
    )

  group_by_n_regs <- csv_results %>%
    group_by(n_reg) %>%
    summarise(
      count = n()
    )

  group_by_n_machs <- csv_results %>%
    group_by(n_mach) %>%
    summarise(
      count = n()
    )
}
