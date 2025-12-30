library(dplyr)
library(ggplot2)
library(stringr)
library(tidyr)

prefix <- "official_experiments/mip_grb_vi"
input_dir <- "table_all_instances"
path_to_csv_input <- file.path(prefix, input_dir, "results_for_all_instances.csv")

results_for_all_instances <- read_delim(
  file = path_to_csv_input, 
  delim = ";"
)

win_counts <- results_for_all_instances %>%
  filter(obj_value == best_obj) %>%
  group_by(vi_config) %>%
  summarise(wins = n())

optimal_filter <- results_for_all_instances %>%
  filter(status == 2)

non_optimal_filter <- results_for_all_instances %>%
  filter(status == 9)

all_vi_configs <- unique(results_for_all_instances$vi_config)

simultaneous_optimal_filter <- optimal_filter %>%
  group_by(full_name) %>%
  filter(all_vi_configs %in% vi_config |> all()) %>%
  ungroup()

simultaneous_non_optimal_filter <- non_optimal_filter %>%
  group_by(full_name) %>%
  filter(all_vi_configs %in% vi_config |> all()) %>%
  ungroup()

solved_counts <- optimal_filter %>%
  group_by(vi_config) %>%
  summarise(solved = n())

simultaneous_avg_time_solved <- simultaneous_optimal_filter %>%
  group_by(vi_config) %>%
  summarise(simultaneous_avg_time_solved = mean(time))

simultaneous_avg_gap_non_solved <- simultaneous_non_optimal_filter %>%
  group_by(vi_config) %>%
  summarise(simultaneous_avg_gap_non_solved = mean(gap))

composite_score_per_vi_config <- results_for_all_instances %>%
  group_by(vi_config) %>%
  summarise(
    arpd = mean(rpd),
    avg_gap = mean(gap),
    feasible = sum(optimal == 1 | tle_feas == 1),
    total = n()
  ) %>%
  left_join(win_counts, by="vi_config") %>%
  left_join(simultaneous_avg_time_solved, by="vi_config") %>%
  left_join(simultaneous_avg_gap_non_solved, by="vi_config") %>%
  left_join(solved_counts, by="vi_config") %>%
  mutate(
    wins = replace_na(wins, 0),
    feas_rate = feasible / total,
    wins_score = wins / max(wins),
    arpd_score = 1 - (arpd - min(arpd)) / (max(arpd) - min(arpd)),
    gap_score = 1 - (avg_gap - min(avg_gap)) / (max(avg_gap) - min(avg_gap))
  )

composite_score_per_vi_config <- composite_score_per_vi_config %>%
  mutate(composite_score = (feas_rate + arpd_score + gap_score)/3)

composite_score_per_vi_config <- composite_score_per_vi_config %>% 
  select(
    vi_config, feas_rate, arpd_score, 
    gap_score, composite_score, solved
  ) %>%
  arrange(desc(composite_score))

composite_score_per_vi_config <- composite_score_per_vi_config %>%
  mutate(
    vi_config = case_when(
      vi_config == "1-29" ~ "None",
      TRUE ~ str_replace(vi_config, "^1-29,", "")
    )
  )

composite_score_per_vi_config <- composite_score_per_vi_config %>%
  mutate(
    vi_config = str_replace_all(
      vi_config,
      "(\\d+)",
      "(\\1)"
    )
  )

output_dir <- "tables_per_configuration"
output_file <- "composite_score_per_vi_config.csv"
output_table_path <- file.path(prefix, output_dir, output_file)

write_delim(
  composite_score_per_vi_config,
  file = output_table_path,
  delim = ";"
)
