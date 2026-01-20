library(dplyr)
library(knitr)
library(kableExtra)
library(tibble)
library(readr)
library(stringr)

variations <- c("multi_island", "multi_floor")
prefix_file_name <- "csvresults_form_mip"
prefix_set_with_vi <- "official_experiments/data/mip_grb_valid_inequalities/official"
prefix_set_no_vi <- "official_experiments/data/mip_gurobi"
prefix_output <- "official_experiments/mip_grb_vi/benchmark_tests/comparison_mip_grb"
prefix_output_file_name <- "csvresults_form_mip.csv"

post_process <- function(df) {
  df <- df %>%
    rename_with(~ sub("(_grb)+$", "", .x))
  
  df <- df %>%
    select(
      name, group, type, full_name, 
      time, gap, obj_value, status, 
      tle_feas, tle_not_feas, optimal,
      constraints_used_mip_str
    ) %>%
    mutate(
      found_sol = pmax(optimal, tle_feas), 
      killed = ifelse(status == 11, 1, 0), 
      tle = pmax(tle_feas, tle_not_feas)
    ) %>%
    rename(vi_config = constraints_used_mip_str)
  
  
  df
}

csv_results_variations <- list()
for (j in seq_along(variations)) {
  file_name <- paste0(prefix_file_name, "_", variations[j], ".csv")
  file_path <- file.path(prefix_set_no_vi, file_name)
  csv_results_no_vi <-
    read.csv(
      file = file_path,
      sep = ";"
    ) |> post_process()
  
  file_name <- paste0(prefix_file_name, "_", variations[j], ".csv")
  file_path <- file.path(prefix_set_with_vi, file_name)
  csv_results_with_vi <-
    read.csv(
      file = file_path,
      sep = ";"
    ) |> post_process()
  
  csv_results <- rbind(csv_results_no_vi, csv_results_with_vi)
  
  csv_results <- csv_results %>%
    mutate(
      variation = variations[j]
    )
  
  csv_results_variations[[variations[j]]] = csv_results
}

csv_results <- rbind(csv_results_variations[["multi_island"]], csv_results_variations[["multi_floor"]])

best_per_instance <- csv_results %>%
  group_by(full_name) %>%
  summarise(
    best_obj = min(obj_value, na.rm = TRUE),
    found_sol_total = sum(found_sol),
    both_found_sol = ifelse(found_sol_total == 2, 1, 0)
  )

csv_results <- csv_results %>%
  left_join(best_per_instance, by = "full_name") %>%
  mutate(
    gap = ifelse(is.na(gap), 100.0, gap),
    rpd = ifelse(obj_value == Inf, 100.0, round(100*(obj_value - best_obj) / best_obj, digits = 2))
  )


summarise_by_var_and_type <- function(df, var, t) {
  df_filtered <- df %>%
    filter(variation == var & type == t)
  
  df_summary <- df_filtered %>%
    group_by(vi_config) %>%
    summarise(
      # avg_gap = mean(gap[both_found_sol == 1]),
      # arpd = mean(rpd[both_found_sol == 1]),
      # avg_time = mean(time[both_found_sol == 1]),
      opt = sum(optimal),
      tle = sum(tle),
      killed = sum(killed),
      feas = sum(found_sol)
    ) %>%
    mutate(
      vi_config = case_when(
        vi_config == "1-29" ~ "None",
        TRUE ~ str_replace(vi_config, "^1-29,", "")
      )
    ) %>%
    mutate(
      vi_config = str_replace_all(
        vi_config,
        "(\\d+)",
        "(\\1)"
      )
    ) %>%
    arrange(vi_config)
  
  df_summary
}

comparison_summary_multi_island_t1 <- summarise_by_var_and_type(csv_results, "multi_island", "t1")
comparison_summary_multi_island_t2 <- summarise_by_var_and_type(csv_results, "multi_island", "t2")
comparison_summary_multi_floor_t1 <- summarise_by_var_and_type(csv_results, "multi_floor", "t1")
comparison_summary_multi_floor_t2 <- summarise_by_var_and_type(csv_results, "multi_floor", "t2")

save_df <- function(df, pref, var, type) {
  file_name <- paste0(paste("comparison_summary", var, type,  sep = "_"), ".csv")
  file_path <- file.path(pref, file_name)
  write_delim(
    df,
    file = file_path,
    delim = ";"
  )
}

save_df(comparison_summary_multi_island_t1, prefix_output, "multi_island", "t1")
save_df(comparison_summary_multi_island_t2, prefix_output, "multi_island", "t2")
save_df(comparison_summary_multi_floor_t1, prefix_output, "multi_floor", "t1")
save_df(comparison_summary_multi_floor_t2, prefix_output, "multi_floor", "t2")
