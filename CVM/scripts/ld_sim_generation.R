
# Long Distance trip generation
ld_sim_generation <- function(TAZLandUseCVTM, TAZ_System, Facilities, skims_dist, 
                              ld_internal_gen_model, ld_external_model, 
                              ld_ieei_dailytrucks_region, ld_externals) {
  
  progressUpdate(subtaskprogress = 0, subtask = "Trip Generation", prop = 1/4, dir = SCENARIO_LOG_PATH)
  
  ### Prepare explanatory variables for regression models
  
  # Variables required for internal_gens_model and 
  # internal_attrs_model (same model specification applied):
  # "IndustrialSc"
  # "ProductionSc"
  # "TransportationSc"                
  # "NFac_RailTruckSc"
  # "NFac_LandfillSc"
  # "DistFloorSpace_LargeKFtSc"       
  # "DistFloorSpace_MediumKFtSc"
  # "Dist_Airport_Prod_EmpSc"
  # "Dist_Interstate_EmpSc"           
  # "Dist_I75_Ambassador_EmpSc"        
  # "Dist_I75_Ambassador_Large_DistSc"
  
  ### Process the facilities table
  
  # Calculate the number of facilities by type by TAZ
  # Calculate the distribution center and warehouse floorspace in the TAZ
  
  Facilities[, FacilityTy := factor(FacilityTy, levels = c("Warehouse/Distribution", "Industrial/Research/Hi-Tech", 
                                                           "Airport", "Rail-Truck Terminal", "Water-Truck Terminal",
                                                           "Sand/Gravel", "Landfill", "Energy"))]
  
  FacilityTyShort <- c("Distribution", "Industrial", 
                       "Airport", "RailTruck", "WaterTruck",
                       "SandGravel", "Landfill", "Energy")
  
  Facilities[, FacilityTy := factor(FacilityTy, labels = FacilityTyShort)]
  
  # Categorization of distribution centers into small, medium, large
  Facilities[FacilityTy == "Distribution", 
             DistCenterSize := c("Small", "Medium", "Large")[findInterval(FloorSpace, 
                                                                          vec = c(0,50000,200000))]]
  
  # Facility totals by TAZ
  Facilities_TAZ <- Facilities[,.(Facilities = .N, FloorSpace = sum(FloorSpace, na.rm = TRUE)), 
                               by = .(TAZ, FacilityTy, DistCenterSize) ]
  
  # Facility totals by TAZ, wide table by facility type
  Facilities_TAZ_w <- dcast.data.table(Facilities_TAZ, 
                                       TAZ~FacilityTy, 
                                       fun.aggregate = sum, 
                                       value.var = "Facilities")
  
  setnames(Facilities_TAZ_w, 
           c("TAZ", paste0("NFac_", names(Facilities_TAZ_w)[2:ncol(Facilities_TAZ_w)])))
  
  # Add number of facilities by type to grouped TAZ employment data
  tripGenExplain <- merge(TAZLandUseCVTM,
                          Facilities_TAZ_w,
                          by = "TAZ",
                          all.x = TRUE)
  
  # Add distribution center floor space to grouped TAZ employment data
  tripGenExplain[Facilities_TAZ[FacilityTy == "Distribution", 
                                .(FloorSpace = sum(FloorSpace)), 
                                by = TAZ], 
                 DistributionFloorSpace := i.FloorSpace, 
                 on = "TAZ"]
  
  # Add distribution floorspace by small, medium, large distribution centers
  Facilities_TAZ_DistSize <- dcast.data.table(Facilities_TAZ[FacilityTy == "Distribution"], 
                                              TAZ~DistCenterSize, 
                                              fun.aggregate = sum, 
                                              value.var = "FloorSpace")
  
  setnames(Facilities_TAZ_DistSize, 
           c("TAZ", paste0("DistFloorSpace_", names(Facilities_TAZ_DistSize)[2:ncol(Facilities_TAZ_DistSize)])))
  
  tripGenExplain <- merge(tripGenExplain,
                          Facilities_TAZ_DistSize,
                          by = "TAZ",
                          all.x = TRUE)
  
  tripGenExplain[is.na(tripGenExplain)] <- 0
  
  # Scale distribution center floorspace so that it in thousands of square feet
  tripGenExplain[, DistributionFloorSpaceKFt := DistributionFloorSpace/1000]
  tripGenExplain[, DistFloorSpace_LargeKFt := DistFloorSpace_Large/1000]
  tripGenExplain[, DistFloorSpace_MediumKFt := DistFloorSpace_Medium/1000]
  tripGenExplain[, DistFloorSpace_SmallKFt := DistFloorSpace_Small/1000]

  ### Process distance skims and create proximity variables
  
  skims_dist <- add_od_fields(dt_od = skims_dist, tbl = TAZ_System, 
                fieldsToAdd = c("TAZ_IE", "StationName", "StationType"),
                fieldsNewNames = c("TYPE", "ExtSt", "ExtStType"))
  
  skims_dist_airport <- skims_dist[OTYPE == "INTERNAL" & DTAZ %in% TAZ_System[AIRPORT == TRUE]$TAZ, 
                                   .(dist = min(dist)), 
                                   by = .(TAZ = OTAZ)]
  
  # Trade Route deviations: distance in excess of fastest xx from I-75 to Ambassador Bridge
  skim_ambassador <- skims_dist[OTYPE == "INTERNAL" & DExtSt == "Ambassador Bridge",
                                .(TAZ = OTAZ, dist)]
  
  skim_bluewater <- skims_dist[OTYPE == "INTERNAL" & DExtSt == "Blue Water Bridge",
                               .(TAZ = OTAZ, dist)]
  
  skim_i75 <- skims_dist[OTYPE == "INTERNAL" & DExtSt == "I-75 S",
                         .(TAZ = OTAZ, dist)]
  
  i75_ambassador <- skims_dist[OExtSt == "Ambassador Bridge" & DExtSt == "I-75 S"]$dist
  
  skim_i75_ambassador <- merge(skim_ambassador[,.(TAZ, dist_amb = dist)],
                               skim_i75[,.(TAZ, dist_i75 = dist)],
                               by = "TAZ",
                               all = TRUE)
  
  skim_i75_ambassador[, dist := dist_amb + dist_i75]
  
  skim_i75_ambassador[, dist_dev := dist - i75_ambassador]
  
  skim_regional_gateways <- skim_i75_ambassador[,.(TAZ, dist_amb, dist_i75)]
  
  skim_regional_gateways[skim_bluewater, 
                         dist_bluewater := i.dist, 
                         on = "TAZ"]
  
  skim_regional_gateways[, dist_gateway := 
                           pmin(dist_amb, dist_i75, dist_bluewater)]
  
  skim_regional_gateways[, dist_gateway_inv := 
                           log(dist_gateway)]
  
  skim_regional_gateways[, dist_gateway_inv := 
                           ifelse(dist_gateway_inv < 2, 1, 2/dist_gateway_inv)]
  
  # Add distance based spatial variables to the data
  tripGenExplain[skims_dist_airport, 
                 Dist_Airport := i.dist, 
                 on = "TAZ"]
  
  tripGenExplain[TAZ_System, 
                 Dist_Interstate := i.DistInterstate, 
                 on = "TAZ"]
  
  # Add the trade route deviation
  tripGenExplain[skim_i75_ambassador, 
                 Dist_I75_Ambassador := i.dist_dev, 
                 on = "TAZ"]
  
  # Add the scale
  tripGenExplain[skim_regional_gateways, 
                 Dist_Reg_Inv := i.dist_gateway_inv, 
                 on = "TAZ"]
  
  # Transformations on airport distance
  # for distances < 10 miles, create increasing value from 0 at 10 miles to 1 at 0 miles
  tripGenExplain[, Dist_Airport_Close := 
                   ifelse(Dist_Airport < 10,1 - Dist_Airport/10,0)]
  
  # Interact airport distance with land use so it is a bonus on a rate
  tripGenExplain[, Dist_Airport_Prod_Emp := 
                   Dist_Airport_Close * log1p(Production)]
  
  # Transformation on distance to interstate
  tripGenExplain[, Dist_Interstate_Close_Three := 
                   ifelse(Dist_Interstate < 3,1 - Dist_Interstate/3, 0)]
  
  # Interstate distance and employment (production, transportation)
  tripGenExplain[, Dist_Interstate_Emp_PT := 
                   Dist_Interstate_Close_Three * log1p(Production + Transportation)]
  
  # Interacted with land use
  tripGenExplain[, Dist_I75_Ambassador_Emp := 
                   ifelse(Dist_I75_Ambassador < 5,1,0) * log1p(Production + Transportation)]
  
  tripGenExplain[, Dist_I75_Ambassador_Large_Dist := 
                   ifelse(Dist_I75_Ambassador < 5,1,0) * log1p(DistFloorSpace_LargeKFt)]
  
  # Consistent regional scaling
  tripGenExplain[, c("IndustrialSc", 
                     "ProductionSc", 
                     "TransportationSc", 
                     "DistFloorSpace_LargeKFtSc", 
                     "DistFloorSpace_MediumKFtSc",
                     "NFac_RailTruckSc", 
                     "NFac_LandfillSc",
                     "Dist_Airport_Prod_EmpSc", 
                     "Dist_Interstate_EmpSc", 
                     "Dist_I75_Ambassador_EmpSc", 
                     "Dist_I75_Ambassador_Large_DistSc") := 
                   .(Dist_Reg_Inv * Industrial, 
                     Dist_Reg_Inv * Production, 
                     Dist_Reg_Inv * Transportation, 
                     Dist_Reg_Inv * DistFloorSpace_LargeKFt,
                     Dist_Reg_Inv * DistFloorSpace_MediumKFt,
                     Dist_Reg_Inv * NFac_RailTruck,
                     Dist_Reg_Inv * NFac_Landfill,
                     Dist_Reg_Inv * Dist_Airport_Prod_Emp,
                     Dist_Reg_Inv * Dist_Interstate_Emp_PT,
                     Dist_Reg_Inv * Dist_I75_Ambassador_Emp,
                     Dist_Reg_Inv * Dist_I75_Ambassador_Large_Dist)]
  
  ### Apply trip generation model: single model for both trips ends
  zoneProdsAttrs <- tripGenExplain[, .(TAZ)]
  
  zoneProdsAttrs[TAZ %in% BASE_TAZ_MODEL_REGION, 
                 tripGen := predict(ld_internal_gen_model, 
                                    tripGenExplain[TAZ %in% BASE_TAZ_MODEL_REGION])]
  
  zoneProdsAttrs[, tripAttr := tripGen]

  ### Apply external model to estimate external productions and attractions
  ld_external_model_m <- melt.data.table(ld_external_model[,.(TAZ, F_BUFFER_MI, F_BUFFER_OH, F_BUFFER_CAN,  F_OTHER_MI,
                                                              F_Mexico, F_US_Central, F_US_East, F_US_South, F_US_West,
                                                              F_Canada_West, F_Canada_East, F_Canada_ON, F_Canada_QC)],
                                         id.vars = "TAZ",
                                         variable.name = "Region",
                                         value.name = "Factor")
  
  ld_external_model_m[, Region := gsub("F_", "", Region, fixed = TRUE)]
  
  ld_external_model_m[ld_ieei_dailytrucks_region, DailyTrucks := i.DailyTrucks, on = "Region"]
  ld_external_model_m[, tripGen := DailyTrucks * Factor]
  
  # Exclude trips from the BUFFER regions
  ld_external_model_m[Region %in% c("BUFFER_MI", "BUFFER_OH", "BUFFER_CAN"), 
                      tripGen := 0]
  
  extProdsAttrs <- ld_external_model_m[, .(tripGen = sum(tripGen)), by = TAZ]
  
  # Reallocate amongst externals if required (e.g., if scenario includes new external)
  ld_externals[extProdsAttrs[, .(BaseTAZ = TAZ, tripGen)],
               BaseTripGen := i.tripGen,
               on = "BaseTAZ"]
  ld_externals[, ScenarioAllocation := BaseTripGen * ScenarioProp]
  
  extProdsAttrs[ld_externals[,.(tripGen = sum(ScenarioAllocation)), by = TAZ],
                tripGen := i.tripGen,
                on = "TAZ"]
  
  # See attractions (inbound) equal to generated trips (outbound)
  extProdsAttrs[, tripAttr := tripGen]
  
  ### Combine and balance the internal and external productions and attractions
  zoneProdsAttrs <- rbind(zoneProdsAttrs, 
                          extProdsAttrs, 
                          fill = TRUE)
  
  # Scaling to balance internal and external productions/attractions
  zoneProdsAttrs[, Int_Ext := ifelse(TAZ %in% BASE_TAZ_EXTERNAL, 
                                     "External", "Internal")]
  
  BalancingFactors <- zoneProdsAttrs[Int_Ext == "External",.(tripGen = sum(tripGen, na.rm = TRUE), tripAttr = sum(tripAttr, na.rm = TRUE))]/
                      zoneProdsAttrs[Int_Ext == "Internal",.(tripGen = sum(tripGen, na.rm = TRUE), tripAttr = sum(tripAttr, na.rm = TRUE))]
  
  zoneProdsAttrs[Int_Ext == "Internal", 
                 c("tripGen", "tripAttr") := 
                   .(tripGen * BalancingFactors$tripGen,
                     tripAttr * BalancingFactors$tripAttr)]
  
  zoneProdsAttrs[, Int_Ext := NULL]
  
  # Truncate results at zero, so that no negative generations or attractions are possible
  zoneProdsAttrs[tripGen < 0, 
                 tripGen := 0]
  
  zoneProdsAttrs[tripAttr < 0, 
                 tripAttr := 0]
  
  progressUpdate(subtaskprogress = 1, subtask = "Trip Generation", prop = 1/4, dir = SCENARIO_LOG_PATH)
  
  return(zoneProdsAttrs)
  
}
