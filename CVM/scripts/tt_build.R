
#Aggregates freight and commercial vehicle trips into trip tables for use with assignment model
tt_build <- function(data = NULL) {
  
  # Begin progress tracking
  progressStart(action = "Writing...", task = "Trip Tables", dir = SCENARIO_LOG_PATH, subtasks = FALSE)
  
  ### Select just the internal portions of cv_trips
  cat("Aggregating Commercial Vehicle Tours to OD Trips", "\n")
  # Trips portions to select:
  # 1. Complete within region trip from OTAZ to DTAZ
  # 2. For buffer to region: from EXT to DTAZ
  # 3. For region to buffer: from OTAZ to EXT
  # 4. For buffer traversing region: from EXT1 to EXT2
  # 5. For within buffer: exclude completely
  cv_trips_region <- rbind(cv_trips[SKIMTYPE == "Within SEMCOG",.(OTAZ, DTAZ, Vehicle, TOD)],
                           cv_trips[SKIMTYPE == "Buffer to SEMCOG", .(OTAZ = EXT, DTAZ, Vehicle, TOD)],
                           cv_trips[SKIMTYPE == "SEMCOG to Buffer", .(OTAZ, DTAZ = EXT, Vehicle, TOD)],
                           cv_trips[SKIMTYPE == "Buffer traversing SEMCOG", .(OTAZ = EXT1, DTAZ = EXT2, Vehicle, TOD)])

  ### Aggregate cv_trips up to a trip table
  cv_trips_bind <- cv_trips_region[, .(trips = .N),
                               by = .(OTAZ, DTAZ, Vehicle, TOD)]
  
  ### Prepare ld_trips for use in trip tables
  cat("Combining Commercial Vehicle Trips and Long Distance Trips", "\n")
  ld_trips_bind <- ld_trips[trips > 0 & !is.na(trips)]
  
  ### Aggregate up to a trip table and write results as a set of OMX matrices
  TripTable <- rbind(cv_trips_bind[, Source := "CV"], 
                     ld_trips_bind[, Source := "LD"])
  
  setkeyv(TripTable, c("OTAZ", "DTAZ", "Vehicle", "TOD"))
  
  # Create a table of matrix names and types consistent with the SEMCOG model
  # Currently there are commercial vehicle trip tables for each combination of
  # Light, Medium, Heavy trucks and the five time periods plus daily totals, for 18 tables
  vehicletypes <- c("Light", "Medium", "Heavy")
  todlabels <- names(BASE_TOD_RANGES)
  
  matnames <- paste(rep(c(todlabels, "Daily"), length(vehicletypes)),
                    rep(vehicletypes, each = length(todlabels)+1),
                    "Truck")
  
  outputMatrices <- data.table(matname = matnames,
                               vehicletype = rep(vehicletypes, each = length(todlabels)+1),
                               tod = rep(c(todlabels, "all"), length(vehicletypes)))
  
  outputMatrices[, matrix_description := paste(SCENARIO_NAME, tod, vehicletype, "CV matrix")]
  
  outputMatrices[, omxoutputpath := rep(c(file.path(SCENARIO_ASSIGN_PATH, paste0("OD_", c(todlabels, "DY"), ".OMX"))), length(vehicletypes))]
  
  outputMatrices[, matname_short := paste(rep(vehicletypes, each = length(todlabels)+1),"Truck")]
  
  if(USER_SAVE_COMBINED_OD_TABLES){
    # Write the CV trip tables to a single OMX file in the CVM output folder
    cat("Write Commercial Vehicle Trips Tables to Single OMX File", "\n")
    
    write_triptables_to_omx(omxoutputpath = rep(file.path(SCENARIO_OUTPUT_PATH, "CV_Trip_Tables.omx"),
                                                nrow(outputMatrices)),
                            tazids = c(BASE_TAZ_MODEL_REGION, BASE_TAZ_EXTERNAL),
                            triptable = TripTable,
                            matnames = outputMatrices$matname,
                            matdescriptions = outputMatrices$matrix_description,
                            dim1name = "TOD",
                            dim2name = "Vehicle",
                            dim1 = outputMatrices$tod,
                            dim2 = outputMatrices$vehicletype)
  }
  
  # Write the CV trip tables to the seperate time of day specific OMX files for assignment
  # Also add the daily CV trip tables to the daily summary file
  # Each one needs a light, medium, and heavy trip table
  # Use create_omx = FALSE to add to the existing omx files
  cat("Add Commercial Vehicle Trips Tables to Time Period and Daily OMX Files", "\n")
  
  tt_list <- write_triptables_to_omx(omxoutputpath = outputMatrices$omxoutputpath,
                                       tazids = c(BASE_TAZ_MODEL_REGION, BASE_TAZ_EXTERNAL),
                                       triptable = TripTable,
                                       matnames = outputMatrices$matname_short,
                                       matdescriptions = outputMatrices$matrix_description,
                                       dim1name = "TOD",
                                       dim2name = "Vehicle",
                                       dim1 = outputMatrices$tod,
                                       dim2 = outputMatrices$vehicletype,
                                       create_omx = FALSE,
                                       number_cores = USER_PROCESSOR_CORES)
  
  # Add the TripTable to the matrix list for saving
  tt_list[["TripTable"]] <- TripTable
  
  # End progress tracking
  progressEnd(dir = SCENARIO_LOG_PATH)
  
  return(tt_list)
}
