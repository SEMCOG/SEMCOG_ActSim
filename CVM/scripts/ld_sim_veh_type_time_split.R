
# Long Distance trip splitting by time-of-day and vehicle type
ld_sim_veh_type_time_split <- function(IE_EI_Trips, EE_Trips, ld_trip_props) {
  
  progressUpdate(subtaskprogress = 0, subtask = "Split Trips by Time and Vehicle Type", prop = 1/4, dir = SCENARIO_LOG_PATH)
  
  ld_trips <- rbind(IE_EI_Trips, EE_Trips)
  
  # Aggregate the trip proportions into the times of day used by the model
  # Create a table with rows for each TOD and vehicle type combination with a percentage of total LD trips
  # The input ld_trip_props should have a row for each 30 minutes increment and a column for each vehicle type
  # The cell values should be a percentage of total LD trips
  
  ld_trip_props <- melt.data.table(ld_trip_props,
                                   id.vars = c("start_minutes", "end_minutes"),
                                   variable.name = "vehicle_type",
                                   value.name = "vehicle_prop")
  
  ld_trip_props[, time_of_day := getSkimTOD(start_minutes, BASE_TOD_RANGES, FALSE)]
  
  ld_trip_props <- ld_trip_props[, .(vehicle_prop = sum(vehicle_prop)), 
                                 by = .(time_of_day, vehicle_type)]
  
  # Apply time-of-day and vehicle type proportions derived from 24-hour truck counts
  
  create_split_trip_table <- function(veh_type, tod){
  
    temp_tt <- copy(ld_trips)
    temp_factor <- ld_trip_props[vehicle_type == veh_type &
                                   time_of_day == tod,
                                 vehicle_prop]
    temp_tt[, trips := trips * temp_factor]
    temp_tt[, Vehicle := veh_type]
    temp_tt[, TOD := tod]
    return(temp_tt)
    
  }
  
  tt_list <- mapply(create_split_trip_table,
                    tod = ld_trip_props$time_of_day,
                    veh_type = ld_trip_props$vehicle_type,
                    SIMPLIFY = FALSE)
  
  ld_trips <- rbindlist(tt_list)
  
  progressUpdate(subtaskprogress = 1, subtask = "Split Trips by Time and Vehicle Type", prop = 1/4, dir = SCENARIO_LOG_PATH)
  
  return(ld_trips)
  
}