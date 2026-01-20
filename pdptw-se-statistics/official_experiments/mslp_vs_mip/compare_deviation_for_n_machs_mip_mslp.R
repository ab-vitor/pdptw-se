library(dplyr)
library(tidyr)
library(readr)

variations <- c("multi_island", "multi_floor")

prefix_input_path_mipr <- "official_experiments/data/mip_gurobi/csvresults_form_mip"
prefix_input_path_mipvir <- "official_experiments/data/mip_grb_valid_inequalities/official/csvresults_form_mip"
prefix_input_path_mslpr <- "official_experiments/data/mslp_official/csvresults_heur_mslp"

prefix_output_path <- "official_experiments/mslp_vs_mip/tables_mach_sens_analysis"

for (j in seq_along(variations)) {
  var <- variations[j]
  csv_mipr <- read.csv(
    file = paste0(prefix_input_path_mipr, "_", var, ".csv"),
    sep = ";"
  )
  csv_mipvir <- read.csv(
    file = paste0(prefix_input_path_mipvir, "_", var, ".csv"),
    sep = ";"
  )
  csv_mslpr <- read.csv(
    file = paste0(prefix_input_path_mslpr, "_", var, ".csv"),
    sep = ";"
  )
  
  csv_miprf <- csv_mipr %>%
    select(full_name, name, group, obj_value_grb) %>%
    rename(mip_sol = obj_value_grb)
  
  csv_mipvirf <- csv_mipvir %>%
    select(full_name, name, group, obj_value) %>%
    rename(mip_vi_sol = obj_value)
  
  csv_mslprf <- csv_mslpr %>%
    select(full_name, name, group, value) %>%
    rename(mslp_sol = value, full_name = full_name) %>%
    group_by(full_name, name, group) %>%
    summarise(mslp_min_sol = min(mslp_sol), .groups = "drop")
  
  
  
  csv_results <- csv_mslprf %>%
    left_join(csv_miprf, by = c("full_name", "group", "name")) %>%
    left_join(csv_mipvirf, by = c("full_name", "group", "name")) %>%
    mutate(
      best_sol = pmin(mip_sol, mip_vi_sol, mslp_min_sol, na.rm = T),
      mip_sol = ifelse(is.infinite(mip_sol), NA, mip_sol),
      mip_vi_sol = ifelse(is.infinite(mip_vi_sol), NA, mip_vi_sol),
    )

  
  
  grouped_inst <-
    csv_results %>%
    separate(group,
              into = c("req", "vehi", "reg", "M"),
              sep = "_")
  

  grouped_inst_spread <- grouped_inst %>%
    pivot_wider(names_from = M, values_from = best_sol)
  
  group_inst_unite <- grouped_inst_spread %>%
    unite("group", req, vehi, reg, sep = "_") %>%
    select(name, group, `03M`, `04M`, `05M`, `06M`) %>%
    mutate(
      min_machs = pmin(`03M`, `05M`, na.rm = T),
      max_machs = pmin(`04M`, `06M`, na.rm = T)
    )

  
  group_inst_merge_machines <- group_inst_unite %>%
    group_by(name, group) %>%
    summarise(
      min_machs = if (all(is.na(min_machs))) NA_real_ else min(min_machs, na.rm = TRUE),
      max_machs = if (all(is.na(max_machs))) NA_real_ else min(max_machs, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      min_machs = ifelse(is.infinite(min_machs), NA, min_machs),
      max_machs = ifelse(is.infinite(max_machs), NA, max_machs)
    )
  
  grouped_inst_dev <- group_inst_merge_machines %>%
    mutate(deviation = (min_machs - max_machs) / min_machs * 100)
  
  output_table_file_name <- paste0("grouped_inst_dev_", var, ".csv")
  output_table_path <- file.path(prefix_output_path, output_table_file_name)
  write_delim(
    grouped_inst_dev,
    file = output_table_path,
    delim = ";"
  )
  
  grouped_mean_dev <-
    grouped_inst_dev %>%
    group_by(group) %>%
    summarise(mean_deviation = mean(deviation))
  
  output_table_file_name <- paste0("grouped_mean_dev_", var, ".csv")
  output_table_path <- file.path(prefix_output_path, output_table_file_name)
  write_delim(
    grouped_mean_dev,
    file = output_table_path,
    delim = ";"
  )
    
}
