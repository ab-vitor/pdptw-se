library(dplyr)
library(knitr)
library(kableExtra)
library(tibble)

variations <- c("multi_island", "multi_floor")
prefix_csv_output <- "grouped"
tables <- c("grouped_abs", "grouped_avrg")

prefix_set <- "official_experiments/data/mip_grb_valid_inequalities/official"
for (table in tables) {
  for (j in seq_along(variations)) {
    file_name <- paste0(table, "_type_1_", variations[j], ".csv")
    file_path <- file.path(prefix_set, table, file_name)
    grouped_t1 <- read.csv(
      file = file_path,
      sep = ";"
    )
    
    # --- NEW: compute totals for numeric columns ---
    totals <- grouped_t1 %>%
      summarise(across(where(is.numeric), \(x) sum(x, na.rm = TRUE)))
    
    # Create a row with same structure
    total_row <- grouped_t1[1, ]
    total_row[] <- NA
    total_row$group <- "sum."
    total_row[names(totals)] <- totals
    
    # Append row
    grouped_t1 <- bind_rows(grouped_t1, total_row)
    
    file_name <- paste0(table, "_type_2_", variations[j], ".csv")
    file_path <- file.path(prefix_set, table, file_name)
    grouped_t2 <- read.csv(
      file = file_path,
      sep = ";"
    )
    
    grouped_t2 <- subset(grouped_t2, select = -1)
    
    # --- NEW: compute totals for numeric columns ---
    totals <- grouped_t2 %>%
      summarise(across(where(is.numeric), \(x) sum(x, na.rm = TRUE)))
    
    # Create a row with same structure
    total_row <- grouped_t2[1, ]
    total_row[] <- NA
    total_row[names(totals)] <- totals
    
    # Append row
    grouped_t2 <- bind_rows(grouped_t2, total_row)
    
    
    grouped_t1 <- grouped_t1 %>% 
      add_column(space1 = "\\hspace{0.1cm}", .after = "group")
    
    grouped_t1$space2 <- "\\hspace{0.2cm}"
    
    type_header = c("",
                    "\\hspace{0.1cm}",
                    "Type 1" = 4,
                    "\\hspace{0.2cm}",
                    "Type 2" = 4)
    
    grouped <- cbind(grouped_t1, grouped_t2)
    
    # Ensure unique column names before working
    grouped <- cbind(grouped_t1, grouped_t2)
    names(grouped) <- make.unique(names(grouped), sep = "_")
    
    file_name <- paste0(table, "_", variations[j], ".csv")
    file_path <- file.path(prefix_set, table, file_name)
    # Save CSV with totals
    write.table(
      grouped,
      file = file_path,
      sep = ";",
      dec = ".",
      quote = F,
      row.names = F
    )
    
    # --- Prepare a copy for LaTeX only ---
    grouped_tex <- grouped
    
    # Escape underscores in column names
    names(grouped_tex) <- gsub("_", "\\\\_", names(grouped_tex))
    
    # Escape underscores in group column (or any other character columns)
    char_cols <- sapply(grouped_tex, is.character)
    grouped_tex[char_cols] <- lapply(grouped_tex[char_cols], function(x) gsub("_", "\\\\_", x))
    
    # Escape underscores in the type header for add_header_above
    type_header_tex <- type_header
    names(type_header_tex) <- gsub("_", "\\\\_", names(type_header_tex))
    
    # Generate LaTeX with totals
    tex_grouped <-
      kable(
        grouped_tex,
        format = "latex",
        booktabs = TRUE,
        linesep = c('', '', '', '\\addlinespace'),
        digits = 2,
        escape = FALSE
      ) %>%
      add_header_above(type_header)

    file_name <- paste0(table, "_", variations[j], ".tex")
    file_path <- file.path(prefix_set, table, file_name)
    writeLines(
      tex_grouped,
      file_path
    )
  }
}