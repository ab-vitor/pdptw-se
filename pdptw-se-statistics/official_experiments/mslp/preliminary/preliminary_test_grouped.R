library(dplyr)

# Refactored by chat-gpt

# Parameters
benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_set <- "official_experiments/multistartlp/preliminar"
csv_input_filename <- "csvresults_heur_mslp.csv"
prefix_output_1 <- "grouped_avrg_group_instname_alpha"
prefix_output_2 <- "grouped_avrg_alpha"
exp_set <- c("set_01", "set_01")

# Helper to write CSVs
write_csv <- function(data, filepath) {
  write.table(
    data,
    filepath,
    sep = ";",
    dec = ".",
    quote = FALSE,
    row.names = FALSE
  )
}

# Helper to compute grouped averages
compute_grouped_stats <- function(data, group_vars) {
  data %>%
    group_by(across(all_of(group_vars))) %>%
    summarise(
      feasible = sum(feasible == "true"),
      # minbestsol = if (all(is.na(value))) NA else min(value),
      # maxbestsol = if (all(is.na(value))) NA else max(value),
      # meanbestsol = if (all(is.na(value))) NA else mean(value),
      minrpd = if (all(is.na(value))) NA else min(rpd),
      meanrpd = if (all(is.na(value))) NA else mean(rpd),
      maxrpd = if (all(is.na(value))) NA else max(rpd),
      # iterations = mean(iteration, na.rm = TRUE),
      # miniterationtobest = min(iterationToBest, na.rm = TRUE),
      # maxiterationtobest = max(iterationToBest, na.rm = TRUE),
      # meaniterationtobest = mean(iterationToBest, na.rm = TRUE),
      # percentage_infeas_sol = mean(percentageInfeasibleSol, na.rm = TRUE),
      # percentage_LP_impr = mean(percentageLPImpr, na.rm = TRUE),
      # mean_LP_impr_percentage = mean(meanLPImprPercentage, na.rm = TRUE),
      # totalTimeElapsed = mean(totalTimeElapsed, na.rm = TRUE),
      # timeToBest = mean(timeToBest, na.rm = TRUE),
      .groups = "drop"
    )
}

# Helper to aggregate by alpha
aggregate_by_alpha <- function(data) {
  data %>%
    group_by(alpha) %>%
    summarise(
      # mean_minbestsol = mean(minbestsol, na.rm = TRUE),
      # mean_maxbestsol = mean(maxbestsol, na.rm = TRUE),
      # mean_meanbestsol = mean(meanbestsol, na.rm = TRUE),
      mean_minrpd = mean(minrpd, na.rm = TRUE),
      mean_meanrpd = mean(meanrpd, na.rm = TRUE),
      mean_maxrpd = mean(maxrpd, na.rm = TRUE),
      sd_minrpd = sd(minrpd, na.rm = TRUE),
      sd_meanrpd = sd(meanrpd, na.rm = TRUE),
      sd_maxrpd = sd(maxrpd, na.rm = TRUE),
      # iterations = mean(iterations, na.rm = TRUE),
      # mean_miniterationtobest = mean(miniterationtobest, na.rm = TRUE),
      # mean_maxiterationtobest = max(maxiterationtobest, na.rm = TRUE),
      # mean_meaniterationtobest = mean(meaniterationtobest, na.rm = TRUE),
      # percentage_infeas_sol = mean(percentage_infeas_sol, na.rm = TRUE),
      # percentage_LP_impr = mean(percentage_LP_impr, na.rm = TRUE),
      # mean_LP_impr_percentage = mean(mean_LP_impr_percentage, na.rm = TRUE),
      # totalTimeElapsed = mean(totalTimeElapsed, na.rm = TRUE),
      # timeToBest = mean(timeToBest, na.rm = TRUE),
      .groups = "drop"
    )
}

# Loop over all benchmarks
for (j in seq_along(benchmarks)) {
  # --- Input ---
  input_path <- file.path("..", benchmarks[j], prefix_set, exp_set[j], csv_input_filename)
  csv_results <- read.csv(input_path, sep = ";")
  
  csv_results <- csv_results %>%
    mutate(across(value, ~ ifelse(is.infinite(.x), NA, .x))) %>%
    select(fullname, type, alpha, seed, value, feasible)
  
  csv_results_minbestsol <- csv_results %>%
    group_by(fullname, type) %>%
    mutate(
      minbestsol = if (all(is.na(value))) NA else min(value)
    ) %>%
    ungroup()
    
  csv_results_rpd <- csv_results_minbestsol %>%
    mutate(
      rpd = if_else(
        is.na(value) | is.na(minbestsol),
        NA,
        100*(value - minbestsol) / minbestsol
      )
    )
  
  # --- Group by fullname, type, alpha ---
  grouped_full <- compute_grouped_stats(csv_results_rpd, c("fullname", "type", "alpha"))
  
  # Separate by type
  grouped_t1 <- grouped_full %>% filter(type == "t1")
  grouped_t2 <- grouped_full %>% filter(type == "t2")
  
  # --- Output base paths ---
  output_base_1 <- file.path("..", benchmarks[j], prefix_set, exp_set[j], prefix_output_1)
  output_base_2 <- file.path("..", benchmarks[j], prefix_set, exp_set[j], prefix_output_2)
  
  # --- Write grouped by fullname/type/alpha ---
  write_csv(grouped_full, paste0(output_base_1, ".csv"))
  write_csv(grouped_t1, paste0(output_base_1, "_type_1.csv"))
  write_csv(grouped_t2, paste0(output_base_1, "_type_2.csv"))
  
  # --- Aggregate by alpha ---
  grouped_alpha_all <- aggregate_by_alpha(grouped_full)
  grouped_alpha_t1 <- aggregate_by_alpha(grouped_t1)
  grouped_alpha_t2 <- aggregate_by_alpha(grouped_t2)
  
  # --- Write aggregated results ---
  write_csv(grouped_alpha_all, paste0(output_base_2, ".csv"))
  write_csv(grouped_alpha_t1, paste0(output_base_2, "_type_1.csv"))
  write_csv(grouped_alpha_t2, paste0(output_base_2, "_type_2.csv"))
}
