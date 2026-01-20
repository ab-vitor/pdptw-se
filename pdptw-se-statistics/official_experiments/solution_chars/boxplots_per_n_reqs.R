library(dplyr)
library(ggplot2)
library(svglite)
library(readr)

benchmarks_desc <- c("Multi-island","Multi-floor")
names_regions <- c("Islands", "Floors")
variations <- c("multi_island", "multi_floor")
method_output_prefix_file_path <- c(
  "official_experiments/data/solution_chars/sol_chars_form_mip",
  "official_experiments/data/solution_chars/sol_chars_heur_mslp"
)
method_names <- c("mip_vi", "mslp")

output_dir_plots <- "official_experiments/solution_chars/plots/n_reqs"
output_dir_tables <- "official_experiments/solution_chars/tables/n_reqs"

columns_max_value <- rep.int(0, 13)

columns_min_value <- rep.int(0, 13)

columns_sol_chars <- c(
  "n_vehicles_used",
  "n_machines_used",
  "max_max_load_all_vehicles",
  "min_max_load_all_vehicles",
  "mean_max_load_all_vehicles",
  "min_completion_time",
  "max_completion_time",
  "mean_completion_time",
  "avrg_machines_travel_time_with_vehicle",
  "avrg_machines_travel_time_only_with_vehicle",
  "avrg_machines_travel_time_no_vehicle",
  "avrg_vehicles_waiting_time_for_a_machine_travel",
  "avrg_vehicles_waiting_time_for_a_service"
)

columns_desc <-
  c(
    "Vehicle Utilization (%)",
    "Machine Utilization (%)",
    "Max of Maximum Capacity Utilization (%)",
    "Min of Maximum Capacity Utilization (%)",
    "Mean of Maximum Capacity Utilization (%)",
    "Minimum completion time (%)",
    "Maximum completion time (%)",
    "Mean completion time (%)",
    "Mean machine active time (%)",
    "Mean machine active time carrying a vehicle (%)",
    "Mean machine active time with dead freight (%)",
    "Mean vehicles waiting time for a machine travel (%)",
    "Mean vehicles waiting time for a service (%)"
  )

for (j in seq_along(variations)) {
  var <- variations[j]
  for (l in seq_along(method_names)){
    file_path <- paste0(method_output_prefix_file_path[l], "_", var, ".csv")
    csvr_df_complete <- read.csv(
      file = file_path,
      sep = ";"
    )
    
    csvr_df <- csvr_df_complete %>%
      mutate(
        n_reqs = substr(group, 1, 2),
        n_regions = substr(group, 9, 10),
        n_machs = substr(group, 13, 14),
        type = substr(name, 3, 3)
      ) %>%
      select(group, name, type, feasible, n_reqs, n_regions, n_machs, any_of(columns_sol_chars))
    
    for (i in seq_along(columns_sol_chars)) {
      columns_max_value[i] <-
        ceiling(max(columns_max_value[i], max(csvr_df[[columns_sol_chars[i]]], na.rm = T), na.rm = T))
    }
    for (i in seq_along(columns_sol_chars)) {
      columns_min_value[i] <- floor(
        min(
          columns_min_value[i], 
          min(csvr_df[[columns_sol_chars[i]]], na.rm = T), 
          na.rm = T
        )
      )
      columns_min_value[i] <- floor(columns_min_value[i] / 10) * 10
    }
  }
}

for (j in seq_along(variations)) {
  var <- variations[j]
  for (l in seq_along(method_names)){
    file_path <- paste0(method_output_prefix_file_path[l], "_", var, ".csv")
    csvr_df_complete <- read.csv(
      file = file_path,
      sep = ";"
    )
    
    csvr_df <- csvr_df_complete %>%
      mutate(
        n_reqs = substr(group, 1, 2),
        n_regions = substr(group, 9, 10),
        n_machs = substr(group, 13, 14),
        type = substr(name, 3, 3)
      ) %>%
      select(group, name, type, feasible, n_reqs, n_regions, n_machs, any_of(columns_sol_chars))
    
    
    columns_breaks <- c(10,10,10,10,10,10,10,10,10,5,5,10,10)
    
    obs_counts <- csvr_df %>%
      filter(feasible == 1) %>%
      group_by(type, n_reqs) %>%
      summarise(count = n(), .groups = "drop") %>%
      arrange(type, n_reqs)
    
    file_name <- paste0("obs_plots_vs_n_reqs_and_instance_", method_names[l], "_", var, ".csv")
    file_path <- file.path(output_dir_tables, file_name)
    write_delim(
      obs_counts,
      file = file_path,
      delim = ";"
    )
    
    for (i in seq_along(columns_sol_chars)) {
      print(columns_sol_chars[i])
      
      p <-
        ggplot(
          csvr_df,
          aes_string(
            x = as.factor(csvr_df$type),
            y = columns_sol_chars[i],
            group = interaction(csvr_df$type, csvr_df$n_reqs),
            fill = "n_reqs"
          )
        ) +
        geom_boxplot() +
        labs(x = "Type",
             y = columns_desc[i],
             fill = "Num. of reqs.") +
        scale_fill_manual(
          values = c(
            "06" = "#E41A1C", 
            "08" = "#377EB8", 
            "10" = "#4DAF4A", 
            "12" = "#984EA3", 
            "40" = "#FF7F00", 
            "60" = "#FFFF33"
          )
        ) +
        theme(legend.position = "top", text = element_text(size = 13)) +
        coord_cartesian(ylim = c(columns_min_value[i], columns_max_value[i])) +
        scale_y_continuous(breaks = seq(
          columns_min_value[i],
          columns_max_value[i],
          by = round(columns_breaks[i], digits = 0)
        ))
      
      
      print(p)
      
      file_name <- paste0("plot_", columns_sol_chars[i], "_vs_n_reqs_and_instance_", method_names[l], "_", var, ".pdf")
      file_path <- file.path(output_dir_plots, file_name)
      # ggsave(file_path, plot = p, width = 5, height = 4) # uncomment to save the plot
    }
  }
}