library(dplyr)
library(knitr)

benchmarks <- c("benchmark_multi_island_v5", "benchmark_multi_floor_v3")
variations <- c("I5", "F3")
prefix_set <- "official_experiments/mip_gurobi"
prefix_csv <- "csvresults_form_melo_type"
exp_set <- c("set_01", "set_01")
for (j in seq_along(benchmarks)) {
  for (t in 1:2) {
    csv_results <-
      read.csv(
        file = paste0(
          "../",
          benchmarks[j],
          "/",
          prefix_set,
          "/",
          exp_set[j],
          "/",
          prefix_csv,
          "_",
          t,
          ".csv"
        ),
        sep = ";"
      )
    
    
    csv_results <- csv_results %>%
      select(-any_of(c("rt_rlx", "rt_rlx.x", "rt_rlx.y")))
    
    rt_rlx_table <-
      read.csv(
        file = paste(
          "../",
          benchmarks[j],
          "/",
          prefix_set,
          "/",
          exp_set[j],
          "/",
          "root_relaxation_",
          exp_set[j],
          "_type_",
          t,
          ".csv",
          sep = ""
        ),
        sep = ";"
      )
    
    rt_rlx_table <- rt_rlx_table %>%
      rename(
        name="Instname",
        rt_rlx="Root.Relaxation",
        group="Group"
      )
    
    csv_results <- csv_results %>%
      left_join(rt_rlx_table, by=c("name", "group"))
      
    
    write.table(
      csv_results,
      paste0(
        "../",
        benchmarks[j],
        "/",
        prefix_set,
        "/",
        exp_set[j],
        "/",
        prefix_csv,
        "_",
        t,
        ".csv"
      ),
      sep = ";",
      dec = ".",
      quote = F,
      row.names = F
    )
  }
}