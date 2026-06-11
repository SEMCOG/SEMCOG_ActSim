
# Long Distance trip distribution for EE trips passing through the model region
ld_sim_throughtrips <- function(ld_ee_trip_table, ld_ee_dailytrucks_region, ld_externals) {
  
  progressUpdate(subtaskprogress = 0, subtask = "Trip Distribution EE", prop = 1/4, dir = SCENARIO_LOG_PATH)
  
  ### For foreasting (Scenarios other than Base), apply region to region factors to EE trips.
  if(SCENARIO_BASESCENARIO == 0){
    
    # apply scale factors derived from ld_ee_dailytrucks_region to grow base year EE trips
    ld_ee_trip_table[ld_ee_dailytrucks_region, 
                     Growth := i.Growth,
                     on = "xx_movement_num"]
    
    ld_ee_trip_table[is.na(Growth), Growth := 1]
    
    ld_ee_trip_table[, trips := trips * Growth]
    
    ld_ee_trip_table[, Growth := NULL]
    
  }
  
  ### Reallocate amongst externals if required (e.g., if scenario includes new external)
  
  # add key fields for the base taz
  ld_ee_trip_table <- merge(ld_ee_trip_table, 
                            ld_externals[,.(OTAZ = TAZ, OBaseTAZ = BaseTAZ, OScenarioProp = ScenarioProp)],
                            by = "OTAZ",
                            allow.cartesian = TRUE)
  
  ld_ee_trip_table <- merge(ld_ee_trip_table, 
                            ld_externals[,.(DTAZ = TAZ, DBaseTAZ = BaseTAZ, DScenarioProp = ScenarioProp)],
                            by = "DTAZ",
                            allow.cartesian = TRUE)
  
  # merge the current trip numbers on by base taz and the apply the proportions
  ld_ee_trip_table[ld_ee_trip_table[,.(OBaseTAZ = OTAZ, DBaseTAZ = DTAZ, trips)],
                   tripsBase := i.trips,
                   on = c("OBaseTAZ", "DBaseTAZ")]
  
  ld_ee_trip_table[, tripsAllocated := tripsBase * OScenarioProp * DScenarioProp]
  
  # sum over OTAZ, DTAZ to remove any duplication due to multiple allocation factors
  ld_ee_trip_table <- ld_ee_trip_table[, .(trips = sum(tripsAllocated)), keyby = .(OTAZ, DTAZ)]
  
  progressUpdate(subtaskprogress = 1, subtask = "Trip Distribution EE", prop = 1/4, dir = SCENARIO_LOG_PATH)
  
  ### return the ee trip table, with OTAZ, DTAZ, and trips
  return(ld_ee_trip_table[, .(OTAZ, DTAZ, trips)])
  
}
