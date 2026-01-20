library(dplyr)
library(ggplot2)
library(svglite)
library(purrr)
library(readr)

benchmarks_desc <- c("Multi-island", "Multi-floor")
names_regions <- c("Islands", "Floors")
variations <- c("multi_island", "multi_floor")
prefix_set <- "official_experiments/data/mip_grb_valid_inequalities/official"
prefix_csv_input_file_name <- "csvresults_form_mip"
plot_dir <- "official_experiments/time_and_optimality_gap/plots"
tables_dir <- "official_experiments/time_and_optimality_gap/tables"

suffix_plot_variation <- "vs_n_reqs_and_instance"

OPTIMAL <- 2
TIME_LIMIT <- 9
KILLED <- 11


columns_max_value <- c(3600, 100)

columns_min_value <- c(0, 0)
set.seed(10)
for (j in seq_along(variations)) {
  csv_input_file_name <- paste0(prefix_csv_input_file_name, "_", variations[j], ".csv")
  csv_input_file_path <- file.path(prefix_set, csv_input_file_name)
  csv_results <- read_delim(
    csv_input_file_path,
    delim = ";", 
    escape_double = FALSE, 
    trim_ws = TRUE
  )
  
  csv_results$type <- substr(csv_results$name, 3, 3)
  
  csv_results <- csv_results %>%
    select(
      name, group, type, 
      full_name, optimal,
      tle_feas, gap, time
    ) %>%
    mutate(
      feas_sol = pmax(optimal,tle_feas),
    ) 
  
  csv_results <- csv_results %>%
    mutate(
      time = ifelse(feas_sol==1, time, NA)
    )
  csv_results$n_reqs <- substr(csv_results$group, 1, 2)
  csv_results$n_regions <- substr(csv_results$group, 9, 10)
  csv_results$n_machs <- substr(csv_results$group, 13, 14)

  counts_type_n_reqs <- csv_results %>%
    filter(feas_sol == 1) %>%
    group_by(type, n_reqs) %>%
    summarise(n_obs = n(), .groups = "drop") %>%
    arrange(type, n_reqs)
  
  write_csv(counts_type_n_reqs, file.path(tables_dir, paste0("counts_by_type_n_reqs_", variations[j], ".csv")))
  columns <- c("time", "gap")
  
  columns_desc <- c("Time (s)", "Gap (%)")
  
  columns_breaks <- c(300, 10)
  for (i in seq_along(columns)) {
    print(columns[i])
    p <-
      ggplot(
        csv_results,
        aes_string(
          x = as.factor(csv_results$type),
          y = columns[i],
          group = interaction(csv_results$type, csv_results$n_reqs),
          fill = "n_reqs"
        )
      ) +
      geom_boxplot() +
      labs(x = "Type",
           y = columns_desc[i],
           fill = "Num. of reqs.") +
      scale_color_brewer(palette = "Set1") +
      theme(legend.position = "top", text = element_text(size = 14)) +
      coord_cartesian(ylim = c(columns_min_value[i], columns_max_value[i])) +
      scale_y_continuous(
        breaks = seq(
          columns_min_value[i],
          columns_max_value[i],
          by = round(columns_breaks[i], digits = 0)
        )
      )
    
    
    print(p)
    
    filename <-
      paste0(
        plot_dir,
        "/",
        "plot_",
        columns[i],
        "_",
        suffix_plot_variation,
        "_",
        variations[j],
        ".pdf"
      )
    # ggsave(filename, plot = p, width = 5, height = 4) # uncomment to save the plot
  }
  
}