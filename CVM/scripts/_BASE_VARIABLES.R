# 1. Define TAZ ranges for different elements of the model region.
TAZ_System <- read.csv(file.path(SYSTEM_DATA_PATH, "TAZ_System.csv"))
BASE_TAZ_INTERNAL <- TAZ_System[TAZ_System$INTERNAL == 1, "TAZ"] #range of TAZs that are within the SEMCOG model region including the buffer
BASE_TAZ_EXTERNAL <- TAZ_System[TAZ_System$EXTERNAL == 1, "TAZ"] #range of external station TAZs
BASE_TAZ_MODEL_REGION <- TAZ_System[TAZ_System$SEMCOG == 1, "TAZ"] #range of internal TAZs that are within the SEMCOG model region not including the buffer
BASE_TAZ_BUFFER <- TAZ_System[TAZ_System$BUFFER == 1, "TAZ"] #range of internal TAZs that are in the buffer around the outside of the SEMCOG model region
BASE_TAZ_REGION_EXTERNAL <- c(BASE_TAZ_MODEL_REGION, BASE_TAZ_EXTERNAL) #range of SEMCOG model region TAZs (internal) and externals, buffer excluded
BASE_TAZ_US <- TAZ_System[TAZ_System$COUNTRY == "US" & TAZ_System$INTERNAL == 1, "TAZ"] #range of TAZs (not external stations) that are within the US
BASE_TAZ_CANADA <- TAZ_System[TAZ_System$COUNTRY == "Canada" & TAZ_System$INTERNAL == 1, "TAZ"] #range of TAZs (not external stations) that are in Canada
BASE_TAZ_COMPLETE <- TAZ_System$TAZ #full set of valid TAZs

rm(TAZ_System)

# 2. Define application base scenario name
BASE_SCENARIO_BASE_NAME <- "SEMCOG_ABM_2"   #"2015_KA15" #base year scenario name
BASE_SCENARIO_BASE_YEAR <- 2015 #as.integer(substr(BASE_SCENARIO_BASE_NAME,1,4))

# 3. Define other application parameters
BASE_NEW_FIRMS_PROP <- 0.6 #proportion of growth in employment in already developed TAZs that comes from new firm formation as opposed to existing firm growth
BASE_SEED_VALUE  <- 5 #seed for sampling to ensure repeatable results
BASE_TIME_PERIOD_TRIP_POINT <- "MIDDLE" #point in trip for time period allocation, from ("START", "MIDDLE", "END")
BASE_TOLL_SKIM_AVAILABLE <- FALSE #are there toll skims for use in the CVM?
# Penalties applies to skims to reduce likelihood of certain TAZs/externals being used 
#(2897 is tunnel, this penalty moves trucks to Ambassador bridge) 
BASE_TAZ_PENALTY <- data.frame(TAZ = c(2897), 
                               Penalty = c(10))
# Penalty (units equivalent to miles) used to reduce likelihood of crossing International boundary between US and Canada
# Applied to in the CVTM (local commerical vehicle trips) in the scheduled stops model and intermediate stops model
BASE_INTERNATIONAL_PENALTY <- 100

# 4. Define time-of-day groupings for skims and trip tables
# Units are minutes after midnight 
# (12:00 AM = 0 at the start of a range, 1440 at the end of a range)
# Five time periods in the SEMCOG ABM model:
# EA (3:00 AM - 6:29 AM)
# AM (6:29 AM - 8:59 AM) 
# MD (9:00 AM - 2:29 PM)
# PM (2:29 PM - 6:29 PM)
# EV (7:00 PM - 2:59 AM) 
BASE_TOD_RANGES <- list(EA = list(c(180, 390)), 
                        AM = list(c(390, 540)), 
                        MD = list(c(540, 870)),
                        PM = list(c(870, 1110)),
                        EV = list(c(0, 180), c(1110, 1440)))

# 5. Define settings used in Dashboard/spreadsheet report
# Column name from TAZ_System.csv that labels each TAZ with the desired group
# names for use in the dashboard. This also determines how TAZs will be grouped
# into larger regions for display in the dashboard.
BASE_DASHBOARD_GEOGRAPHY <- "CountyName"

# Unit used for display in dashboard
BASE_DASHBOARD_LENGTH_UNIT <- "miles"

# Default scenario to use for refence comparisons in the Dashboard/spreadsheet report
# The SCENARIO_REFERENCE_NAME can also be passed as a command argument 
# A command argument will which takes precendence over the value entered, see run_semcog_cvtm.R
# Valid settings: 
# "Validation" - (quoted string) this will compare the current scenario to observed data for validation purposes
# BASE_SCENARIO_BASE_NAME - (unquoted variable name) this will compare the current scenario to the base scenario
# "<scenario name>" - (quoted string, case sensitive) this will the current scenario to another scenario
#                     the scenario name is the directory name for the scenario, and the scenario must have 
#                     been run to completion already
BASE_SCENARIO_REFERENCE_NAME <- "Validation"