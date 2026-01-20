library(readr)
library(dplyr)

path_to_csv_input <- "official_experiments/mip_grb_vi/tables_per_instance/"

files <- list.files(path = path_to_csv_input, pattern = "\\.csv$", full.names = TRUE)

results_for_all_instances <- files %>%
  lapply(function(f) read_delim(f, delim = ";", col_types = cols())) %>%
  bind_rows()

results_for_all_instances <- results_for_all_instances %>%
  mutate(gap = ifelse(is.na(gap), 100.0, gap))

# Identify best objective per instance
best_per_instance <- results_for_all_instances %>%
  group_by(full_name) %>%
  summarise(
    best_obj = min(obj_value, na.rm = TRUE)
  )

results_for_all_instances <- results_for_all_instances %>%
  left_join(best_per_instance, by = "full_name") %>%
  # mutate(rpd = (obj_value - best_obj) / best_obj)
  mutate(rpd = ifelse(obj_value == Inf, 1, (obj_value - best_obj) / best_obj)) %>%
  rename(vi_config = constraints_used_mip_str)

path_to_csv_output <- "official_experiments/mip_grb_vi/table_all_instances/"

write_delim(results_for_all_instances, file.path(path_to_csv_output, "results_for_all_instances.csv"), delim = ";")
