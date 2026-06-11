
# This function loads all necessary inputs into envir, after any needed
# transformations
tt_process_inputs <- function(envir){
  
  ### Load project input files
 
  ### Load inputs/outputs from earlier steps
  load(file.path(SCENARIO_OUTPUT_PATH, SYSTEM_LDM_OUTPUTNAME))
  envir[["ld_trips"]] <- ld_sim_results$ld_trips

  load(file.path(SCENARIO_OUTPUT_PATH, SYSTEM_CVTM_OUTPUTNAME))
  envir[["cv_trips"]] <- cv_sim_results$cv_trips
  
}