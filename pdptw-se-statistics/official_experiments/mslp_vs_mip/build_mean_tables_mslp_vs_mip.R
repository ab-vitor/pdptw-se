  library(dplyr)
  library(readr)
  
  variations <- c("multi_island", "multi_floor")
  prefix_path_mip <- "official_experiments/data/mip_grb_valid_inequalities/official"
  prefix_path_mslp <- "official_experiments/data/mslp_official"
  types <- c(1, 2)
  
  prefix_input_csvr_mip <- "csvresults_form_mip"
  prefix_input_csvr_mslp <- "csvresults_heur_mslp"
  
  prefix_output <- "official_experiments/mslp_vs_mip/tables"
  
  for (j in seq_along(variations)) {
    var <- variations[j]
    for (t in types) {
      suff_var <- paste0(var, ".csv")
      suff_type <- paste0("type_", t, ".csv")
      mip_input_name <- paste(prefix_input_csvr_mip, suff_var, sep="_")
      mip_input_path <- file.path(prefix_path_mip, mip_input_name)
      csvr_mip_complete <-
        read.csv(
          file = mip_input_path,
          sep = ";"
        )
      
      csvr_mip <- csvr_mip_complete %>%
        select(full_name, type, group, obj_value) %>%
        rename(mip_sol = obj_value) %>%
        filter(type == paste0("t", t))
        
      
      mslp_input_name <- paste(prefix_input_csvr_mslp, suff_var, sep="_")
      mslp_input_path <- file.path(prefix_path_mslp, mslp_input_name)
      csvr_mslp_complete <-
        read.csv(
          file = mslp_input_path,
          sep = ";"
        )
      
      csvr_mslp <- csvr_mslp_complete %>%
        rename(full_name = full_name, mslp_sol = value) %>%
        filter(n <= 12, type == paste0("t", t))
      
      grouped_avrg_group_instname_mslp <- csvr_mslp %>%
        group_by(full_name, group) %>%
        summarise(
          minbestsol = min(mslp_sol, na.rm = T),
          maxbestsol = max(mslp_sol, na.rm = T),
          meanbestsol = mean(mslp_sol, na.rm = T),
          iterations = mean(iteration, na.rm = T),
          miniterationtobest = min(iteration_to_best, na.rm = T),
          maxiterationtobest = max(iteration_to_best, na.rm = T),
          meaniterationtobest = mean(iteration_to_best, na.rm = T),
          mincputimetobest = min(time_to_best, na.rm = T),
          maxcputimetobest = max(time_to_best, na.rm = T),
          meancputimetobest = mean(time_to_best, na.rm = T),
          meancputime = mean(total_time_elapsed, na.rm = T),
          # across(
          #   where(is.numeric) &
          #     !c(value, iterations, iterationtobest, cputimetobest),
          #   mean,
          #   na.rm = TRUE
          # ),
          .groups = "drop"
        )
      
      csvr_mip_mslp <-
        left_join(csvr_mip,
                  grouped_avrg_group_instname_mslp,
                  by = c("full_name", "group"))
      
      
      csvr_mip_mslp <- csvr_mip_mslp %>%
        select(full_name, group, mip_sol, minbestsol, meanbestsol) %>%
        rename(
          mip_sol = mip_sol,
          mslp_min_sol = minbestsol,
          mslp_mean_sol = meanbestsol
        )
      
      csvr_mip_mslp <- csvr_mip_mslp %>%
        mutate(
          dev_mip_mslp_minbs = (mslp_min_sol - mip_sol) / mip_sol * 100,
          dev_mip_mslp_meanbs = (mslp_mean_sol - mip_sol) / mip_sol * 100
        )
      
      grouped_mean_dev <- csvr_mip_mslp %>%
        group_by(group) %>%
        summarise(
          mean_dev_mip_mslp_minbs = if (any(is.na(dev_mip_mslp_minbs))) NA else mean(dev_mip_mslp_minbs, na.rm = T),
          mean_dev_mip_mslp_meanbs = if (any(is.na(dev_mip_mslp_meanbs))) NA else mean(dev_mip_mslp_meanbs, na.rm = T)
        )
      
      
      output_file_name <- paste("grouped_mean_dev", var, suff_type, sep="_")
      output_file_path <- file.path(prefix_output, output_file_name)
      write_delim(
        grouped_mean_dev,
        file = output_file_path,
        delim = ";",
      )
      
      grouped_avrg_mip <- csvr_mip %>%
        group_by(group) %>%
        summarise("Sol." = if (any(is.na(mip_sol))) NA else mean(mip_sol, na.rm = T))
      
      grouped_avrg_mslp <- grouped_avrg_group_instname_mslp %>%
        group_by(group) %>%
        summarise(
          "min. sol." = mean(minbestsol, na.rm = T),
          "mean sol." = mean(meanbestsol, na.rm = T),
          "time (s)" = mean(meancputime, na.rm = T),
          "ttb (s)" = mean(meancputimetobest, na.rm = T)
        )
      
      grouped_mean_mip_mslp <- left_join(grouped_avrg_mip, grouped_avrg_mslp, by = c("group"))
      
      output_file_name_mip_mslp <- paste("grouped_mean_mip_mslp", var, suff_type, sep="_")
      output_file_path_mip_mslp <- file.path(prefix_output, output_file_name_mip_mslp)
      write_delim(
        grouped_mean_mip_mslp,
        file = output_file_path_mip_mslp,
        delim = ";",
      )
    }
  }
