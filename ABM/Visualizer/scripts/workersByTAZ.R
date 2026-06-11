##########################################################
### Script to summarize workers by TAZ and Income Group

start_time <- Sys.time()

### Read Command Line Arguments
args                <- commandArgs(trailingOnly = TRUE)
Parameters_File     <- args[1]

### Read parameters from Parameters_File
parameters          <- read.csv(Parameters_File, header = TRUE)
ABM_DIR             <- trimws(paste(parameters$Value[parameters$Key=="ABM_DIR"]))
ABM_SUMMARY_DIR     <- trimws(paste(parameters$Value[parameters$Key=="ABM_SUMMARY_DIR"]))
SKIMS_DIR           <- trimws(paste(parameters$Value[parameters$Key=="SKIMS_DIR"]))
ZONES_DIR           <- trimws(paste(parameters$Value[parameters$Key=="ZONES_DIR"]))
LAND_USE_DIR        <- trimws(paste(parameters$Value[parameters$Key=="LAND_USE_DIR"]))
R_LIBRARY           <- trimws(paste(parameters$Value[parameters$Key=="R_LIBRARY"]))
BUILD_SAMPLE_RATE   <- trimws(paste(parameters$Value[parameters$Key=="BUILD_SAMPLE_RATE"]))
input_data          <- trimws(paste(parameters$Value[parameters$Key=="SE_INPUT_DIR"]))

# syn_path <- "E:/Projects/Clients/SEMCOG/Models/SEMCOG_ABM/SEMCOG_model/data/reindexed"
# syn_hh <- read.csv(file.path(syn_path, "households.csv"), header = TRUE)

.libPaths(R_LIBRARY)
SYSTEM_REPORT_PKGS <- c("reshape", "dplyr", "ggplot2", "plotly", "readr")
lib_sink <- suppressWarnings(suppressMessages(lapply(SYSTEM_REPORT_PKGS, library, character.only = TRUE))) 

# read data
setwd(LAND_USE_DIR)
land_use                          <- read.csv("land_use_taz.csv", header = TRUE)
destination_choice_size_terms     <- read.csv("destination_choice_size_terms.csv", header = TRUE)

setwd(ABM_DIR)
hh   <- read_csv("final_households.csv")
per  <- read_csv("final_persons.csv")
taz_maz  <- read_csv("final_land_use.csv")

setwd(ABM_SUMMARY_DIR)

employment_categories <- colnames(destination_choice_size_terms[c(4:21)])

income_segments_df <- data.frame(code = c(1,2,3,4),
                                 segment = c("work_low", "work_med", "work_high", "work_veryhigh"))
countynames <- data.frame(code = c(1, 2, 3, 4, 5, 6, 7, 8),
                          name = c("Detroit", "Wayne", "Oakland", "Macomb", "Washtenaw", "Monroe", "St. Clair", "Livingston"))
# --------------------------------------------------
### Functions
lm_eqn <- function(df){
  m <- lm(y ~ x - 1, df);
  eq <- paste("Y = ", format(coef(m)[1], digits = 2), " * X, ", " r2 = ", format(summary(m)$r.squared, digits = 3), sep = "")
  return(eq)
}
lm_eqn_labeled <- function(df){
  m <- lm(tot_workers ~ tot_emp - 1, df);
  eq <- paste("Y = ", format(coef(m)[1], digits = 2), " * X, ", " r2 = ", format(summary(m)$r.squared, digits = 3), sep = "")
  return(eq)
}

createMultiColorScatter <- function(df, color_label, title, save_name){
  
  x_pos <- max(df$x) * .75
  y_pos1 <- max(df$y) * .2
  y_pos2 <- max(df$y) * .1
  
  p <- ggplot(df, aes(x=x, y=y, colour=color_var)) +
    geom_point(alpha=.5) + 
    geom_smooth(method=lm, formula = y ~ x - 1, se=FALSE) +
    # geom_smooth(method=lm, alpha=0.5, color="black") + 
    geom_abline(intercept = 0, slope = 1, linetype = 2) + 
    geom_text(x = x_pos, y = y_pos2,label = "- - - - : 45 Deg Line",  parse = FALSE, color = "black") +
    labs(x="Employment", y="Workers", colour=color_label, title=title)
  # plot(p)
  ggsave(file=save_name, width=12, height=10)
  
}

createSingleColorScatter <- function(df, title, save_name){

  x_pos <- max(df$x) * .75
  y_pos1 <- max(df$y) * .2
  y_pos2 <- max(df$y) * .1
  
  p <- ggplot(df, aes(x=x, y=y)) +
    geom_point(shape=1, color = "#0072B2")  + 
    geom_smooth(method=lm, formula = y ~ x - 1, se=FALSE) +
    # geom_smooth(method=lm, alpha=0.5, color="black") + 
    geom_text(x = x_pos, y = y_pos1,label = as.character(lm_eqn(df)) ,  parse = FALSE, color = "#0072B2", size = 6) +
    geom_abline(intercept = 0, slope = 1, linetype = 2) + 
    geom_text(x = x_pos, y = y_pos2,label = "- - - - : 45 Deg Line",  parse = FALSE, color = "black") +
    labs(x="Employment", y="Workers", title=title)
  # plot(p)
  ggsave(file=save_name, width=12, height=10)
  
}

# ------------------------------------------
# Processing person file
per$finalweight <- 1/as.numeric(BUILD_SAMPLE_RATE)
per$income_segment <- hh$income_segment[match(per$household_id, hh$household_id)]

workers <- per[per$workplace_zone_id > 0 & per$is_worker == TRUE,]
#2-zone
workers$workplace_zone_id_taz <- taz_maz$TAZ[match(workers$workplace_zone_id, taz_maz$zone_id)]

workers$work_county <- land_use$COUNTY[match(workers$workplace_zone_id_taz, land_use$ZONE)]

income_factors <- destination_choice_size_terms[destination_choice_size_terms$model_selector == "workplace",]
income_factors$income_segment <- income_segments_df$code[match(income_factors$segment, income_segments_df$segment)]

# -----------------------------------------
# Workers vs Employment by County
print("Creating Workers vs Employment by County...")

employmentbyCounty <- land_use %>%
  group_by(COUNTY) %>%
  summarize(tot_emp = sum(tot_emp)) %>%
  select(COUNTY, tot_emp)

workersByCounty <- workers %>%
  group_by(work_county) %>%
  summarize(tot_workers = sum(finalweight)) %>%
  left_join(employmentbyCounty, by = c("work_county" = "COUNTY")) %>%
  select(work_county, tot_workers, tot_emp)

workersByCounty$county_name <- countynames$name[match(workersByCounty$work_county, countynames$code)]

x_pos <- max(workersByCounty$tot_emp) * .75
y_pos1 <- max(workersByCounty$tot_workers) * .2
y_pos2 <- max(workersByCounty$tot_workers) * .1
  
pCounty <- ggplot(workersByCounty, aes(x=tot_emp, y=tot_workers, colour=county_name)) +
  # geom_point(shape=1, color = "#0072B2") + 
  geom_point() + 
  geom_smooth(method=lm, formula = y ~ x - 1, se=FALSE, color = "#0072B2") +
  geom_abline(intercept = 0, slope = 1, linetype = 2) + 
  annotate("text", x=x_pos, y=y_pos1, label = as.character(lm_eqn_labeled(workersByCounty)), color = "#0072B2", size = 4) +
  geom_text(x=x_pos, y=y_pos2, label = "- - - - : 45 Deg Line",  parse = FALSE, color = "black") +
  geom_label(data=workersByCounty, aes(label=county_name), nudge_y = 60000) + 
  labs(x="Employment", y="Workers", colour="County", title="Workers vs Employment by County") +
  theme(legend.position="none")

ggsave(file="workersByCounty.jpeg", width=12, height=10)

write.csv(workersByCounty, "workersByCounty.csv", row.names = TRUE)

# -------------------------------------------
# Workers vs Employment by TAZ
print("Creating Workers vs Employment for all occupations and tazs...")

employmentbyTAZ <- land_use %>%
  select(ZONE, COUNTY, tot_emp)

workersByTAZ <- workers %>%
  group_by(workplace_zone_id_taz) %>%
  summarize(tot_workers = sum(finalweight)) %>%
  left_join(employmentbyTAZ, by = c("workplace_zone_id_taz" = "ZONE")) %>%
  select(workplace_zone_id_taz, COUNTY, tot_workers, tot_emp)

workersByTAZ$county_name <- countynames$name[match(workersByTAZ$COUNTY, countynames$code)]

workersByTAZ$x <- workersByTAZ$tot_emp
workersByTAZ$y <- workersByTAZ$tot_workers
workersByTAZ$color_var <- workersByTAZ$county_name

title <- "All TAZs By County"
save_name <- "workersByTAZ_County.jpeg"
createMultiColorScatter(df=workersByTAZ, color_label="County", title, save_name)

title <- "All TAZs"
save_name <- "workersByTAZ.jpeg"
createSingleColorScatter(df=workersByTAZ, title, save_name)

workersByTAZ$work_to_job_ratio <- workersByTAZ$tot_workers / workersByTAZ$tot_emp
avg_work_to_job_ratio <- mean(workersByTAZ$work_to_job_ratio)

write.csv(workersByTAZ, "workersByTAZ.csv", row.names = TRUE)

# -------------------------------------------
# Workers vs Employment by Occupation for each TAZ
print("Creating Workers vs Employment for all income groups...")

# Pre-compute the sum of size term factors across all income groups for each
# employment category. Used to normalize employment in both the combined and
# per-income-group plots.
factor_sums <- colSums(income_factors[, employment_categories])

# Write normalized size terms to CSV for reference
normalized_factors_df <- income_factors[, c("segment", employment_categories)]
for (emp_cat in employment_categories){
  normalized_factors_df[emp_cat] <- ifelse(factor_sums[emp_cat] > 0,
                                           income_factors[[emp_cat]] / factor_sums[emp_cat],
                                           0)
}
write.csv(normalized_factors_df, "normalized_size_terms.csv", row.names = FALSE)

# Normalize size terms within each income segment across employment categories.
# These shares are used to distribute model workers by category without
# inflating totals when categories are summed back up.
worker_allocation_shares_df <- income_factors[, c("income_segment", "segment", employment_categories)]
for (r in seq_len(nrow(worker_allocation_shares_df))){
  row_sum <- sum(as.numeric(worker_allocation_shares_df[r, employment_categories]))
  if (row_sum > 0){
    worker_allocation_shares_df[r, employment_categories] <-
      as.numeric(worker_allocation_shares_df[r, employment_categories]) / row_sum
  } else {
    worker_allocation_shares_df[r, employment_categories] <- 0
  }
}
write.csv(worker_allocation_shares_df, "worker_allocation_shares.csv", row.names = FALSE)

employmentbyOcc <- land_use %>%
  select(ZONE, employment_categories) %>%
  melt(id="ZONE") %>%
  rename(emp_cat = variable, num_emp = value)

workersByOccInc <- workers %>%
  group_by(workplace_zone_id_taz, income_segment) %>%
  summarize(tot_workers = sum(finalweight)) %>%
  left_join(income_factors, by=("income_segment")) %>%
  select(workplace_zone_id_taz, income_segment, tot_workers, employment_categories)

# distributing taz workers into employment categories based on destination_choice_size_terms
for (i in seq(length(employment_categories))){
  emp_cat <- employment_categories[i]
  workersByOccInc[emp_cat] <- round(
    workersByOccInc$tot_workers *
      worker_allocation_shares_df[[emp_cat]][match(workersByOccInc$income_segment,
                                                   worker_allocation_shares_df$income_segment)]
  )
}

workersByOcc <- workersByOccInc %>%
  group_by(workplace_zone_id_taz) %>%
  select(workplace_zone_id_taz, employment_categories)

workersByOcc <- as.data.frame(workersByOcc)
workersByOcc <- workersByOcc %>%
  melt(id = "workplace_zone_id_taz") %>%
  rename(emp_cat = variable, tot_workers = value) %>%
  left_join(employmentbyOcc, by = c("workplace_zone_id_taz" = "ZONE", "emp_cat" = "emp_cat")) %>%
  rename(tot_emp = num_emp)
  
workersByOcc$x <- workersByOcc$tot_emp
workersByOcc$y <- workersByOcc$tot_workers
workersByOcc$color_var <- workersByOcc$emp_cat
# Note: for the combined (all income groups) plot, normalized employment per
# category equals raw employment, because the four income groups' cross-normalized
# shares sum to 1.0 per category. So x = raw employment is already the correct
# normalized scale for this combined view.

title <- "All Income Groups"
save_name <- "workers_incAll.jpeg"
createMultiColorScatter(df=workersByOcc, color_label="Employment Category", title, save_name)

write.csv(workersByOcc, "workers_incAll.csv", row.names = TRUE)

# for (emp_cat in employment_categories){
#  workersSingleOcc <- workersByOcc[workersByOcc$emp_cat == emp_cat,]
#  title <- paste("Employment Category ", emp_cat, sep="")
#  save_name <- paste("workers_incAll_",emp_cat,".jpeg", sep="")
#  createSingleColorScatter(workersSingleOcc, title, save_name)
# }


# -------------------------------------------
# Workers vs Employment by Occupation and income group for each TAZ
print("Creating Workers vs Employment for individual income groups...")

employmentbyInc <- land_use %>%
  select(ZONE, employment_categories)

# (factor_sums and normalized_factors_df already computed above)

i <- 0
for (inc_seg in unique(workersByOccInc$income_segment)){
  i <- i + 1
  workersByOccInc_i <- workersByOccInc[workersByOccInc$income_segment == inc_seg,]
  income_factors_i <- income_factors[income_factors$income_segment == inc_seg,]
  employmentbyInc_i <- employmentbyInc
  
  # Normalize employment by cross-income-group share:
  # share_i(cat) = factor_i(cat) / sum_across_all_groups(factor(cat))
  # This means the four income groups' x-axes sum to raw total employment,
  # so absolute worker counts and employment are on the same scale.
  for (emp_cat in employment_categories){
    share_i <- ifelse(factor_sums[emp_cat] > 0,
                      income_factors_i[[emp_cat]] / factor_sums[emp_cat],
                      0)
    employmentbyInc_i[emp_cat] <- round(employmentbyInc[emp_cat] * share_i)
  }
  
  employmentbyInc_i <- employmentbyInc_i %>%
    melt(id = "ZONE") %>%
    rename(emp_cat = variable, tot_emp = value)
  
  workersByOccInc_i <- data.frame(workersByOccInc_i)
  workersByOccInc_i <- workersByOccInc_i %>%
    select(workplace_zone_id_taz, employment_categories)%>%
    melt(id = "workplace_zone_id_taz") %>%
    rename(emp_cat = variable, tot_workers = value) %>%
    left_join(employmentbyInc_i, by=c("workplace_zone_id_taz" = "ZONE", "emp_cat" = "emp_cat"))
  
  workersByOccInc_i$x <- workersByOccInc_i$tot_emp
  workersByOccInc_i$y <- workersByOccInc_i$tot_workers
  workersByOccInc_i$color_var <- workersByOccInc_i$emp_cat

  title <- paste("Income Segment ", i,"", sep="")
  save_name <- paste("workersByEmpCat_inc",i,".jpeg", sep="")
  createMultiColorScatter(df=workersByOccInc_i, color_label="Employment Category", title, save_name)

  csv_name <- paste("workersByEmpCat_inc",i,".csv", sep="")
  write.csv(workersByOccInc_i, csv_name, row.names = TRUE)
   
#  for (emp_cat in employment_categories){
#    workersSingleOccInc_i <- workersByOccInc_i[workersByOccInc_i$emp_cat == emp_cat,]
#    title <- paste("Employment Category ", emp_cat, sep="")
#    save_name <- paste("workers_inc",i,"_",emp_cat,".jpeg", sep="")
#    createSingleColorScatter(workersSingleOccInc_i, title, save_name)
#  }
    
  workersByInc_i <- workersByOccInc_i %>%
    select(workplace_zone_id_taz, tot_emp, tot_workers) %>%
    group_by(workplace_zone_id_taz) %>%
    summarize_at(c("tot_emp", "tot_workers"), sum) %>%
    mutate(x = tot_emp) %>%
    mutate(y = tot_workers)
  
  title <- paste("Income Group ", i, " Total Employment", sep="")
  save_name <- paste("workers_inc",i,"_total.jpeg", sep="")
  createSingleColorScatter(workersByInc_i, title, save_name)

  csv_name <- paste("workers_inc",i,"_total.csv", sep="")
  write.csv(workersByInc_i, csv_name, row.names = TRUE)
}


end_time <- Sys.time()
end_time - start_time
cat("\n Script finished, run time: ", end_time - start_time, "sec \n")

# finish
