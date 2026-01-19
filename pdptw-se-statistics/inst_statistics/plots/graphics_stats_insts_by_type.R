library(ggplot2)
library(dplyr)
library(purrr)

variations <- c("multi_island", "multi_floor")
variations_desc <- c("Multi-island", "Multi-floor")
folder_variations <- c("multi_island/", "multi_floor/")
profiles <- c("small", "big")
suff_prof <- c("", "_big")

set.seed(0)

plot_profiles <- list(
  # Profile A: small famillies
  small = list(
    list(yvar = "tw_shift", ylab = "TW change (%)",  ylim = c(0, 15),  breaks = seq(0, 15, 3)),
    list(yvar = "cap_incr", ylab = "Cap change (%)", ylim = c(0, 2.5), breaks = seq(0, 2.5, 0.5))
  ),

  # Profile B: big famillies
  big = list(
    list(yvar = "tw_shift", ylab = "TW change (%)",   ylim = c(0, 55), breaks = seq(0, 55, 5)),
    list(yvar = "cap_incr", ylab = "Cap change (%)",  ylim = c(0, 2.5),  breaks = seq(0, 2.5, 0.5))
  )
)


# --- Helper: read both types and merge ---
read_stats <- function(inst, folder) {
  read_one <- function(type) {
    df <- read.csv(
      file = paste0("./inst_statistics/", folder, "stats_", inst, "_type_", type, ".csv"),
      sep = ";"
    )
    df$type <- as.character(type)
    df
  }
  stats <- bind_rows(read_one(1), read_one(2))
  
  stats %>%
    mutate(
      n_regions = substr(group, 10, 10),
      group_num = as.numeric(factor(group)),
      n_regions_num = as.numeric(factor(n_regions)),
      tw_shift = 100 * tw_shift,
      cap_incr = 100 * cap_incr,
    )
}

# --- Helper: save boxplot ---
save_boxplot <- function(stats, yvar, ylab, inst, ylim = NULL, breaks = NULL,
                         filename_suffix = NULL, add_jitter = TRUE,
                         add_rect = FALSE, inst_desc = NULL) {
  
  p <- ggplot(stats, aes(x = type, y = .data[[yvar]])) +
    geom_boxplot(outlier.shape = NA) +
    labs(x = "Type", y = ylab)
  
  if (add_jitter) {
    p <- p + geom_point(
      aes(x = type, y = .data[[yvar]]),
      shape = 21,
      position = position_jitter(width = 0.2, height = 0),
      alpha = 0.5
    )
  }
  
  if (!is.null(ylim)) {
    p <- p + coord_cartesian(ylim = ylim)
  }
  if (!is.null(breaks)) {
    p <- p + scale_y_continuous(breaks = breaks)
  }
  
  if (add_rect) {
    y_func <- function(n_regions) ifelse(n_regions == "2", 3.841, 7.815)
    chi_squared_table <- data.frame(
      xmin = stats$n_regions_num - 0.5,
      xmax = stats$n_regions_num + 0.5,
      ymin = y_func(stats$n_regions) - 1e-11,
      ymax = y_func(stats$n_regions) + 1e-11
    )
    p <- p + geom_rect(
      data = chi_squared_table,
      aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      color = "red", alpha = 0.3, inherit.aes = FALSE
    )
  }
  
  print(p)
  filename <- paste0("inst_statistics/plots/boxplot_stats_by_type_",
                     filename_suffix %||% yvar, "_", inst, ".pdf")
  # ggsave(filename, plot = p, width = 5, height = 4) # uncomment this line to save box plot
}


for (p in seq_along(profiles)){
  profile_choice <- profiles[p]
  suff_p <- suff_prof[p]
  # --- Main loop ---
  for (i in seq_along(variations)) {
    inst <- paste0(variations[i], suff_p)
    stats <- read_stats(inst, folder_variations[i])
    
    plots_to_generate <- plot_profiles[[profile_choice]]
    
    walk(plots_to_generate, function(spec) {
      save_boxplot(
        stats,
        yvar = spec$yvar,
        ylab = spec$ylab,
        inst = inst,
        ylim = spec$ylim,
        breaks = spec$breaks,
        filename_suffix = spec$filename_suffix,
        add_rect = spec$add_rect %||% FALSE
      )
    })
  }
}
