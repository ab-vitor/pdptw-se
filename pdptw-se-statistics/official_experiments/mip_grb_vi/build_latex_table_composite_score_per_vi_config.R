library(dplyr)
library(xtable)
library(readr)

prefix <- "official_experiments/mip_grb_vi"
input_dir <- "tables_per_configuration"
input_file <- "composite_score_per_vi_config.csv"
path_to_csv_input <- file.path(prefix, input_dir, input_file)

composite_score_per_vi_config <- read_delim(
  file = path_to_csv_input, 
  delim = ";"
)

composite_score_per_vi_config <- composite_score_per_vi_config %>%
  mutate(across(
    where(~ is.numeric(.x) &&
            all(.x >= 0 & .x <= 1, na.rm = TRUE) &&
            any(.x %% 1 != 0, na.rm = TRUE)),  # ensures there are fractional values
    ~ round(.x * 100, 2)
  ))

digits_vec <- c(0, 0, 2, 2, 2, 2, 0)

latex_table <- xtable(
  composite_score_per_vi_config, 
  caption = "Composite Score per VI Configuration", 
  digits = digits_vec
)

print(latex_table, include.rownames = FALSE)

output_dir <- "tables_per_configuration"
output_file <- "composite_score_table.tex"
output_path <- file.path(prefix, output_dir, output_file)
sink(output_path)
print(latex_table, include.rownames = FALSE)
sink()
