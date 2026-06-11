# R packages required by the model
SYSTEM_PKGS <- c("bit", "bit64", "data.table", "fastcluster", "withr", "ggplot2", "pscl",
                 "reshape", "reshape2", "rFreight", "TSP", "sf", "rhdf5",
                 "leaflet", "jsonlite", "apollo")

SYSTEM_REPORT_PKGS <- c("DT", "flexdashboard", "leaflet", "plotly", "scales",
                        "pander", "stringr", "kableExtra", "openxlsx")

SYSTEM_DEV_PKGS <- c("lwgeom", "dplyr", "ggrepel",
                  "ggspatial", "bookdown", "leaps", "tools", "foreign")

# combine list of system and system report packages so all install if needed on call to initializeApp
# leave the list of packages used in development seperate, not required for application
SYSTEM_PKGS <- c(SYSTEM_PKGS, SYSTEM_REPORT_PKGS[!SYSTEM_REPORT_PKGS %in% SYSTEM_PKGS])

# paths to main application directories
SYSTEM_APP_PATH       <- getwd()
SYSTEM_INTEGRATED_PATH <- dirname(getwd())

# path to R Library, R freight Package, and Pandoc are in scenario paths if it is being used 
# i.e., the run was launched from TransCAD. If not, the run is standalone and paths are hardcoded here.
if(exists("SCENARIO_PATHS")){
  
  SYSTEM_PKGS_PATH      <- file.path(SYSTEM_INTEGRATED_PATH, SCENARIO_PATHS[1])
  SYSTEM_PANDOC_PATH    <- file.path(SYSTEM_INTEGRATED_PATH, SCENARIO_PATHS[3])

} else {
  
  SYSTEM_PKGS_PATH      <- file.path(SYSTEM_INTEGRATED_PATH, "pkgs", "library")
  SYSTEM_PANDOC_PATH    <- file.path(SYSTEM_INTEGRATED_PATH, "pkgs", "Pandoc")
  
}

SYSTEM_DATA_PATH      <- file.path(SYSTEM_APP_PATH, "data")
SYSTEM_SCRIPTS_PATH   <- file.path(SYSTEM_APP_PATH, "scripts")
SYSTEM_RFREIGHT_PATH  <- file.path(SYSTEM_INTEGRATED_PATH, "Tasks", "CVM_dev", "rFreight_0.1-39.zip")
SYSTEM_DEV_PATH       <- file.path(SYSTEM_INTEGRATED_PATH, "Tasks", "CVM_dev")
SYSTEM_DOCS_PATH      <- file.path(SYSTEM_INTEGRATED_PATH, "docs")

# add the library folder to the library search paths
.libPaths(c(SYSTEM_PKGS_PATH, .libPaths())) 
Sys.setenv(R_LIBS = paste(SYSTEM_PKGS_PATH, Sys.getenv("R_LIBS"),
                          sep=.Platform$path.sep))

# Standard model component databases
SYSTEM_FIRMSYN_OUTPUTNAME <- "1.Firms.RData"
SYSTEM_LDM_OUTPUTNAME     <- "2.LongDistanceTrips.RData"
SYSTEM_CVTM_OUTPUTNAME    <- "3.CommercialVehicleTrips.RData"
SYSTEM_TT_OUTPUTNAME      <- "4.TripTables.RData"
SYSTEM_DB_OUTPUTNAME      <- "5.DashboardTables.RData"
