
# Long Distance trip distribution for IE and EI trips
ld_sim_distribution <- function(zoneProdsAttrs, skims_dist, ld_distribution_model) {
  
  progressUpdate(subtaskprogress = 0, subtask = "Trip Distribution IE & EI", prop = 1/4, dir = SCENARIO_LOG_PATH)
  
  # Create skeleton dataset to iterate over
  
  allTAZVec <- zoneProdsAttrs[, TAZ]
  
  IE_EI_Trips <- as.data.table(expand.grid(OTAZ = allTAZVec, 
                                           DTAZ = allTAZVec))
  
  # Filter to only include IE or EI trips. 
  # II trips are modeled in the CVTM. 
  # EE trips are handled in a later step of the LDM.
  
  IE_EI_Trips <- IE_EI_Trips[(OTAZ %in% BASE_TAZ_MODEL_REGION & DTAZ %in% BASE_TAZ_EXTERNAL) |
                         (OTAZ %in% BASE_TAZ_EXTERNAL & DTAZ %in% BASE_TAZ_MODEL_REGION)]
  
  IE_EI_Trips[zoneProdsAttrs[,.(OTAZ = TAZ, tripGen)],
              Prod := i.tripGen,
              on = "OTAZ"]
  
  IE_EI_Trips[zoneProdsAttrs[,.(DTAZ = TAZ, tripAttr)],
              Attr := i.tripAttr,
              on = "DTAZ"]
  
  # Add distance for impendance calculation
  IE_EI_Trips[skims_dist,
              Distance := i.dist,
              on = c("OTAZ", "DTAZ")]
  
  # Doubly constrained gravity model
  # Conserve TAZ totals at the origin and destination end
  # Distribute using friction factors with gamma function
  # Impedance a function of distance from external station to internal TAZ (or vice versa)
  
  ff_a <- ld_distribution_model[Variable == "ff_a"]$Coefficient
  ff_b <- ld_distribution_model[Variable == "ff_b"]$Coefficient
  ff_c <- ld_distribution_model[Variable == "ff_c"]$Coefficient
  
  IE_EI_Trips[, trips := applyGravModel(ff_a, ff_b, ff_c, dat = copy(IE_EI_Trips))]
  
  # Remove excess columns and round numbers of trips to integers
  IE_EI_Trips[, c("Prod", "Attr", "Distance") := NULL]
  setcolorder(IE_EI_Trips, c("OTAZ", "DTAZ", "trips"))
  setkey(IE_EI_Trips, OTAZ, DTAZ)
  
  progressUpdate(subtaskprogress = 1, subtask = "Trip Distribution IE & EI", prop = 1/4, dir = SCENARIO_LOG_PATH)
  
  return(IE_EI_Trips)
  
}

# Function to apply doubly constraint gravity model and return trips
applyGravModel <- function(ff_a, ff_b, ff_c, dat){
  
  # Build the friction factor matrix for all IE/EI
  dat[, FF_Distance := ff_a * (Distance ^ -ff_b) * exp(-ff_c * Distance)]
  
  # Calculate gravity model terms
  dat[, GMTrips := Attr * FF_Distance/sum(Attr * FF_Distance) * Prod, by = OTAZ]
  
  # Doubly Constrain the Modeled Trips
  # Constrain on Attractions
  dat[, Trips := GMTrips]
  
  for (i in 1:10){
    
    dat_dtrips <- dat[, .(Attr = min(Attr), DTrips = sum(Trips)), keyby = DTAZ]
    dat_dtrips[, DAdj := ifelse(DTrips > 0, Attr/DTrips, 1)]
    dat[dat_dtrips, DAdj := i.DAdj, on = "DTAZ"]
    dat[, Trips := Trips * DAdj]
    
    # Constrain on Destinations
    dat_otrips <- dat[, .(Prod = min(Prod), OTrips = sum(Trips)), keyby = OTAZ]
    dat_otrips[, OAdj := ifelse(OTrips > 0, Prod/OTrips, 1)]
    dat[dat_otrips, OAdj := i.OAdj, on = "OTAZ"]
    dat[, Trips := Trips * OAdj]
    
  }
  
  return(dat$Trips)
 
}

