# User options to control hardware use, and run mode
USER_PROCESSOR_CORES <- 5L # How many processors should be used during model runs? 
                           # (a number, followed by L to indicate integer)
USER_RUN_MODE <- "Application" # What type of run is being done? 
                               # Options are "Application" or "Calibration" 
                               # where calibration triggers certain model components to run iterative adjustments
USER_SAVE_COMBINED_OD_TABLES <- FALSE # Should OD tables also be saved in 
                                      # a single combined trip table in CVM outputs? 
                                      # This take ~5 minutes per iteration, not necessary typically
USER_SAVE_OUTPUTS_ITERATION <- FALSE # Should CVTM and Trip table outputs by exported for every system iteration? 
                                     # If TRUE, each CVTM and Trip table database CSV is saved 
                                     # with the filename appended with the iteration number 
                                     # (typically E8 model is run for 5 iterations)
USER_SPREADSHEET_SUMMARIES <- TRUE # Should dashboard component include additional reporting to a spreadsheet? 
                                   # If TRUE, a spreadsheet report is written. 
                                   # WARNING requires exported flow csv files for assignment summaries, 
                                   # these will only be up to date if dashboard step is run after 
                                   # full system model run is completed (can be run as a single step from the GUI)
                                   # Note that call from integrated model to build dashboard in mid-run 
                                   # will override setting (if it is set to TRUE)
                                   # as assignment results will be inconsistent with the rest of the results
                                   # This is not the case when the reporting portion of the integrated model is used
                                   # and the spreadsheet summaries are selected