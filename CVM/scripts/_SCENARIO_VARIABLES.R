# 1. Define any default variables: only used in model testing/stand alone operation, 
#   values for these will be derived from either command arguments or text configuration file from TransCAD
SCENARIO_DEFAULT_NAME <- "SEMCOG_ABM_2" # base year scenario name in ABM model

# 2. Remainder of the script processes command line and config settings for the set up of this scenario
# If the model was called from the command line
if (exists("SYSTEM_COMMAND_ARGS")) {
  
  if (length(SYSTEM_COMMAND_ARGS) >= 1) SCENARIO_RUN_FIRMSYN <- as.logical(SYSTEM_COMMAND_ARGS[1]) else SCENARIO_RUN_FIRMSYN <- TRUE
  if (length(SYSTEM_COMMAND_ARGS) >= 2) SCENARIO_RUN_LDM     <- as.logical(SYSTEM_COMMAND_ARGS[2]) else SCENARIO_RUN_LDM <- TRUE
  if (length(SYSTEM_COMMAND_ARGS) >= 3) SCENARIO_RUN_CVTM    <- as.logical(SYSTEM_COMMAND_ARGS[3]) else SCENARIO_RUN_CVTM <- TRUE
  if (length(SYSTEM_COMMAND_ARGS) >= 4) SCENARIO_RUN_TT      <- as.logical(SYSTEM_COMMAND_ARGS[4]) else SCENARIO_RUN_TT <- TRUE
  if (length(SYSTEM_COMMAND_ARGS) >= 5) SCENARIO_RUN_DB      <- as.logical(SYSTEM_COMMAND_ARGS[5]) else SCENARIO_RUN_DB <- TRUE

  # Read the scenario name and input paths file
  if(exists("SCENARIO_PATHS")){

    SCENARIO_DESCRIPTION <- SCENARIO_PATHS[3]
    SCENARIO_INPUT_DIR <- SCENARIO_PATHS[4]
    SCENARIO_OUTPUT_DIR <- SCENARIO_PATHS[5]
    SCENARIO_ITERATION <- SCENARIO_PATHS[6]
  
    if (SCENARIO_PATHS[7] == "Firm Synthesis"){
      
      SCENARIO_TAZSE <- SCENARIO_PATHS[8]
      SCENARIO_TAZSEBUFFER <- SCENARIO_PATHS[9]
      SCENARIO_BASEFIRMS <- SCENARIO_PATHS[10]
      SCENARIO_BASESCENARIO <- SCENARIO_PATHS[11]
      
      # Check the value of SCENARIO_BASESCENARIO
      stopifnot(as.integer(SCENARIO_BASESCENARIO) %in% c(0,1))
      
    }
  
    if (SCENARIO_PATHS[7] == "Long Distance"){
      
      SCENARIO_FACILITIES <- SCENARIO_PATHS[8]
      SCENARIO_CVM_IEEI <- SCENARIO_PATHS[9]
      SCENARIO_CVM_EE <- SCENARIO_PATHS[10]
      SCENARIO_CVM_EXTERNAL <- SCENARIO_PATHS[11]
      SCENARIO_LD_SKIM_DIST <- SCENARIO_PATHS[12]
      SCENARIO_LD_SKIM_PATH <- SCENARIO_PATHS[13]
      SCENARIO_BASESCENARIO <- SCENARIO_PATHS[14]
      
      # Check the value of SCENARIO_BASESCENARIO
      stopifnot(as.integer(SCENARIO_BASESCENARIO) %in% c(0,1))
      
    }
  
    if (SCENARIO_PATHS[7] == "CV Touring Model"){
      
      SCENARIO_CV_SKIM_TIME <- SCENARIO_PATHS[8]
      SCENARIO_CV_SKIM_DIST <- SCENARIO_PATHS[9]
      SCENARIO_CV_SKIM_TOLL <- SCENARIO_PATHS[10]
      SCENARIO_CVM_EXTERNAL <- SCENARIO_PATHS[11]
      SCENARIO_CV_SKIM_PATHS <- sapply(1:length(BASE_TOD_RANGES),
                                       function(x) SCENARIO_PATHS[11 + x])
    }
  
    if (SCENARIO_PATHS[7] == "CV Trip Tables"){
      
      SCENARIO_ASSIGN_PATH <- dirname(SCENARIO_PATHS[8])
    
    }
    
    if (SCENARIO_PATHS[7] == "CV Dashboard"){
      
      SCENARIO_DB_SPREADSHEET <- as.logical(SCENARIO_PATHS[8])
      SCENARIO_ASSIGN_FLOWS_PATH <- dirname(SCENARIO_PATHS[9])
      # The reference scenario is not currently being passed from TransCAD via the text file so set here
      if(SCENARIO_DB_SPREADSHEET) SCENARIO_REFERENCE_NAME <- BASE_SCENARIO_REFERENCE_NAME
      
    }
    
    # Split the input and output directory paths and create path components
    SCENARIO_INPUT_DIR_SPLIT <- unlist(strsplit(SCENARIO_INPUT_DIR, split = "\\\\"))
    SCENARIO_OUTPUT_DIR_SPLIT <- unlist(strsplit(SCENARIO_OUTPUT_DIR, split = "\\\\"))
    SCENARIO_NAME <- SCENARIO_INPUT_DIR_SPLIT[length(SCENARIO_INPUT_DIR_SPLIT)-1]
    SCENARIO_INPUT_DIR_NAME <- SCENARIO_INPUT_DIR_SPLIT[length(SCENARIO_INPUT_DIR_SPLIT)]
    SCENARIO_OUTPUT_DIR_NAME <- SCENARIO_OUTPUT_DIR_SPLIT[length(SCENARIO_OUTPUT_DIR_SPLIT)]
    SCENARIO_FOLDER_PATH <- paste(SCENARIO_INPUT_DIR_SPLIT[1:(length(SCENARIO_INPUT_DIR_SPLIT)-2)], collapse = "/")
    
    rm(SCENARIO_PATHS)
  
  } else {
    
    # Additional command arguments can be passed instead of using text file
    if (length(SYSTEM_COMMAND_ARGS) >= 6) SCENARIO_NAME        <- as.character(SYSTEM_COMMAND_ARGS[6]) else SCENARIO_NAME <- SCENARIO_DEFAULT_NAME
    if (length(SYSTEM_COMMAND_ARGS) >= 7) SCENARIO_DESCRIPTION <- as.character(SYSTEM_COMMAND_ARGS[7]) else SCENARIO_DESCRIPTION <- SCENARIO_DEFAULT_NAME
    if (length(SYSTEM_COMMAND_ARGS) >= 8) SCENARIO_ITERATION   <- as.integer(SYSTEM_COMMAND_ARGS[8]) else SCENARIO_ITERATION <- 1L
    if (length(SYSTEM_COMMAND_ARGS) >= 9) SCENARIO_REFERENCE_NAME <- SYSTEM_COMMAND_ARGS[9] else SCENARIO_REFERENCE_NAME <- BASE_SCENARIO_REFERENCE_NAME
    
  }
    
} else {
  
  # No command line arguments (e.g. default call to run base scenario)
  SCENARIO_NAME <- SCENARIO_DEFAULT_NAME
  SCENARIO_DESCRIPTION <- SCENARIO_DEFAULT_NAME
  SCENARIO_ITERATION <- 1L
  SCENARIO_RUN_FIRMSYN <- TRUE
  SCENARIO_RUN_LDM <- TRUE
  SCENARIO_RUN_CVTM <- TRUE
  SCENARIO_RUN_TT <- TRUE
  SCENARIO_RUN_DB <- TRUE
  SCENARIO_REFERENCE_NAME <- BASE_SCENARIO_REFERENCE_NAME
  
}

# Build the paths to scenario input, scenario output, base output, and log file locations
# If paths not passed assume that scenarios are in "Model Runs" directory
if(!exists("SCENARIO_FOLDER_PATH")) SCENARIO_FOLDER_PATH <- file.path(SYSTEM_INTEGRATED_PATH, "Model_Runs")
if(!exists("SCENARIO_INPUT_DIR")) SCENARIO_INPUT_DIR <- file.path(SCENARIO_FOLDER_PATH, SCENARIO_NAME, "Input")
if(!exists("SCENARIO_OUTPUT_DIR")) SCENARIO_OUTPUT_DIR <- file.path(SCENARIO_FOLDER_PATH, SCENARIO_NAME, "Output")
if(!exists("SCENARIO_OUTPUT_DIR_NAME")) SCENARIO_OUTPUT_DIR_NAME <- "Output"

SCENARIO_INPUT_PATH  <- file.path(SCENARIO_INPUT_DIR, "SED")
SCENARIO_SKIM_PATH  <- file.path(SCENARIO_OUTPUT_DIR, "skims")
SCENARIO_OUTPUT_PATH <- file.path(SCENARIO_OUTPUT_DIR, "CVM")
SCENARIO_DEFAULT_OUTPUT_PATH <- file.path(SCENARIO_FOLDER_PATH, SCENARIO_DEFAULT_NAME, SCENARIO_OUTPUT_DIR_NAME, "CVM")
SCENARIO_LOG_PATH    <- file.path(SCENARIO_OUTPUT_PATH, "log")

# Create file specific paths if those are missing
if (!exists("SCENARIO_TAZSE") & SCENARIO_RUN_FIRMSYN) {
  if(SCENARIO_NAME == SCENARIO_DEFAULT_NAME) {
    SCENARIO_TAZSE <- file.path(SCENARIO_INPUT_PATH, "base_transcad_taz.csv")
  } else {
    SCENARIO_TAZSE <- file.path(SCENARIO_INPUT_PATH, paste0(substr(SCENARIO_NAME,1,4), "_transcad_taz.csv"))  
  }
}
if (!exists("SCENARIO_TAZSEBUFFER") & SCENARIO_RUN_FIRMSYN) SCENARIO_TAZSEBUFFER <- file.path(SCENARIO_INPUT_PATH, "TAZSocioEconomicsBuffer.csv")
if (!exists("SCENARIO_BASEFIRMS") & SCENARIO_RUN_FIRMSYN) SCENARIO_BASEFIRMS <- file.path(SCENARIO_DEFAULT_OUTPUT_PATH, SYSTEM_FIRMSYN_OUTPUTNAME)
if (!exists("SCENARIO_BASESCENARIO") & (SCENARIO_RUN_FIRMSYN | SCENARIO_RUN_LDM)) SCENARIO_BASESCENARIO <- 1L
if (!exists("SCENARIO_FACILITIES") & SCENARIO_RUN_LDM) SCENARIO_FACILITIES <- file.path(SCENARIO_INPUT_PATH, "Facilities.csv")
if (!exists("SCENARIO_CVM_IEEI") & SCENARIO_RUN_LDM) SCENARIO_CVM_IEEI <- file.path(SCENARIO_INPUT_PATH, "CVM_IEEI_Region.csv")
if (!exists("SCENARIO_CVM_EE") & SCENARIO_RUN_LDM) SCENARIO_CVM_EE <- file.path(SCENARIO_INPUT_PATH, "CVM_EE_Region.csv")
if (!exists("SCENARIO_CVM_EXTERNAL") & (SCENARIO_RUN_LDM | SCENARIO_RUN_CVTM)) SCENARIO_CVM_EXTERNAL <- file.path(SCENARIO_INPUT_PATH, "CVM_Externals.csv")
if (!exists("SCENARIO_LD_SKIM_DIST") & SCENARIO_RUN_LDM) SCENARIO_LD_SKIM_DIST <- "Miles"
if (!exists("SCENARIO_LD_SKIM_PATH") & SCENARIO_RUN_LDM) SCENARIO_LD_SKIM_PATH <- file.path(SCENARIO_SKIM_PATH, "MD_HwySkim.omx")
if (!exists("SCENARIO_CV_SKIM_TIME") & SCENARIO_RUN_CVTM) SCENARIO_CV_SKIM_TIME <- "Trav_Time"
if (!exists("SCENARIO_CV_SKIM_DIST") & SCENARIO_RUN_CVTM) SCENARIO_CV_SKIM_DIST <- "Miles"
if (!exists("SCENARIO_CV_SKIM_TOLL") & SCENARIO_RUN_CVTM) SCENARIO_CV_SKIM_TOLL <- NA
if (!exists("SCENARIO_CV_SKIM_PATHS") & SCENARIO_RUN_CVTM) {
  SCENARIO_CV_SKIM_PATHS <- file.path(SCENARIO_SKIM_PATH,
                                      paste(names(BASE_TOD_RANGES), "HwySkim.omx", sep = "_"))
  }
if (!exists("SCENARIO_ASSIGN_PATH") & SCENARIO_RUN_TT) SCENARIO_ASSIGN_PATH <- file.path(SCENARIO_OUTPUT_DIR, "HAssign")
if (!exists("SCENARIO_ASSIGN_FLOWS_PATH") & SCENARIO_RUN_DB) SCENARIO_ASSIGN_FLOWS_PATH <- file.path(SCENARIO_OUTPUT_DIR, "HAssign")
if (!exists("SCENARIO_DB_SPREADSHEET") & SCENARIO_RUN_DB) SCENARIO_DB_SPREADSHEET <- TRUE
if (!exists("SCENARIO_REFERENCE_NAME") & SCENARIO_RUN_DB) SCENARIO_REFERENCE_NAME <- BASE_SCENARIO_REFERENCE_NAME

# Switches for the Dashboard components: TRUE and the content for that model step is rendered in the dashboard
SCENARIO_DB_FIRMSYN <- TRUE
SCENARIO_DB_LDM <- TRUE
SCENARIO_DB_CVTM <- TRUE
SCENARIO_DB_TT <- TRUE
