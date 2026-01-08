library(dplyr)
library(knitr)
library(kableExtra)
library(tibble)
library(readr)

variations <- c("multi_island", "multi_floor")
prefix_path <- "official_experiments/mslp_vs_mip/tables"
suff_t1 <- "type_1.csv"
suff_t2 <- "type_2.csv"
tables <- c("grouped_mean_mip_mslp")

for (table in tables) {
  for (j in seq_along(variations)) {
    var <- variations[j]
    input_file_name <- paste(table, var, suff_t1, sep = "_")
    input_file_path <- file.path(prefix_path, input_file_name)
    grouped_t1 <-
      read.csv(
        file = input_file_path,
        sep = ";"
      )
    
    grouped_t1 <- grouped_t1 %>%
      rename(
        Sol_t1 = Sol.,
        min_sol_t1 = min..sol.,
        mean_sol_t1 = mean.sol.,
        time_s_t1 = time..s.,
        ttb_s_t1 = ttb..s.,
      )
    
    input_file_name <- paste(table, var, suff_t2, sep = "_")
    input_file_path <- file.path(prefix_path, input_file_name)
    grouped_t2 <-
      read.csv(
        file = input_file_path,
        sep = ";"
      )
    
    grouped_t2 <- grouped_t2 %>%
      rename(
        Sol_t2 = Sol.,
        min_sol_t2 = min..sol.,
        mean_sol_t2 = mean.sol.,
        time_s_t2 = time..s.,
        ttb_s_t2 = ttb..s.,
      )
    
    
    grouped_t1 <- grouped_t1 %>% 
      add_column(space1 = "hspace{0.05cm}", .after = "group") %>%
      add_column(space2 = "hspace{0.05cm}", .after = "Sol_t1")
    
    grouped_t2 <- grouped_t2 %>% 
      add_column(space4 = "hspace{0.05cm}", .after = "Sol_t2")
    
    grouped_t1$space3 <- "hspace{0.1cm}"
    
    type_header = c("",
                    "hspace{0.05cm}",
                    "Type 1" = 4,
                    "hspace{0.1cm}",
                    "Type 2" = 4)
    
    
    
    grouped <- left_join(grouped_t1, grouped_t2, by="group")
    
    output_file_name <- paste0(table, "_", var, ".csv")
    output_file_path <- file.path(prefix_path, output_file_name)
    write_delim(
      grouped,
      file = output_file_path,
      delim = ";"
    )
    
    tex_grouped <-
      kable(
        grouped,
        format = "latex",
        booktabs = TRUE,
        linesep = c('', '', '', '\\addlinespace'),
        digits = 2,
        escape = F
      )
    
    output_file_name <- paste0(table, "_", var, ".tex")
    output_file_path <- file.path(prefix_path, output_file_name)
    writeLines(
      tex_grouped,
      output_file_path,
    )
  }
}
