library(readr)
library(dplyr)

# Parameters
benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
off_exp <- "official_experiments"
mslp_prel_folder <- "multistartlp/official"
prefix_set <- file.path(off_exp, mslp_prel_folder)
csv_input_filename <- "csvresults_heur_mslp"
ext_csv <- ".csv"
exp_set <- c("set_01", "set_01")

for (j in seq_along(benchmarks)) {
  input_name <- paste0(csv_input_filename, ext_csv)
  input_path <- file.path("..", benchmarks[j], prefix_set, exp_set[j], input_name)
  csv_results <- read_delim(input_path, delim = ";")
  
  csv_results <- csv_results %>%
    mutate(across(value, ~ ifelse(is.infinite(.x), NA, .x))) %>%
    select(
      name, group, type, alpha, 
      seed, value, feasible, 
      totalTimeElapsed, fullname, n,
      iterationToBest, timeToBest, iteration,
      percentageInfeasibleSol, meanLPImprPercentage
    )
  
  ouput_name <- paste0(csv_input_filename, "_", variations[j], ext_csv)
  ouput_path <- file.path(off_exp, "data", "mslp_official", ouput_name)
  dir.create(dirname(ouput_path), showWarnings = FALSE, recursive = TRUE)

  write_delim(csv_results, ouput_path, delim = ";")
}