library(dplyr)
library(knitr)
library(kableExtra)
library(tibble)
library(readr)
library(ggplot2)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
file_name <- "csvresults_form_melo.csv"
prefix_set_with_vi <- "official_experiments/mip_grb_valid_inequalities/official"
prefix_set_no_vi <- "official_experiments/mip_gurobi"
prefix_output_plots <- "official_experiments/mip_grb_vi/benchmark_tests/comparison_mip_grb/plots"
prefix_output_tables <- "official_experiments/mip_grb_vi/benchmark_tests/comparison_mip_grb/tables"

post_process <- function(df, suff) {
  obj_col <- paste("obj_value", suff, sep = "_")
  gap_col <- paste("gap", suff, sep = "_")
  df <- df %>%
    mutate(
      found_sol = pmax(optimal, tle_feas),
      !!obj_col := ifelse(found_sol == 1, obj_value, NA),
      # !!gap_col := ifelse(found_sol == 1, gap, NA),
      !!gap_col := ifelse(tle_feas == 1, gap, NA),
      type = substr(type, 2, 2)
    ) %>%
    select(
      full_name, group, type, obj_col, gap_col
    )
  df
}

for (j in seq_along(benchmarks)) {
  file_path <- file.path("..", benchmarks[j], prefix_set_no_vi, "set_02", file_name)
  csv_results_no_vi <-
    read.csv(
      file = file_path,
      sep = ";"
    ) |> post_process(suff = "no_vi")
  
  file_path <- file.path("..", benchmarks[j], prefix_set_with_vi, "set_01", file_name)
  csv_results_with_vi <-
    read.csv(
      file = file_path,
      sep = ";"
    ) |> post_process(suff = "with_vi")
  
  csv_results <- csv_results_no_vi %>%
    left_join(csv_results_with_vi, by = c("full_name", "group", "type"))
  
  csv_results <- csv_results %>%
    mutate(
      dev_obj = ifelse(
        !is.na(obj_value_no_vi) & !is.na(obj_value_with_vi), 
        round((obj_value_with_vi - obj_value_no_vi) / obj_value_no_vi * 100, digits = 2), 
        NA
      ),
      dev_gap = ifelse(
        !is.na(gap_no_vi) & !is.na(gap_with_vi), 
        round((gap_with_vi - gap_no_vi) / ifelse(gap_no_vi==0, 1, gap_no_vi) * 100, digits = 2), 
        NA
      ),
      n_reqs = substr(group, 1, 2)
    )
  
  csv_results_sol <- csv_results %>%
    mutate(
      only_missing_no_vi = if_else(is.na(obj_value_no_vi) & !is.na(obj_value_with_vi), 1, 0),
      only_missing_with_vi = if_else(is.na(obj_value_with_vi) & !is.na(obj_value_no_vi), 1, 0),
      missing_both = if_else(is.na(obj_value_no_vi) & is.na(obj_value_with_vi), 1, 0),
      missing_one = if_else(is.na(dev_obj), 1, 0)
    )

  na_count_table_sol <- csv_results_sol %>%
    group_by(type) %>%
    summarise(
      only_missing_no_vi = sum(only_missing_no_vi),
      only_missing_with_vi = sum(only_missing_with_vi),
      missing_both = sum(missing_both),
      missing_one = sum(missing_one)
    )
  
  na_count_table_sol <- na_count_table_sol %>%
    mutate(variation = variations[j]) %>%
    select(type, missing_one, missing_both, only_missing_no_vi, only_missing_with_vi, variation)
  
  output_file_name <- paste0("na_count_dev_obj_", variations[j], ".csv")
  output_file_path <- file.path(prefix_output_tables, output_file_name)
  write_delim(
    na_count_table_sol,
    file = output_file_path,
    delim = ";"
  )

  #############
  csv_results_gap <- csv_results %>%
    mutate(
      only_missing_no_vi = if_else(is.na(gap_no_vi) & !is.na(gap_with_vi), 1, 0),
      only_missing_with_vi = if_else(is.na(gap_with_vi) & !is.na(gap_no_vi), 1, 0),
      missing_both = if_else(is.na(gap_no_vi) & is.na(gap_with_vi), 1, 0),
      missing_one = if_else(is.na(dev_gap), 1, 0)
    )

  na_count_table_gap <- csv_results_gap %>%
    group_by(type) %>%
    summarise(
      only_missing_no_vi = sum(only_missing_no_vi),
      only_missing_with_vi = sum(only_missing_with_vi),
      missing_both = sum(missing_both),
      missing_one = sum(missing_one)
    )
  
  na_count_table_gap <- na_count_table_gap %>%
    mutate(variation = variations[j]) %>%
    select(type, missing_one, missing_both, only_missing_no_vi, only_missing_with_vi, variation)
  
  output_file_name <- paste0("na_count_dev_gap_", variations[j], ".csv")
  output_file_path <- file.path(prefix_output_tables, output_file_name)
  write_delim(
    na_count_table_gap,
    file = output_file_path,
    delim = ";"
  )

  
  
  p <- ggplot(csv_results, aes(x = type, y = dev_obj, fill=n_reqs, group = as.factor(interaction(type, n_reqs)))) +
    geom_boxplot(outlier.shape = NA) +
    # geom_point(
    #   aes(x = type, y = dev_obj, group = interaction(type, n_reqs)),
    #   shape = 21,
    #   position = position_jitter(width = 0.2, height = 0),
    #   alpha = 0.5
    # ) +
    labs(x = "Type", y = "Sol. deviation (%)", fill = "Num. of reqs.") +
    scale_color_brewer(palette = "Set1") +
    theme(legend.position = "top", text = element_text(size = 13)) +
    scale_y_continuous(
      limits = c(-10, 10),
      breaks = seq(-10, 10, by=2),
    )
  
  print(p)
  
  ggsave_filename <- paste0("box_plots_sol_dev_with_vi_no_vi_", variations[j], "_by_n_reqs.pdf")
  ggsave_filepath <- file.path(prefix_output_plots, ggsave_filename)
  # ggsave(ggsave_filepath, plot = p, width = 5, height = 4)
   
  p <- ggplot(csv_results, aes(x = type, y = dev_gap, fill=n_reqs, group = as.factor(interaction(type, n_reqs)))) +
    geom_boxplot(outlier.shape = NA) +
    # geom_point(
    #   aes(x = type, y = dev_gap, group = interaction(type, n_reqs)),
    #   shape = 21,
    #   position = position_jitter(width = 0.2, height = 0),
    #   alpha = 0.5
    # ) +
    labs(x = "Type", y = "Gap deviation (%)", fill = "Num. of reqs.") +
    scale_color_brewer(palette = "Set1") +
    theme(legend.position = "top", text = element_text(size = 13)) +
    scale_y_continuous(
      limits = c(-100, 100),
      breaks = seq(-100, 100, by=20),
    )
  print(p)
  ggsave_filename <- paste0("box_plots_gap_dev_with_vi_no_vi_", variations[j], "_by_n_reqs.pdf")
  ggsave_filepath <- file.path(prefix_output_plots, ggsave_filename)
  # ggsave(ggsave_filepath, plot = p, width = 5, height = 4)
}




