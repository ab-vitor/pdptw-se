library(dplyr)
library(readr)


variations <- c("multi_island", "multi_floor")
prefix_csv_output <- "grouped"
prefix_set_output <- "official_experiments/data/grb_vs_hx"
prefix_csv_input_grb <- "official_experiments/data/mip_gurobi/csvresults_form_mip"
prefix_csv_input_hx <- "official_experiments/data/mip_hexaly/csvresults_form_mip_hx"
ext_csv <- ".csv"

types <- c(1, 2)

na_count_list <- list()


for (j in seq_along(variations)) {
  for (t in types) {
    suff_output <- paste0("dev_type_", t)
    csvr_grb_file_path <- paste0(prefix_csv_input_grb, "_", variations[j], ext_csv)
    csv_results_df_grb <- read_delim(
      file = csvr_grb_file_path,
      delim = ";"
    )
    
    csv_results_df_grb <- csv_results_df_grb %>%
      filter(type == paste0("t", t))
    
    csvr_hx_file_path <- paste0(prefix_csv_input_hx, "_", variations[j], ext_csv)
    csv_results_df_hx <- read_delim(
      file = csvr_hx_file_path,
      delim = ";"
    )
    
    csv_results_df_hx <- csv_results_df_hx %>%
      filter(type == paste0("t", t))
    
    df_grb_hx <- inner_join(
      csv_results_df_grb,
      csv_results_df_hx,
      by = c("name", "group")
    )
    
    dev_df_grb_hx <- df_grb_hx %>%
      mutate(
        dev_obj = ifelse(!is.na(obj_value_grb) & !is.na(obj_value_hx), round((obj_value_hx - obj_value_grb) / obj_value_grb * 100, digits = 2), NA),
        dev_gap = ifelse(
          gap_grb > 0,
          round((gap_hx - gap_grb) / gap_grb * 100, digits = 2), 0
        ),
        dev_time = round((time_hx - time_grb) / time_grb * 100, digits=2)
      )
    
    dev_df_grb_hx <- dev_df_grb_hx %>%
      select(name, group, 
             obj_value_grb, obj_value_hx, dev_obj,
      )
    
    dev_df_grb_hx <- dev_df_grb_hx %>%
      mutate(
        only_missing_grb = if_else(is.na(obj_value_grb) & !is.na(obj_value_hx), 1, 0),
        only_missing_hx = if_else(is.na(obj_value_hx) & !is.na(obj_value_grb), 1, 0),
        missing_both = if_else(is.na(obj_value_grb) & is.na(obj_value_hx), 1, 0),
        missing_one = if_else(is.na(dev_obj), 1, 0)
      )
    
    na_count_table <- dev_df_grb_hx %>%
      summarise(
        only_missing_grb = sum(only_missing_grb),
        only_missing_hx = sum(only_missing_hx),
        missing_both = sum(missing_both),
        missing_one = sum(missing_one)
      )
    
    na_count_table <- na_count_table %>%
      mutate(
        variation = variations[j],
        inst_type = paste0("type_", t)
      )
    
    # store this table in the list
    na_count_list[[paste0(variations[j], "_type_", t)]] <- na_count_table
    
    na_count_table_file_name <- paste0("na_count_dev_obj_", suff_output, ".csv")
    na_count_table_file_path <- file.path(
      prefix_set_output,
      variations[j],
      na_count_table_file_name
    )
    dir.create(dirname(na_count_table_file_path), showWarnings = FALSE, recursive = TRUE)

    write.table(
      na_count_table,
      na_count_table_file_path,
      sep = ";",
      dec = ".",
      quote = F,
      row.names = F
    )
    
    dev_df_grb_hx <- dev_df_grb_hx %>%
      select(-only_missing_grb, -only_missing_hx, -missing_both, -missing_one)
    
    dev_df_grb_hx_file_name <- paste0("inst_by_inst_grb_vs_hx_", suff_output, ".csv")
    dev_df_grb_hx_file_path <- file.path(
      prefix_set_output,
      variations[j],
      dev_df_grb_hx_file_name
    )
    dir.create(dirname(dev_df_grb_hx_file_path), showWarnings = FALSE, recursive = TRUE)

    write.table(
      dev_df_grb_hx,
      dev_df_grb_hx_file_path,
      sep = ";",
      dec = ".",
      quote = F,
      row.names = F
    )
    
    grouped_mean_dev <- dev_df_grb_hx %>%
      group_by(group) %>%
      summarise(
        mean_dev_obj = if (any(is.na(dev_obj))) NA else mean(dev_obj),
      )

    grouped_mean_dev_file_name <- paste0(prefix_csv_output, "_", suff_output, ".csv")
    grouped_mean_dev_file_path <- file.path(
      prefix_set_output,
      variations[j],
      grouped_mean_dev_file_name
    )
    dir.create(dirname(grouped_mean_dev_file_path), showWarnings = FALSE, recursive = TRUE)
    write.table(
      grouped_mean_dev,
      grouped_mean_dev_file_path,
      sep = ";",
      dec = ".",
      quote = F,
      row.names = F
    )
    
  }
}

# ---- After both loops, merge all the small tables ----
merged_na_count_table <- bind_rows(na_count_list)
merged_na_count_table <- merged_na_count_table %>%
  select(inst_type, variation, missing_one, missing_both, only_missing_grb, only_missing_hx) %>%
  arrange(inst_type)

write.table(
  merged_na_count_table,
  paste0(prefix_set_output, "/merged_na_count_summary.csv"),
  sep = ";",
  dec = ".",
  quote = F,
  row.names = F
)