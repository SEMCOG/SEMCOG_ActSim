
# This function loads all necessary inputs into envir, after any needed transformations
ld_sim_process_inputs <- function(envir) {
  
  ### Load project input files
  project.files <- c(ld_sim_generation          = file.path(SYSTEM_SCRIPTS_PATH, "ld_sim_generation.R"),
                     ld_sim_distribution        = file.path(SYSTEM_SCRIPTS_PATH, "ld_sim_distribution.R"),
                     ld_sim_throughtrips        = file.path(SYSTEM_SCRIPTS_PATH, "ld_sim_throughtrips.R"),
                     ld_sim_veh_type_time_split = file.path(SYSTEM_SCRIPTS_PATH, "ld_sim_veh_type_time_split.R"),
                     ld_internal_gen_model      = file.path(SYSTEM_DATA_PATH, "ld_internal_gen_model.RDS"),
                     ld_external_model          = file.path(SYSTEM_DATA_PATH, "ld_external_model.csv"),
                     ld_distribution_model      = file.path(SYSTEM_DATA_PATH, "ld_distribution_model.csv"),
                     ld_ee_trip_table           = file.path(SYSTEM_DATA_PATH, "ld_ee_trip_table.csv"),
                     ld_trip_props              = file.path(SYSTEM_DATA_PATH, "ld_trip_time_vehicle_proportions.csv"),
                     TAZ_System                 = file.path(SYSTEM_DATA_PATH, "TAZ_System.csv"))
  
  loadInputs(files = project.files, envir = envir)
  
  ### Load inputs/outputs from earlier steps
  load(file.path(SCENARIO_OUTPUT_PATH, SYSTEM_FIRMSYN_OUTPUTNAME))
  envir[["TAZLandUseCVTM"]] <- firm_sim_results$TAZLandUseCVTM
  envir[["TAZSocioEconomics"]] <- firm_inputs$TAZSocioEconomics
  
  ### Load scenario input files
  scenario.files <- c(Facilities = SCENARIO_FACILITIES,
                      ld_ieei_dailytrucks_region  = SCENARIO_CVM_IEEI,
                      ld_ee_dailytrucks_region  = SCENARIO_CVM_EE,
                      ld_externals = SCENARIO_CVM_EXTERNAL)
  loadInputs(files = scenario.files, envir = envir)
  
  ### Process scenario input files
  
  # limit the facilities file to just facilities that were built before the scenario year
  # facilities file can include future facilities and they should be filtered out
  
  # There is (currently) no defined scenario year variable, but the 
  # ld_ee_dailytrucks_region table (SCENARIO_CVM_EE) contains the scenario year
  SCENARIO_YEAR <-  as.integer(envir[["ld_ee_dailytrucks_region"]]$Year[1])
  
  # Clean the year built field: replace NAs and any 9999 with 2018
  # and allow for any facilities built upto 2019 for any scenario year before 2020
  envir[["Facilities"]][is.na(YearBuilt) | YearBuilt == 9999, YearBuilt := 2018]
  envir[["Facilities"]] <- envir[["Facilities"]][YearBuilt <= SCENARIO_YEAR | (SCENARIO_YEAR < 2020 & YearBuilt < 2020)]
  
  ### Load skims
  
  # Import a representative distance skim.
  skims_dist <- omx_to_dt(matrix_name = SCENARIO_LD_SKIM_DIST, 
            matrix_path = SCENARIO_LD_SKIM_PATH, 
            value_col_name = "dist", 
            row_lookup_name = "ZoneID", 
            col_lookup_name = "ZoneID")
  
  # Apply TAZ penalities if any specified
  # data.frame with TAZ and Penalty
  if(exists("BASE_TAZ_PENALTY")){
    for(i in 1:nrow(BASE_TAZ_PENALTY)){
      skims_dist[(OTAZ == BASE_TAZ_PENALTY$TAZ[i] | DTAZ == BASE_TAZ_PENALTY$TAZ[i]) & dist > 0, 
                      dist := dist + BASE_TAZ_PENALTY$Penalty[i]]    
    }
  }

  envir[["skims_dist"]] <- skims_dist
  
  gc()
  
}
