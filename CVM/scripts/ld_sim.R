
# Simulate [l]ong [d]istance freight movements
ld_sim <- function(data = NULL) {
  
  # Begin progress tracking
  progressStart(action = "Simulating...", task = "Long Distance Movements", dir = SCENARIO_LOG_PATH, subtasks = FALSE)
  
  # Define run_steps if it is not already in the environment (default to running all steps)
  if(!exists("run_step")) run_step <- rep(TRUE, 4)
  
  if(run_step[1]){
    # Perform trip generation to produce productions and attractions
    cat("Estimating Long Distance Productions and Attractions", "\n")
    zoneProdsAttrs <- ld_sim_generation(TAZLandUseCVTM = TAZLandUseCVTM,
                                        TAZ_System = TAZ_System,
                                        Facilities = Facilities,
                                        skims_dist = skims_dist,
                                        ld_internal_gen_model = ld_internal_gen_model, 
                                        ld_external_model = ld_external_model, 
                                        ld_ieei_dailytrucks_region = ld_ieei_dailytrucks_region,
                                        ld_externals = ld_externals)
    gc()
  
  }
  
  if(run_step[2]){
    # Perform trip distribution to produce IE and EI zone-to-zone trip totals
    cat("Distributing Long Distance Trips", "\n")
    IE_EI_Trips <- ld_sim_distribution(zoneProdsAttrs = zoneProdsAttrs,
                                       skims_dist = skims_dist,
                                       ld_distribution_model = ld_distribution_model)
    gc()
  }
  
  if(run_step[3]){
    # Scale observed truck flows from base year to find EE zone-to-zone trip totals
    cat("Forecasting Long Distance External to External Trips", "\n")
    EE_Trips <- ld_sim_throughtrips(ld_ee_trip_table = ld_ee_trip_table,
                                    ld_ee_dailytrucks_region = ld_ee_dailytrucks_region,
                                    ld_externals = ld_externals)
    gc()
  }
  
  if(run_step[4]){
    # Split long distance trips by vehicle type and time-of-day
    cat("Allocating Long Distance Trips to Vehicles and Time of Day", "\n")
    ld_trips <- ld_sim_veh_type_time_split(IE_EI_Trips = IE_EI_Trips,
                                           EE_Trips = EE_Trips,
                                           ld_trip_props = ld_trip_props)
    gc()
  }
  
  # End progress tracking
  progressEnd(dir = SCENARIO_LOG_PATH)
  
  if(USER_RUN_MODE == "Calibration"){
    return(get(submodel_results_name))
  } else {
    return(list(ld_trips = ld_trips, 
                zoneProdsAttrs = zoneProdsAttrs))
  }
  
}