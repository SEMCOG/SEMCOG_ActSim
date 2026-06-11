##############################################################################################
#Title:             SEMCOG Commercial Vehicle Model
#Project:           SEMCOG Commercial Vehicle Model project
#Description:       A commercial vehicle simulation model of the SEMCOG region, including Detroit
#Date:              2-28-2022
#Author:            Resource Systems Group, Inc.
#Copyright:         Copyright 2022 RSG, Inc. - All rights reserved.
##############################################################################################

# 1. Specific scenario arguments from the command line:
#    [1] Run Firm Synthesis component (Boolean, TRUE or FALSE, defaults to TRUE)
#    [2] Run Long Distance component  (Boolean, TRUE or FALSE, defaults to TRUE)
#    [3] Run CVTM component           (Boolean, TRUE or FALSE, defaults to TRUE)
#    [4] Run TT component             (Boolean, TRUE or FALSE, defaults to TRUE)
#    [5] Run Dashboard component      (Boolean, TRUE or FALSE, defaults to TRUE)
#    [6] Scenario Name                (Character string, must be a valid scenario folder name, 
#                                     detaults to base scenario name) 
#                                     (not required if writing out "run_semcog_cvtm.txt")
#    [7] Scenario Description         (Character string, any valid string acceptable, 
#                                     detaults to base scenario name) 
#                                     (not required if writing out "run_semcog_cvtm.txt")
#    [8] Iteration                    (Integer, defaults to 1) 
#                                     (not required if writing out "run_semcog_cvtm.txt")
#    [9] Scenario Reference Name      (Character string, must be either:
#                                     "Validation" to compare with observed data, or
#                                     a valid scenario folder name to compare with scenario 
#                                     Detaults to "Validation")
#                                     (not required if writing out "run_semcog_cvtm.txt")
#setwd('C:/RSG_test/semcog/CVM')
SYSTEM_COMMAND_ARGS <- commandArgs(TRUE)

# 2. Read in the run parameters file "run_semcog_cvtm.txt" if it exists
if(file.exists("run_semcog_cvtm.txt")){
  scenario_paths_file <- file("run_semcog_cvtm.txt")
  SCENARIO_PATHS <- readLines(scenario_paths_file)
  close(scenario_paths_file)
}

# 3. Run the application
source(file.path("scripts", "__Master.R"))
