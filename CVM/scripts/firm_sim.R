
# Master function for executing the synthesis of firms.
firm_sim <- function(Establishments) {
  
  # Begin progress tracking
  progressStart(action = "Simulating...", task = "Firms", dir = SCENARIO_LOG_PATH, subtasks = FALSE)
  
  # Define run_steps if it is not already in the environment (default to running all steps)
  if(!exists("run_step")) run_step <- rep(TRUE, 2)

  if(run_step[2]){
    # Different approach in base and future scenarios: base year start from start,
    # future year build on base year scaled firm list
    
    if(SCENARIO_BASESCENARIO == 1){
      
      cat("Creating Base Year Establishment List", "\n")
      
      # Add a business ID variable
      Establishments[, BusID := .I]
      
      # Add employment classifications
      Establishments[UEmpCats, 
            c("EmpCatName", "EmpCatGroupedName") := .(i.EmpCatName, i.EmpCatGroupedName),
            on = c("EmpCatID")]
      
      # Scale firms to TAZ employment forecasts
      cat("Scaling Base Year Establishments to Match Base Year TAZ Emplyoment", "\n")
      ScenarioFirms <- scaleEstablishmentsTAZEmployment(RegionFirms = Establishments, 
                                            TAZEmployment = TAZEmployment[TAZ %in% BASE_TAZ_INTERNAL], 
                                            NewFirmsProportion = BASE_NEW_FIRMS_PROP,
                                            MaxBusID = max(Establishments$BusID),
                                            EstSizeCategories = EstSizeCategories)
      
      BaseYearFirms <- copy(ScenarioFirms)
      
      # Future year
    } else {
      if(file.exists(SCENARIO_BASEFIRMS)){
        # Load the output from the base year firm synthesis model
        cat("Loading Base Year Establishment List", "\n")
        load(SCENARIO_BASEFIRMS)
        BaseYearFirms <- firm_sim_results$BaseYearFirms
        
        # Scale firms to TAZ employment forecasts
        cat("Scaling Base Year Establishment List to Match TAZ Employment Forecasts", "\n")
        ScenarioFirms <- scaleEstablishmentsTAZEmployment(RegionFirms = BaseYearFirms, 
                                                  TAZEmployment = TAZEmployment[TAZ %in% BASE_TAZ_INTERNAL], 
                                                  NewFirmsProportion = BASE_NEW_FIRMS_PROP,
                                                  MaxBusID = max(BaseYearFirms$BusID),
                                                  EstSizeCategories = EstSizeCategories)
        
      } else {
        
        stop("No Base Scenario outputs available. Please run the Base Scenario first.")
        
      }
    }
  } # End Step
  
  # End progress tracking
  progressEnd(dir = SCENARIO_LOG_PATH)
  
  # Return results
  if(USER_RUN_MODE == "Calibration"){
    return(get(submodel_results_name))
  } else {
    return(list(ScenarioFirms = ScenarioFirms, 
              BaseYearFirms = BaseYearFirms, 
              TAZLandUseCVTM = TAZLandUseCVTM))
  }
}
