library(dplyr)
library(readr)

variations <- c("multi_island", "multi_floor")
prefix_input_path <- "official_experiments/data/mslp_official"
prefix_input_file_name <- "csvresults_heur_mslp"

prefix_output_path_plots <- "official_experiments/mslp/official/plots"
prefix_output_path_tables <- "official_experiments/mslp/official/tables"
set.seed(10)
for (j in seq_along(variations)) {
  input_file_name <- paste0(prefix_input_file_name, "_", variations[j], ".csv")
  csv_mslpr_path <- file.path(prefix_input_path, input_file_name)
  csv_mslpr_complete <- read.csv(file = csv_mslpr_path,sep = ";")
  
  csv_mslpr <- csv_mslpr_complete %>%
    mutate(
      perc_feasible = 100 - percentage_infeasible_sol,
      mean_LP_impr_percentage = ifelse(feasible, mean_LP_impr_percentage, NA),
      feasible = feasible == "true"
    ) %>%
    select(-percentage_infeasible_sol)
  
  
  csv_mslpr$type <- substr(csv_mslpr$type, 2, 2)
  csv_mslpr$n_machs <- substr(csv_mslpr$group, 13, 14)
  
  count_csv_mslpr <- csv_mslpr %>%
    group_by(n_machs) %>%
    summarise(
      count_obs_type1 = sum(!is.na(mean_LP_impr_percentage) & type == "1"),
      count_obs_type2 = sum(!is.na(mean_LP_impr_percentage) & type == "2"),
      .groups = "drop"
    )
  
  output_filename <- paste0("table_counts_obs_per_n_machs_and_instance_lp_impr_", variations[j], "_mslp.csv")
  file_path <- file.path(
      prefix_output_path_tables,
      "n_machs",
      output_filename
    )
  write_delim(count_csv_mslpr, file = file_path, delim = ";")

  p <-
    ggplot(
      csv_mslpr,
      aes(
        x = as.factor(type),
        y = perc_feasible,
        group = interaction(type, n_machs),
        fill = n_machs
      )
    ) +
    geom_boxplot() +
    labs(x = "Type",
         y = "Feasible solutions (%)",
         fill = "Num. of mach.") +
    scale_color_brewer(palette = "Set1") +
    theme(legend.position = "top", text = element_text(size = 14)) +
    coord_cartesian(ylim = c(0, 100)) +
    scale_y_continuous(
      breaks = seq(0, 100, by = round(10, digits = 0))
    )
  
  print(p)
  
  output_filename <- paste0("plot_feas_sol_perc_vs_n_machs_and_instance_", variations[j], "_mslp.pdf")
  file_path <- file.path(
      prefix_output_path_plots,
      "n_machs",
      output_filename
    )
  # ggsave(file_path, plot = p, width = 5, height = 4) # uncomment to save the plot
  
  p <-
    ggplot(
      csv_mslpr,
      aes(
        x = as.factor(type),
        y = mean_LP_impr_percentage,
        group = interaction(type, n_machs),
        fill = n_machs
      )
    ) +
    geom_boxplot() +
    labs(x = "Type",
         y = "Mean LP improvement (%)",
         fill = "Num. of mach.") +
    scale_color_brewer(palette = "Set1") +
    theme(legend.position = "top", text = element_text(size = 14)) +
    coord_cartesian(ylim = c(0, 45)) +
    scale_y_continuous(breaks = seq(0,
                                    45,
                                    by = round(5, digits = 0)))
  
  print(p)
  
  output_filename <- paste0("plot_mean_lp_impr_vs_n_machs_and_instance_", variations[j], "_mslp.pdf")
  file_path <- file.path(
      prefix_output_path_plots,
      "n_machs",
      output_filename
    )
  # ggsave(file_path, plot = p, width = 5, height = 4) # uncomment to save the plot
}
