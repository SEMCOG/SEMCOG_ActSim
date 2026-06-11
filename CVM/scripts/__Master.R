
### Initialize Application -------------------------------------------------------------------

# Start the rFreight application
source(file.path("scripts", "init_start_rFreight_model.R"))

cat("Running the", SCENARIO_DESCRIPTION, "Scenario from the ", SCENARIO_NAME , " Directory", "\n")
SCENARIO_RUN_START   <- Sys.time()

### 1. Firm Synthesis ------------------------------------------------------------------------

if (SCENARIO_RUN_FIRMSYN) {
  
  cat("Starting Firm Synthesis Step", "\n")
  
  # Load executive functions (process inputs and simulation)
  source(file = file.path(SYSTEM_SCRIPTS_PATH, "firm_sim_process_inputs.R"))
  source(file = file.path(SYSTEM_SCRIPTS_PATH, "firm_sim.R"))
  
  # Process inputs
  cat("Processing Firm Synthesis Inputs", "\n")
  firm_inputs <- new.env()
  Establishments <- firm_sim_process_inputs(envir = firm_inputs)
  
  # Run simulation
  cat("Running Firm Synthesis Simulation", "\n")
  firm_sim_results <- suppressMessages(run_sim(FUN = firm_sim, data = Establishments, 
                                               packages = SYSTEM_PKGS, lib = SYSTEM_PKGS_PATH,
                                               inputEnv = firm_inputs))
  
  # Save inputs and results to Rdata file
  cat("Saving Firm Synthesis Database", "\n")
  save(firm_sim_results, 
       firm_inputs, 
       file = file.path(SCENARIO_OUTPUT_PATH, 
                        SYSTEM_FIRMSYN_OUTPUTNAME))
  
  # Export results to csv files
  cat("Writing Firm Synthesis Results to CSV Files", "\n")
  lapply(1:length(firm_sim_results), 
         function(x) fwrite(firm_sim_results[[x]], 
                            file = file.path(SCENARIO_OUTPUT_PATH, 
                                             paste(SYSTEM_FIRMSYN_OUTPUTNAME, 
                                                   names(firm_sim_results)[x],
                                                   "csv",
                                                   sep = "."))))
  
  # Clean up workspace
  rm(firm_sim_results, firm_inputs, Establishments)
  gc(verbose = FALSE)
  
}


### 2. Simulate Long Distance Movements ------------------------------------------------------

if (SCENARIO_RUN_LDM) {
  
  cat("Starting Long Distance Step", "\n")
  
  # Load executive functions (process inputs and simulation)
  source(file = file.path(SYSTEM_SCRIPTS_PATH, "ld_sim_process_inputs.R"))
  source(file = file.path(SYSTEM_SCRIPTS_PATH, "ld_sim.R"))
  
  # Process inputs
  cat("Processing Long Distance Inputs", "\n")
  ld_inputs <- new.env()
  ld_sim_process_inputs(envir = ld_inputs)
  
  # Run simulation
  cat("Running Long Distance Simulation", "\n")
  ld_sim_results <- suppressMessages(run_sim(FUN = ld_sim, data = NULL, 
                                             packages = SYSTEM_PKGS, lib = SYSTEM_PKGS_PATH,
                                             inputEnv = ld_inputs))
  
  # Save inputs and results to Rdata file
  cat("Saving Long Distance Database", "\n")
  save(ld_sim_results, 
       ld_inputs, 
       file = file.path(SCENARIO_OUTPUT_PATH, 
                        SYSTEM_LDM_OUTPUTNAME))
  
  # Export results to csv files
  cat("Writing Long Distance Results to CSV Files", "\n")
  lapply(1:length(ld_sim_results), 
         function(x) fwrite(ld_sim_results[[x]], 
                            file = file.path(SCENARIO_OUTPUT_PATH, 
                                             paste(SYSTEM_LDM_OUTPUTNAME, 
                                                   names(ld_sim_results)[x],
                                                   "csv",
                                                   sep = "."))))
  
  # Clean up workspace
  rm(ld_sim_results, ld_inputs)
  gc(verbose = FALSE)
  
}


### 3. Simulate Commercial Vehicle Movements -------------------------------------------------

if (SCENARIO_RUN_CVTM) {
  
  cat("Starting Commercial Vehicle Touring Step", "\n")
  
  # Load executive functions (process inputs and simulation)
  source(file = file.path(SYSTEM_SCRIPTS_PATH, "cv_sim_process_inputs.R"))
  source(file = file.path(SYSTEM_SCRIPTS_PATH, "cv_sim.R"))
  
  # Process inputs
  cat("Processing Commercial Vehicle Touring Inputs", "\n")
  cv_inputs <- new.env()
  ScenarioFirms <- cv_sim_process_inputs(envir = cv_inputs)
  
  # Run simuation
  cat("Running Commercial Vehicle Touring Simulation", "\n")
  cv_sim_results <- list()
  cv_sim_results$cv_trips <- suppressMessages(run_sim(FUN = cv_sim, data = ScenarioFirms,
                                             k = USER_PROCESSOR_CORES, 
                                             packages = SYSTEM_PKGS, lib = SYSTEM_PKGS_PATH,
                                             inputEnv = cv_inputs))
  cv_sim_results$cv_trips[, TourID := as.integer(factor(paste(BusID, Vehicle, TourID)))]
  
  # Save inputs and results to Rdata file
  cat("Saving Commercial Vehicle Touring Database", "\n")
  save(cv_sim_results, 
       cv_inputs, 
       file = file.path(SCENARIO_OUTPUT_PATH, 
                        SYSTEM_CVTM_OUTPUTNAME))
  
  # Export results to csv files
  cat("Writing Commercial Vehicle Touring Results to CSV Files", "\n")
  lapply(1:length(cv_sim_results), 
         function(x)  { 
           fwrite(cv_sim_results[[x]], 
                  file = file.path(SCENARIO_OUTPUT_PATH, 
                                   paste(SYSTEM_CVTM_OUTPUTNAME, 
                                         names(cv_sim_results)[x],
                                         "csv",
                                         sep = ".")))
           if(USER_SAVE_OUTPUTS_ITERATION) {
             fwrite(cv_sim_results[[x]], 
                    file = file.path(SCENARIO_OUTPUT_PATH, 
                                     paste(SYSTEM_CVTM_OUTPUTNAME, 
                                           names(cv_sim_results)[x],
                                           SCENARIO_ITERATION,
                                           "csv",
                                           sep = ".")))}})
  
  # Clean up workspace
  rm(cv_sim_results, cv_inputs, ScenarioFirms)
  gc(verbose = FALSE)
  
}


### 4. Produce Regional Trip Tables -------------------------------------------------------------------------

if (SCENARIO_RUN_TT) {
  
  cat("Producing Commercial Vehicle Trip Tables", "\n")
  
  # Load executive functions
  source(file.path(SYSTEM_SCRIPTS_PATH, "tt_build.R"))
  source(file.path(SYSTEM_SCRIPTS_PATH, "tt_build_process_inputs.R"))
  
  # Process inputs
  cat("Processing Commercial Vehicle Trip Tables Inputs", "\n")
  tt_inputs <- new.env()
  tt_process_inputs(envir = tt_inputs)
  
  # Create trip tables as an OMX file
  cat("Writing Commercial Vehicle Trip Tables to OMX Files", "\n")
  tt_list <- suppressMessages(
    run_sim(FUN = tt_build, data = NULL,
            packages = SYSTEM_PKGS, lib = SYSTEM_PKGS_PATH,
            inputEnv = tt_inputs))
  
  # Save results to Rdata file
  cat("Saving Commercial Vehicle Trip Tables Database", "\n")
  save(tt_list, 
       tt_inputs, 
       file = file.path(SCENARIO_OUTPUT_PATH, 
                        SYSTEM_TT_OUTPUTNAME))
  
  # Export results to csv files
  cat("Writing Commercial Vehicle Trip Tables Results to CSV Files", "\n")
  lapply(1:length(tt_list), 
         function(x) { if(is.data.table(tt_list[[x]])) {
           fwrite(tt_list[[x]], 
                  file = file.path(SCENARIO_OUTPUT_PATH, 
                                   paste(SYSTEM_TT_OUTPUTNAME, 
                                         names(tt_list)[x],
                                         "csv",
                                         sep = ".")))
           if(USER_SAVE_OUTPUTS_ITERATION) {
             fwrite(tt_list[[x]], 
                    file = file.path(SCENARIO_OUTPUT_PATH, 
                                     paste(SYSTEM_TT_OUTPUTNAME, 
                                           names(tt_list)[x],
                                           SCENARIO_ITERATION,
                                           "csv",
                                           sep = ".")))}}})
  
  # Clean up workspace
  rm(tt_list, tt_inputs)
  gc(verbose = FALSE)
  
}
  
  
### Produce Dashboard and Spreadsheet Report -------------------------------------------------------------------------

if (SCENARIO_RUN_DB) {
  
  cat("Producing Commercial Vehicle Model Dashboard", "\n")
  
  # Load executive functions
  source(file = file.path(SYSTEM_SCRIPTS_PATH, "db_build.R"))
  source(file = file.path(SYSTEM_SCRIPTS_PATH, "db_build_process_inputs.R"))
  
  # Process inputs
  cat("Processing Commercial Vehicle Model Dashboard Inputs", "\n")
  db_inputs <- new.env()
  db_build_process_inputs(envir = db_inputs)
  
  # Generate dashboard and spreadsheet
  cat("Rendering Commercial Vehicle Model Dashboard and Spreadsheet", "\n")
  dashboardFileLoc <- suppressWarnings(suppressMessages(
    run_sim(FUN = db_build, data = NULL,
            packages = SYSTEM_REPORT_PKGS, lib = SYSTEM_PKGS_PATH,
            inputEnv = db_inputs
    )
  ))
  
  # Save results to Rdata file
  cat("Saving Dashboard Tabulations Database", "\n")
  save(db_inputs, 
       file = file.path(SCENARIO_OUTPUT_PATH, 
                        SYSTEM_DB_OUTPUTNAME)) 
 
}

