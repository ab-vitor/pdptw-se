library(dplyr)
library(knitr)
library(kableExtra)
library(tibble)
library(readr)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
file_name <- "grouped_abs.csv"
prefix_set_with_vi <- "official_experiments/mip_grb_valid_inequalities/official"
prefix_set_no_vi <- "official_experiments/mip_gurobi"
prefix_output <- "official_experiments/mip_grb_vi/benchmark_tests/comparison_mip_grb"
prefix_output_file_name <- "grouped_abs_imprv"

for (j in seq_along(benchmarks)) {
  file_path <- file.path("..", benchmarks[j], prefix_set_no_vi, "set_02", file_name)
  grouped_abs_no_vi <-
    read.csv(
      file = file_path,
      sep = ";"
    )
  
  grouped_abs_no_vi <- grouped_abs_no_vi %>%
    rename(
      Optimal_t1_no_vi = Optimal,
      TLE_t1_no_vi = TLE,
      Killed_t1_no_vi = Killed,
      Feas_Sol_t1_no_vi = Feas..Sol.,
      Optimal_t2_no_vi = Optimal_1,
      TLE_t2_no_vi = TLE_1,
      Killed_t2_no_vi = Killed_1,
      Feas_Sol_t2_no_vi = Feas..Sol._1,
    )
  
  file_path <- file.path("..", benchmarks[j], prefix_set_with_vi, "set_01", file_name)
  grouped_abs_with_vi <-
    read.csv(
      file = file_path,
      sep = ";"
    )
  
  grouped_abs_with_vi <- grouped_abs_with_vi %>%
    rename(
      Optimal_t1_with_vi = Optimal,
      TLE_t1_with_vi = TLE,
      Killed_t1_with_vi = Killed,
      Feas_Sol_t1_with_vi = Feas..Sol.,
      Optimal_t2_with_vi = Optimal_1,
      TLE_t2_with_vi = TLE_1,
      Killed_t2_with_vi = Killed_1,
      Feas_Sol_t2_with_vi = Feas..Sol._1,
    )
  
  grouped_abs_comparison <- grouped_abs_no_vi %>%
    left_join(grouped_abs_with_vi, by = c("group", "space1", "space2"))
  
  grouped_abs_comparison <- grouped_abs_comparison %>%
    mutate(
      Optimal_t1_impr = Optimal_t1_with_vi - Optimal_t1_no_vi,
      TLE_t1_impr = -(TLE_t1_with_vi - TLE_t1_no_vi),
      Killed_t1_impr = -(Killed_t1_with_vi - Killed_t1_no_vi),
      Feas_Sol_t1_impr = Feas_Sol_t1_with_vi - Feas_Sol_t1_no_vi,
      Optimal_t2_impr = Optimal_t2_with_vi - Optimal_t2_no_vi,
      TLE_t2_impr = -(TLE_t2_with_vi - TLE_t2_no_vi),
      Killed_t2_impr = -(Killed_t2_with_vi - Killed_t2_no_vi),
      Feas_Sol_t2_impr = Feas_Sol_t2_with_vi - Feas_Sol_t2_no_vi
    ) %>%
    select(
      group, space1,
      Optimal_t1_impr, TLE_t1_impr, Killed_t1_impr, Feas_Sol_t1_impr,
      space2,
      Optimal_t2_impr, TLE_t2_impr, Killed_t2_impr, Feas_Sol_t2_impr
    )
  
  output_file_name <- paste0(prefix_output_file_name, "_", variations[j], ".csv")
  output_file_path <- file.path(prefix_output, output_file_name)
  write_delim(
    grouped_abs_comparison,
    file = output_file_path,
    delim = ";"
  )
  
}