library(dplyr)

# Refactored by chat-gpt

# Parameters
variations <- c("multi_island", "multi_floor")
prefix_set <- "official_experiments/data/mslp_preliminary"
prefix_csv_input_filename <- "csvresults_heur_mslp"
prefix_output_1 <- "grouped_avrg_group_instname_alpha"
prefix_output_2 <- "grouped_avrg_alpha"

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
      minrpd = if (all(is.na(value))) NA else min(rpd),
      meanrpd = if (all(is.na(value))) NA else mean(rpd),
      maxrpd = if (all(is.na(value))) NA else max(rpd),
      .groups = "drop"
    )
}

# Helper to aggregate by alpha
aggregate_by_alpha <- function(data) {
  data %>%
    group_by(alpha) %>%
    summarise(
      mean_minrpd = mean(minrpd, na.rm = TRUE),
      mean_meanrpd = mean(meanrpd, na.rm = TRUE),
      mean_maxrpd = mean(maxrpd, na.rm = TRUE),
      sd_minrpd = sd(minrpd, na.rm = TRUE),
      sd_meanrpd = sd(meanrpd, na.rm = TRUE),
      sd_maxrpd = sd(maxrpd, na.rm = TRUE),
      .groups = "drop"
    )
}

# Loop over all variations
for (j in seq_along(variations)) {
  # --- Input ---
  csv_input_filename <- paste0(prefix_csv_input_filename, "_", variations[j], ".csv")
  input_path <- file.path(prefix_set, csv_input_filename)
  csv_results <- read.csv(input_path, sep = ";")
  
  csv_results <- csv_results %>%
    mutate(across(value, ~ ifelse(is.infinite(.x), NA, .x))) %>%
    select(full_name, type, alpha, seed, value, feasible)
  
  csv_results_minbestsol <- csv_results %>%
    group_by(full_name, type) %>%
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
  
  # --- Group by full_name, type, alpha ---
  grouped_full <- compute_grouped_stats(csv_results_rpd, c("full_name", "type", "alpha"))
  
  # Separate by type
  grouped_t1 <- grouped_full %>% filter(type == "t1")
  grouped_t2 <- grouped_full %>% filter(type == "t2")
  
  # --- Output base paths ---
  output_base_1 <- file.path(prefix_set, "grouped", prefix_output_1)
  output_base_2 <- file.path(prefix_set, "grouped", prefix_output_2)
  dir.create(dirname(output_base_1), showWarnings = FALSE, recursive = TRUE)
  dir.create(dirname(output_base_2), showWarnings = FALSE, recursive = TRUE)
    
  # --- Write grouped by full_name/type/alpha ---
  write_csv(grouped_full, paste0(output_base_1, "_", variations[j], ".csv"))
  write_csv(grouped_t1, paste0(output_base_1, "_type_1_", variations[j], ".csv"))
  write_csv(grouped_t2, paste0(output_base_1, "_type_2_", variations[j], ".csv"))
  
  # --- Aggregate by alpha ---
  grouped_alpha_all <- aggregate_by_alpha(grouped_full)
  grouped_alpha_t1 <- aggregate_by_alpha(grouped_t1)
  grouped_alpha_t2 <- aggregate_by_alpha(grouped_t2)
  
  # --- Write aggregated results ---
  write_csv(grouped_alpha_all, paste0(output_base_2, "_", variations[j], ".csv"))
  write_csv(grouped_alpha_t1, paste0(output_base_2, "_type_1_", variations[j], ".csv"))
  write_csv(grouped_alpha_t2, paste0(output_base_2, "_type_2_", variations[j], ".csv"))
}
