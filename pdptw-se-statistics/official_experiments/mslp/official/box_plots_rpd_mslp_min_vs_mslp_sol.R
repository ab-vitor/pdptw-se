library(dplyr)
library(readr)
library(ggplot2)

variations <- c("multi_island", "multi_floor")
prefix_path_mslp <- "official_experiments/data/mslp_official"
prefix_mslp_input_name <- "csvresults_heur_mslp"

prefix_output_tables <- "official_experiments/mslp/official/tables"
prefix_output_plots <- "official_experiments/mslp/official/plots"
set.seed(10)

for (j in seq_along(variations)) {
  var <- variations[j]
  mslp_input_name <- paste0(prefix_mslp_input_name, "_", var, ".csv")
  mslp_input_path <- file.path(prefix_path_mslp, mslp_input_name)
  csvr_mslp_complete <-
    read.csv(
      file = mslp_input_path,
      sep = ";"
    )
  
  csvr_mslp <- csvr_mslp_complete %>%
    rename(mslp_sol = value) %>%
    filter(n > 12)
  
  csvr_mslp_best <- csvr_mslp %>%
    group_by(full_name, group, type) %>%
    summarise(
      mslp_min_sol = min(mslp_sol, na.rm = T),
      .groups = "drop"
    )
  
  csvr_mslp <- left_join(csvr_mslp, csvr_mslp_best, by = c("full_name", "group", "type"))
  
  csvr_mslp <- csvr_mslp %>%
    select(full_name, type, group, mslp_sol, mslp_min_sol) %>%
    mutate(
      mslp_sol = ifelse(is.infinite(mslp_sol), NA, mslp_sol),
      mslp_min_sol = ifelse(is.infinite(mslp_min_sol), NA, mslp_min_sol)
    )
  
  csvr_mslp <- csvr_mslp %>%
    mutate(
      rpd_mslp_sol_min = (mslp_sol - mslp_min_sol) / mslp_min_sol * 100,
    )
  
  
  csvr_mslp_na_count_table <- csvr_mslp %>%
    mutate(
      missing_one = if_else(is.na(rpd_mslp_sol_min), 1, 0)
    )
  
  na_count_table_sol <- csvr_mslp_na_count_table %>%
    group_by(type) %>%
    summarise(
      missing_one = sum(missing_one)
    )
  
  na_count_table_sol <- na_count_table_sol %>%
    mutate(variation = var) %>%
    select(type, missing_one, variation)
  
  output_file_name <- paste0("na_count_rpd_obj_", var, "_mslp_sol_min.csv")
  output_file_path <- file.path(prefix_output_tables, output_file_name)
  write_delim(
    na_count_table_sol,
    file = output_file_path,
    delim = ";"
  )
  
  csvr_mslp <- csvr_mslp %>%
    mutate(
      type = substr(type, 2, 2),
      n_reqs = substr(csvr_mslp$group, 1, 2)
    )
  
  p <- ggplot(csvr_mslp, aes(x = type, y = rpd_mslp_sol_min, fill=n_reqs, group = as.factor(interaction(type, n_reqs)))) +
    geom_boxplot() +
    labs(x = "Type", y = "Solution value RPD (%)", fill = "Num. of reqs.") +
    scale_color_brewer(palette = "Set1") +
    theme(legend.position = "top", text = element_text(size = 13)) +
    scale_y_continuous(
      limits = c(0, 14),
      breaks = seq(0, 14, by=2),
    )
  
  print(p)
  suff_output <- "_by_n_reqs.pdf"
  ggsave_filename <- paste0("box_plots_sol_rpd_mslp_sol_min_", var, suff_output)
  ggsave_filepath <- file.path(prefix_output_plots, ggsave_filename)
  # ggsave(ggsave_filepath, plot = p, width = 5, height = 4) # uncomment to save the plot
}
