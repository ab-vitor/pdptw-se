library(dplyr)
library(readr)

variations <- c("multi_island", "multi_floor")
prefix_path_mip <- "official_experiments/data/mip_grb_valid_inequalities/official"
prefix_path_mslp <- "official_experiments/data/mslp_official"

prefix_mip_input_name <- "csvresults_form_mip"
prefix_mslp_input_name <- "csvresults_heur_mslp"

prefix_output_tables <- "official_experiments/mslp_vs_mip/tables"
prefix_output_plots <- "official_experiments/mslp_vs_mip/plots"
set.seed(10)

for (j in seq_along(variations)) {
  var <- variations[j]
  mip_input_name <- paste0(prefix_mip_input_name, "_", var, ".csv")
  mip_input_path <- file.path(prefix_path_mip, mip_input_name)
  csvr_mip_complete <-
    read.csv(
      file = mip_input_path,
      sep = ";"
    )
  
  csvr_mip <- csvr_mip_complete %>%
    select(full_name, group, type, obj_value) %>%
    rename(mip_sol = obj_value) %>%
    mutate(mip_sol = ifelse(is.infinite(mip_sol), NA, mip_sol))
  
  mslp_input_name <- paste0(prefix_mslp_input_name, "_", var, ".csv")
  mslp_input_path <- file.path(prefix_path_mslp, mslp_input_name)
  csvr_mslp_complete <-
    read.csv(
      file = mslp_input_path,
      sep = ";"
    )
  
  csvr_mslp <- csvr_mslp_complete %>%
    rename(full_name = full_name, mslp_sol = value) %>%
    filter(n <= 12)
  
  
  csvr_mip_mslp <-
    left_join(csvr_mip,
              csvr_mslp,
              by = c("full_name", "group", "type"))
  
  csvr_mip_mslp <- csvr_mip_mslp %>%
    select(full_name, type, group, mip_sol, mslp_sol)
  
  csvr_mip_mslp <- csvr_mip_mslp %>%
    mutate(
      dev_mip_mslp = (mslp_sol - mip_sol) / mip_sol * 100,
    )
  
  
  csvr_mip_mslp_na_count_table <- csvr_mip_mslp %>%
    mutate(
      missing_one = if_else(is.na(dev_mip_mslp), 1, 0)
    )
  
  na_count_table_sol <- csvr_mip_mslp_na_count_table %>%
    group_by(type) %>%
    summarise(
      missing_one = sum(missing_one)
    )
  
  na_count_table_sol <- na_count_table_sol %>%
    mutate(variation = var) %>%
    select(type, missing_one, variation)
  
  output_file_name <- paste0("na_count_dev_obj_", var, "_all_indep_exec.csv")
  output_file_path <- file.path(prefix_output_tables, output_file_name)
  write_delim(
    na_count_table_sol,
    file = output_file_path,
    delim = ";"
  )
  
  csvr_mip_mslp <- csvr_mip_mslp %>%
    mutate(
      type = substr(type, 2, 2),
      n_reqs = substr(csvr_mip_mslp$group, 1, 2)
    )
  
  p <- ggplot(csvr_mip_mslp, aes(x = type, y = dev_mip_mslp, fill=n_reqs, group = as.factor(interaction(type, n_reqs)))) +
    geom_boxplot() +
    # geom_point(
    #   aes(x = type, y = dev_mip_mslp, grouop = interaction(type, n_reqs)),
    #   shape = 21,
    #   position = position_jitter(width = 0.2, height = 0),
    #   alpha = 0.5,
    # ) +
    labs(x = "Type", y = "Solution value RPD (%)", fill = "Num. of reqs.") +
    scale_color_brewer(palette = "Set1") +
    theme(legend.position = "top", text = element_text(size = 13)) +
    scale_y_continuous(
      limits = c(-20, 25),
      breaks = seq(-20, 25, by=5),
    )
  
  print(p)
  suff_output <- "_by_n_reqs_all_indep_exec.pdf"
  ggsave_filename <- paste0("box_plots_sol_dev_mip_mslp_", var, suff_output)
  ggsave_filepath <- file.path(prefix_output_plots, ggsave_filename)
  # ggsave(ggsave_filepath, plot = p, width = 5, height = 4)
}
