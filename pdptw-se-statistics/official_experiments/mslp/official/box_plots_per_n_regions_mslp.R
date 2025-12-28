library(dplyr)
library(readr)

benchmarks <- c("benchmark_multi_island_v5","benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_input_path <- "official_experiments/multistartlp/official"
input_file_name <- "csvresults_heur_mslp.csv"
ext_set <- c("set_01", "set_01")

prefix_output_path_plots <- "official_experiments/mslp/official/plots"
prefix_output_path_tables <- "official_experiments/mslp/official/tables"
set.seed(10)
for (j in seq_along(benchmarks)) {
  csv_mslpr_path <- file.path("..", benchmarks[j], prefix_input_path, ext_set[j], input_file_name)
  csv_mslpr_complete <- read.csv(file = csv_mslpr_path,sep = ";")
  
  csv_mslpr <- csv_mslpr_complete %>%
    select(fullname, group, type, percentageInfeasibleSol, meanLPImprPercentage, feasible) %>%
    mutate(
      perc_feasible = 100 - percentageInfeasibleSol,
      meanLPImprPercentage = ifelse(feasible, meanLPImprPercentage, NA),
      feasible = feasible == "true"
    ) %>%
    select(-percentageInfeasibleSol)
  
  
  csv_mslpr$type <- substr(csv_mslpr$type, 2, 2)
  csv_mslpr$n_regions <- substr(csv_mslpr$group, 9, 10)
  
  count_csv_mslpr <- csv_mslpr %>%
    group_by(n_regions) %>%
    summarise(
      count_obs_type1 = sum(!is.na(meanLPImprPercentage) & type == "1"),
      count_obs_type2 = sum(!is.na(meanLPImprPercentage) & type == "2"),
      .groups = "drop"
    )
  
  output_filename <- paste0("table_counts_obs_per_n_regions_and_instance_lp_impr_", variations[j], "_mslp.csv")
  file_path <- file.path(
      prefix_output_path_tables,
      "n_regions",
      output_filename
    )
  write_delim(count_csv_mslpr, file = file_path, delim = ";")

  p <-
    ggplot(
      csv_mslpr,
      aes(
        x = as.factor(type),
        y = perc_feasible,
        group = interaction(type, n_regions),
        fill = n_regions
      )
    ) +
    geom_boxplot() +
    labs(x = "Type",
         y = "Feasible solutions (%)",
         fill = "Num. of regions") +
    scale_color_brewer(palette = "Set1") +
    theme(legend.position = "top", text = element_text(size = 14)) +
    coord_cartesian(ylim = c(0, 100)) +
    scale_y_continuous(
      breaks = seq(0, 100, by = round(10, digits = 0))
    )
  
  print(p)
  
  output_filename <- paste0("plot_feas_sol_perc_vs_n_regions_and_instance_", variations[j], "_mslp.pdf")
  file_path <- file.path(
      prefix_output_path_plots,
      "n_regions",
      output_filename
    )
  ggsave(file_path, plot = p, width = 5, height = 4)
  
  p <-
    ggplot(
      csv_mslpr,
      aes(
        x = as.factor(type),
        y = meanLPImprPercentage,
        group = interaction(type, n_regions),
        fill = n_regions
      )
    ) +
    geom_boxplot() +
    labs(x = "Type",
         y = "Mean LP improvement (%)",
         fill = "Num. of regions") +
    scale_color_brewer(palette = "Set1") +
    theme(legend.position = "top", text = element_text(size = 14)) +
    coord_cartesian(ylim = c(0, 45)) +
    scale_y_continuous(breaks = seq(0,
                                    45,
                                    by = round(5, digits = 0)))
  
  print(p)
  
  output_filename <- paste0("plot_mean_lp_impr_vs_n_regions_and_instance_", variations[j], "_mslp.pdf")
  file_path <- file.path(
      prefix_output_path_plots,
      "n_regions",
      output_filename
    )
  ggsave(file_path, plot = p, width = 5, height = 4)
}
