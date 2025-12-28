library(dplyr)


solvers_suff <- c("", "_hx")
benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_csv_output <- "grouped"
exp_set <- c("set_02", "set_02")
prefix_set_output <- "official_experiments/grb_vs_hx"
prefix_set_grb <- "official_experiments/mip_gurobi"
prefix_set_hx <- "official_experiments/mip_hexaly"
prefix_csv_input_grb <- "csvresults_form_melo"
prefix_csv_input_hx <- "csvresults_form_melo_hx"


na_count_list <- list()


for (j in seq_along(benchmarks)) {
  for (t in 1:2) {
    suff_output <- paste0("dev_type_", t)
    csv_results_df_grb <-
      read.csv(
        file = paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set_grb,
          "/",
          exp_set[j],
          "/",
          prefix_csv_input_grb,
          "_type_",
          t,
          ".csv"
        ),
        sep = ";"
      )
    
    csv_results_df_grb <- csv_results_df_grb %>%
      rename(obj_value = any_of("objValue")) %>%
      select(name, group, obj_value, gap, n_vehicles_used, time) %>%
      rename(
        obj_value_grb = obj_value,
        gap_grb = gap,
        n_vehicles_used_grb = n_vehicles_used,
        time_grb = time
      ) %>%
      mutate(
        obj_value_grb = ifelse(n_vehicles_used_grb != 0 & obj_value_grb != Inf & !is.na(obj_value_grb), obj_value_grb, NA)
      )
    
    csv_results_df_hx <-
      read.csv(
        file = paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set_hx,
          "/",
          exp_set[j],
          "/",
          prefix_csv_input_hx,
          "_type_",
          t,
          ".csv"
        ),
        sep = ";"
      )
    
    csv_results_df_hx <- csv_results_df_hx %>%
      rename(obj_value = any_of("objValue")) %>%
      select(name, group, obj_value, gap, n_vehicles_used, time) %>%
      rename(
        obj_value_hx = obj_value,
        gap_hx = gap,
        n_vehicles_used_hx = n_vehicles_used,
        time_hx = time
      ) %>%
      mutate(
        obj_value_hx = ifelse(n_vehicles_used_hx != 0 & obj_value_hx != Inf & !is.na(obj_value_hx), obj_value_hx, NA)
      )
    
    
    df_grb_hx <- 
      inner_join(
        csv_results_df_grb,
        csv_results_df_hx,
        by = c("name", "group")
      )
    
    dev_df_grb_hx <- df_grb_hx %>%
      mutate(
        dev_obj = ifelse(!is.na(obj_value_grb) & !is.na(obj_value_hx), round((obj_value_hx - obj_value_grb) / obj_value_grb * 100, digits = 2), NA),
        dev_gap = ifelse(gap_grb > 0,
                         round((gap_hx - gap_grb) / gap_grb * 100, digits = 2),
                         0),
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
    
    # add identifiers to know which benchmark/type this belongs to
    na_count_table <- na_count_table %>%
      mutate(
        variation = variations[j],
        inst_type = paste0("type_", t)
      )
    
    # store this table in the list
    na_count_list[[paste0(benchmarks[j], "_type_", t)]] <- na_count_table
    
      
    write.table(
      na_count_table,
      paste(
        "../",
        benchmarks[j],
        "/",
        prefix_set_output,
        "/",
        exp_set[j],
        "/",
        "na_count_dev_obj",
        "_",
        suff_output,
        ".csv",
        sep = ""
      ),
      sep = ";",
      dec = ".",
      quote = F,
      row.names = F
    )
    
    dev_df_grb_hx <- dev_df_grb_hx %>%
      select(-only_missing_grb, -only_missing_hx, -missing_both, -missing_one)
    
    write.table(
      dev_df_grb_hx,
      paste(
        "../",
        benchmarks[j],
        "/",
        prefix_set_output,
        "/",
        exp_set[j],
        "/",
        "inst_by_inst_grb_vs_hx",
        "_",
        suff_output,
        ".csv",
        sep = ""
      ),
      sep = ";",
      dec = ".",
      quote = F,
      row.names = F
    )
    
    grouped_mean_dev <- dev_df_grb_hx %>%
      group_by(group) %>%
      summarise(
        mean_dev_obj = if (any(is.na(dev_obj))) NA else mean(dev_obj),
        # mean_dev_gap = if (any(is.na(dev_gap))) NA else mean(dev_gap),
        # mean_dev_time = if (any(is.na(dev_time))) NA else mean(dev_time)
      )
    
    write.table(
      grouped_mean_dev,
      paste(
        "../",
        benchmarks[j],
        "/",
        prefix_set_output,
        "/",
        exp_set[j],
        "/",
        prefix_csv_output,
        "_",
        suff_output,
        ".csv",
        sep = ""
      ),
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

# write the merged summary table
write.table(
  merged_na_count_table,
  paste0(prefix_set_output, "/tables/merged_na_count_summary.csv"),
  sep = ";",
  dec = ".",
  quote = F,
  row.names = F
)