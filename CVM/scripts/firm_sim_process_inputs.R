
# This function loads all necessary inputs into envir, after any needed transformations
firm_sim_process_inputs <- function(envir) {
  
  ### Load project input files
  project.files <- c(EstSizeCategories            = file.path(SYSTEM_DATA_PATH, "EstSizeCategories.csv"),
                     Establishments               = file.path(SYSTEM_DATA_PATH, "Establishments.csv"),
                     NAICS3_to_EmpCats            = file.path(SYSTEM_DATA_PATH, "NAICS3_to_EmpCats.csv"),
                     TAZ_System                   = file.path(SYSTEM_DATA_PATH, "TAZ_System.csv"))
  
  loadInputs(files = project.files, envir = envir)
  
  ### Process project input files
  envir[["UEmpCats"]] <- unique(envir[["NAICS3_to_EmpCats"]][,.(EmpCatID, EmpCatName, EmpCatDesc, EmpCatGroupedName)])
  
  ### Load scenario input files
  scenario.files <- c(TAZSocioEconomicsRawTAZData = SCENARIO_TAZSE,
                      TAZSocioEconomicsBuffer = SCENARIO_TAZSEBUFFER)
  loadInputs(files = scenario.files, envir = envir)
  
  ### Process scenario input files
  envir[["TAZSocioEconomicsInternal"]] <- envir[["TAZSocioEconomicsRawTAZData"]][, c("zoneid", 
                                                                                     "tot_hhs",
                                                                                     "tot_pop",
                                                                                     sort(unique(envir[["UEmpCats"]]$EmpCatName))),
                                                                                  with = FALSE]
  
  setnames(envir[["TAZSocioEconomicsInternal"]], 
           c("zoneid", "tot_hhs", "tot_pop"), 
           c("TAZ", "HH", "POP"))
  
  envir[["TAZSocioEconomics"]] <- rbind(envir[["TAZSocioEconomicsInternal"]],
                                        envir[["TAZSocioEconomicsBuffer"]])
  
  envir[["TAZSocioEconomics"]] <- processTAZSocioEconomics(TAZSE = envir[["TAZSocioEconomics"]])
  
  envir[["TAZEmployment"]] <- extractTAZEmployment(TAZSE = envir[["TAZSocioEconomics"]], 
                                                   employment.regexpr = "^e[0-9][0-9]_")
  
  envir[["TAZLandUseCVTM"]] <- summarizeTAZLandUse(envir[["TAZSocioEconomics"]],
                                        EmpCats = envir[["UEmpCats"]]$EmpCatName,
                                        GroupingCats = envir[["UEmpCats"]]$EmpCatGroupedName,
                                        AddEmpTotal = TRUE,
                                        TotalEmpName = "TotalEmp",
                                        AddlFields = "HH",
                                        AddlFieldNames = "TotalHHs")
  
  ### Return the Establishments table
  Establishments <- envir[["Establishments"]]
  rm(Establishments, envir = envir)
  
  return(Establishments)
  
}
