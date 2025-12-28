library(dplyr)
library(readr)

benchmarks <-
  c(
    "benchmark_multi_island_v5",
    "benchmark_multi_floor_v3",
    "benchmark_multi_island_v5",
    "benchmark_multi_floor_v3"
  )
variations <- c("I5", "F3")
prefix_path_mip <- "official_experiments/mip_grb_valid_inequalities/official"
prefix_path_mslp <- "official_experiments/multistartlp/official"
sets <- c("set_01", "set_01", "set_01", "set_01")

prefix_input_csvr_mip <- "csvresults_form_melo"
prefix_input_csvr_mslp <- "csvresults_heur_mslp"

prefix_output <- "official_experiments/mslp_vs_mip/tables"

for (j in 1:2) {
  k <- j + 2
  var <- variations[j]
  for (t in 1:2) {
    suff_type <- paste0("type_", t, ".csv")
    mip_input_name <- paste(prefix_input_csvr_mip, suff_type, sep="_")
    mip_input_path <- file.path(
      "..",
      benchmarks[j],
      prefix_path_mip,
      sets[j],
      mip_input_name
    )
    csvr_mip_complete <-
      read.csv(
        file = mip_input_path,
        sep = ";"
      )
    
    csvr_mip <- csvr_mip_complete %>%
      select(full_name, group, obj_value)
    
    mslp_input_name <- paste(prefix_input_csvr_mslp, suff_type, sep="_")
    mslp_input_path <- file.path(
      "..",
      benchmarks[k],
      prefix_path_mslp,
      sets[k],
      mslp_input_name
    )
    csvr_mslp_complete <-
      read.csv(
        file = mslp_input_path,
        sep = ";"
      )
    
    csvr_mslp <- csvr_mslp_complete %>%
      select(
        fullname, group, value, iteration, 
        iterationToBest, timeToBest, 
        totalTimeElapsed, seed, n, feasible
      ) %>%
      rename(full_name = fullname) %>%
      filter(n <= 12)
    
    grouped_avrg_group_instname_mslp <- csvr_mslp %>%
      group_by(full_name, group) %>%
      summarise(
        minbestsol = min(value, na.rm = T),
        maxbestsol = max(value, na.rm = T),
        meanbestsol = mean(value, na.rm = T),
        iterations = mean(iteration, na.rm = T),
        miniterationtobest = min(iterationToBest, na.rm = T),
        maxiterationtobest = max(iterationToBest, na.rm = T),
        meaniterationtobest = mean(iterationToBest, na.rm = T),
        mincputimetobest = min(timeToBest, na.rm = T),
        maxcputimetobest = max(timeToBest, na.rm = T),
        meancputimetobest = mean(timeToBest, na.rm = T),
        meancputime = mean(totalTimeElapsed, na.rm = T),
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
      select(full_name, group, obj_value, minbestsol, meanbestsol) %>%
      rename(
        mip_sol = obj_value,
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
      summarise("Sol." = if (any(is.na(obj_value))) NA else mean(obj_value, na.rm = T))
    
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
