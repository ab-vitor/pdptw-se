library(readr)

variations <- c("multi_island", "multi_floor")
prefix_output_path_plots <- "official_experiments/mslp_vs_mip/tables_mach_sens_analysis/plots"
prefix_output_path_tables <- "official_experiments/mslp_vs_mip/tables_mach_sens_analysis"
for(j in seq_along(variations)){
  input_filename <- paste0("grouped_inst_dev_", variations[j], ".csv")
  prefix_path <- "official_experiments/mslp_vs_mip/tables_mach_sens_analysis"
  input_path <- file.path(prefix_path, input_filename)
  grouped_inst_dev <- read_delim(
    file = input_path, 
    delim = ";", 
    escape_double = FALSE, 
    trim_ws = TRUE
  )
  grouped_inst_dev <- grouped_inst_dev %>%
    mutate(
      type = substr(name, 3, 3),
      n_reqs = substr(group, 1, 2)
    )
  
  counts <- grouped_inst_dev %>%
    group_by(type, n_reqs) %>%
    summarise(n_obs = sum(!is.na(deviation)), .groups = "drop")

  output_counts_filename <- paste0("counts_mach_sens_analysis_dev_", variations[j], ".csv")
  output_counts_path <- file.path(prefix_output_path_tables, output_counts_filename)

  readr::write_csv(counts, output_counts_path)
  
  p <-
    ggplot(
      grouped_inst_dev,
      aes(
        x = as.factor(type),
        y = deviation,
        group = interaction(type, n_reqs),
        fill = n_reqs
      )
    ) +
    geom_boxplot() +
    labs(x = "Type",
         y = "Solution value RPD (%)",
         fill = "Num. of reqs.") +
    scale_color_brewer(palette = "Set1") +
    theme(legend.position = "top", text = element_text(size = 14)) +
    coord_cartesian(ylim = c(-6, 10)) +
    scale_y_continuous(
      breaks = seq(-6, 10, by = round(2, digits = 0))
    )
  
  print(p)
  
  output_filename <- paste0("plot_mach_sens_analysis_dev_", variations[j], ".pdf")
  file_path <- file.path(
    prefix_output_path_plots,
    "n_reqs",
    output_filename
  )
  # ggsave(file_path, plot = p, width = 5, height = 4) # uncomment to save the plot
}