library(dplyr)
library(readr)

benchmarks <-
  c(
    "benchmark_multi_island_v5",
    "benchmark_multi_floor_v3"
  )
variations <- c("I5", "F3")
prefix_path_mip <- "official_experiments/mip_grb_valid_inequalities/official"
prefix_path_mslp <- "official_experiments/multistartlp/official"
sets <- c("set_01", "set_01", "set_01", "set_01")

mip_input_name <- "csvresults_form_melo.csv"
mslp_input_name <- "csvresults_heur_mslp.csv"

prefix_output_tables <- "official_experiments/mslp_vs_mip/tables"
prefix_output_plots <- "official_experiments/mslp_vs_mip/plots"
set.seed(10)

for (j in 1:2) {
  k <- j + 2
  var <- variations[j]
  mip_input_path <- file.path(
    "..",
    benchmarks[j],
    prefix_path_mip,
    sets[j],
    mip_input_name
  )
  csvr_mip_complete <-
    read.csv(
      file = mip_input_path,
      sep = ";"
    )
  
  csvr_mip <- csvr_mip_complete %>%
    select(full_name, group, type, obj_value)
  
  mslp_input_path <- file.path(
    "..",
    benchmarks[j],
    prefix_path_mslp,
    sets[k],
    mslp_input_name
  )
  csvr_mslp_complete <-
    read.csv(
      file = mslp_input_path,
      sep = ";"
    )
  
  csvr_mslp <- csvr_mslp_complete %>%
    select(
      fullname, group, type, value,
      iteration, iterationToBest, timeToBest, 
      totalTimeElapsed, seed, n, feasible
    ) %>%
    rename(full_name = fullname) %>%
    filter(n <= 12)
  
  grouped_avrg_group_instname_mslp <- csvr_mslp %>%
    group_by(full_name, group, type) %>%
    summarise(
      minbestsol = min(value, na.rm = T),
      meanbestsol = mean(value, na.rm = T),
      .groups = "drop"
    )
  
  csvr_mip_mslp <-
    left_join(csvr_mip,
              grouped_avrg_group_instname_mslp,
              by = c("full_name", "group", "type"))
  
  
  csvr_mip_mslp <- csvr_mip_mslp %>%
    select(full_name, type, group, obj_value, minbestsol, meanbestsol) %>%
    rename(
      mip_sol = obj_value,
      mslp_min_sol = minbestsol,
      mslp_mean_sol = meanbestsol
    ) %>%
    mutate(
      mip_sol = ifelse(is.infinite(mip_sol), NA, mip_sol)
    )
  
  csvr_mip_mslp <- csvr_mip_mslp %>%
    mutate(
      dev_mip_mslp_minbs = (mslp_min_sol - mip_sol) / mip_sol * 100,
      dev_mip_mslp_meanbs = (mslp_mean_sol - mip_sol) / mip_sol * 100
    )
  
  
  csvr_mip_mslp_na_count_table <- csvr_mip_mslp %>%
    mutate(
      missing_one = if_else(is.na(dev_mip_mslp_minbs), 1, 0)
    )
  
  na_count_table_sol <- csvr_mip_mslp_na_count_table %>%
    group_by(type) %>%
    summarise(
      missing_one = sum(missing_one)
    )
  
  na_count_table_sol <- na_count_table_sol %>%
    mutate(variation = var) %>%
    select(type, missing_one, variation)
  
  output_file_name <- paste0("na_count_dev_obj_", var, ".csv")
  output_file_path <- file.path(prefix_output_tables, output_file_name)
  write_delim(
    na_count_table_sol,
    file = output_file_path,
    delim = ";"
  )
  
  csvr_mip_mslp$type <- substr(csvr_mip_mslp$type, 2, 2)
  
  p <- ggplot(csvr_mip_mslp, aes(x = type, y = dev_mip_mslp_minbs)) +
    geom_boxplot(outlier.shape = NA) +
    geom_point(
      aes(x = type, y = dev_mip_mslp_minbs),
      shape = 21,
      position = position_jitter(width = 0.2, height = 0),
      alpha = 0.5,
    ) +
    labs(x = "Type", y = "Sol. deviation (%)") +
    scale_y_continuous(
      limits = c(-20, 25),
      breaks = seq(-20, 25, by=5),
    )
  
  print(p)
  
  # ggsave_filename <- paste0("box_plots_sol_dev_mip_mslp_", var, ".pdf")
  # ggsave_filepath <- file.path(prefix_output_plots, ggsave_filename)
  # ggsave(ggsave_filepath, plot = p, width = 5, height = 4)
}
