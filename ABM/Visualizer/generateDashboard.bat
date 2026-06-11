:: ############################################################################
:: # Batch file to generate CTRAMP HTML Visualizer for SNABM
:: #
:: # 1. User should specify the path to the base and build summaries,
:: #    the specified directory should have all the files listed in
:: #    \templates\summaryFilesNames.csv
:: #
:: # 2. User should also specify the name of the base and build scenario if the
:: #    base\build scenario is specified as "CHTS", scenario names are replaced
:: #    with appropriate Census sources names wherever applicable
:: ############################################################################
@ECHO Off
SET INPUT_DIR=%1
SET BASE_IS_SURVEY=%2
SET OUTPUT_DIR=%3
SET BASE_SCEN_DIR=%4
SET R_DIR=%5
SET R_LIBRARY=%6
SET PANDOC_DIR=%7

SET SCRIPTS_DIR=%~dp0
CD ../..

SET PARENT_DIR=%cd%

CD %PARENT_DIR%
ECHO %PARENT_DIR%

:: copy destination_choice_size_terms to WorkingFiles folder
COPY %PARENT_DIR%\ABM\configs\destination_choice_size_terms.csv %OUTPUT_DIR%WorkingFiles

:: User Inputs
:: ###########

:: Set paths
SET PROJECT_DIR=%INPUT_DIR%
SET HTML_OUTPUT_DIR=%OUTPUT_DIR%
SET ABM_DIR=%OUTPUT_DIR%ActivitySim
SET ABM_SUMMARY_DIR=%OUTPUT_DIR%ActivitySim\visualizer
SET BUILD_SUMMARY_DIR=%ABM_SUMMARY_DIR%

IF %BASE_IS_SURVEY%==1 ( SET BASE_SUMMARY_DIR=%SCRIPTS_DIR%data\summarized_survey) ELSE ( SET BASE_SUMMARY_DIR=%BASE_SCEN_DIR%)

SET CENSUS_DIR=%SCRIPTS_DIR%data\census\
SET CENSUS_SUMMARY_DIR=%SCRIPTS_DIR%data\census\summarized
SET SKIMS_DIR=%OUTPUT_DIR%Skims
SET ZONES_DIR=%SCRIPTS_DIR%data\SHP
SET LAND_USE_DIR=%OUTPUT_DIR%WorkingFiles
SET SE_INPUT_DIR=%INPUT_DIR%SE_Data
SET CALIBRATION_DIR=%SCRIPTS_DIR%data\calibration_targets
SET SHP_FILE_NAME=semcog_zones.shp
SET CT_ZERO_AUTO_FILE_NAME=ct_zero_auto.shp

REM SET SUBSET_HTML_NAME=SNABM_Dashboard_SUBSET_vs_CHTS_%RUN_NAME%
REM SET FULL_HTML_NAME=SNABM_Dashboard_FULL_vs_CHTS_%RUN_NAME%
SET FULL_HTML_NAME=ActivitySimVisualizer

IF %BASE_IS_SURVEY%==1 (
   SET BASE_SCENARIO_NAME=SURVEY
) ELSE (
   SET BASE_SCENARIO_NAME=Base Run
)
::SET BUILD_SCENARIO_NAME=ACTIVITYSIM
SET BUILD_SCENARIO_NAME=This Run
:: for survey base legend names are different [Yes\No]
IF %BASE_IS_SURVEY%==1 ( SET IS_BASE_SURVEY=Yes) ELSE ( SET IS_BASE_SURVEY=No)
SET MAX_ITER=1
SET BASE_SAMPLE_RATE=1.0
REM SEMCOG synthetic pop has 1905120 hh as of 5/1/2020
SET BUILD_SAMPLE_RATE=1.0
REM SET BUILD_SAMPLE_RATE=0.000525
REM SET BUILD_SAMPLE_RATE=0.20996
REM SET BUILD_SAMPLE_RATE=.10498

:: Set up dependencies
:: ###################
:: Set R, R library, R freight zip path
SET R_SCRIPT=%PARENT_DIR%\%R_DIR%\Rscript
SET R_LIBRARY=%PARENT_DIR%\%R_LIBRARY%
:: Set PANDOC path
SET RSTUDIO_PANDOC=%PARENT_DIR%\%PANDOC_DIR%

:: Create the sub folderS if not exist
if not exist %ABM_SUMMARY_DIR%\base\ mkdir %ABM_SUMMARY_DIR%\base\
:: if not exist %ABM_SUMMARY_DIR%\build\ mkdir %ABM_SUMMARY_DIR%\build\
:: if not exist %ABM_SUMMARY_DIR%\JPEG\ mkdir %ABM_SUMMARY_DIR%\JPEG\
if not exist %ABM_SUMMARY_DIR%\runtime\ mkdir %ABM_SUMMARY_DIR%\runtime\

:: Parameters file
SET PARAMETERS_FILE=%ABM_SUMMARY_DIR%\runtime\parameters.csv
ECHO Key,Value > %PARAMETERS_FILE%
ECHO SCRIPTS_DIR,%SCRIPTS_DIR% >> %PARAMETERS_FILE%
ECHO PROJECT_DIR,%PROJECT_DIR% >> %PARAMETERS_FILE%
ECHO HTML_OUTPUT_DIR,%HTML_OUTPUT_DIR% >> %PARAMETERS_FILE%
ECHO ABM_DIR,%ABM_DIR% >> %PARAMETERS_FILE%
ECHO ABM_SUMMARY_DIR,%ABM_SUMMARY_DIR% >> %PARAMETERS_FILE%
ECHO CALIBRATION_DIR,%CALIBRATION_DIR% >> %PARAMETERS_FILE%
ECHO BASE_SUMMARY_DIR,%BASE_SUMMARY_DIR% >> %PARAMETERS_FILE%
ECHO BUILD_SUMMARY_DIR,%BUILD_SUMMARY_DIR% >> %PARAMETERS_FILE%
ECHO CENSUS_DIR,%CENSUS_DIR% >> %PARAMETERS_FILE%
ECHO CENSUS_SUMMARY_DIR,%CENSUS_SUMMARY_DIR% >> %PARAMETERS_FILE%
ECHO SKIMS_DIR,%SKIMS_DIR% >> %PARAMETERS_FILE%
ECHO ZONES_DIR,%ZONES_DIR% >> %PARAMETERS_FILE%
ECHO LAND_USE_DIR,%LAND_USE_DIR% >> %PARAMETERS_FILE%
ECHO SE_INPUT_DIR,%SE_INPUT_DIR% >> %PARAMETERS_FILE%
REM ECHO BASE_SUMMARY_DIR_SUBSET,%BASE_SUMMARY_DIR_SUBSET% >> %PARAMETERS_FILE%
ECHO BASE_SCENARIO_NAME,%BASE_SCENARIO_NAME% >> %PARAMETERS_FILE%
ECHO BUILD_SCENARIO_NAME,%BUILD_SCENARIO_NAME% >> %PARAMETERS_FILE%
ECHO BASE_SAMPLE_RATE,%BASE_SAMPLE_RATE% >> %PARAMETERS_FILE%
ECHO BUILD_SAMPLE_RATE,%BUILD_SAMPLE_RATE% >> %PARAMETERS_FILE%
ECHO MAX_ITER,%MAX_ITER% >> %PARAMETERS_FILE%
ECHO R_LIBRARY,%R_LIBRARY% >> %PARAMETERS_FILE%
ECHO RSTUDIO_PANDOC,%RSTUDIO_PANDOC% >> %PARAMETERS_FILE%
REM ECHO SUBSET_HTML_NAME,%SUBSET_HTML_NAME% >> %PARAMETERS_FILE%
ECHO FULL_HTML_NAME,%FULL_HTML_NAME% >> %PARAMETERS_FILE%
ECHO SHP_FILE_NAME,%SHP_FILE_NAME% >> %PARAMETERS_FILE%
ECHO CT_ZERO_AUTO_FILE_NAME,%CT_ZERO_AUTO_FILE_NAME% >> %PARAMETERS_FILE%
ECHO IS_BASE_SURVEY,%IS_BASE_SURVEY% >> %PARAMETERS_FILE%


:: Call the R script to generate ActivitySim summaries for visualizer
:: ############################################################################
ECHO %startTime%%Time%: Create ActivitySim summary for visualizer...
%R_SCRIPT% %SCRIPTS_DIR%\scripts\Summarize_ActivitySim_SEMCOG.R %PARAMETERS_FILE%
IF %ERRORLEVEL% NEQ 0 GOTO MODEL_ERROR

ECHO %startTime%%Time%: Create ActivitySim Workers by TAZ plots for visualizer...
%R_SCRIPT% %SCRIPTS_DIR%\scripts\workersByTAZ.R %PARAMETERS_FILE%
IF %ERRORLEVEL% NEQ 0 GOTO MODEL_ERROR

ECHO %startTime%%Time%: Create zero auto households by census tract for visualizer...
%R_SCRIPT% %SCRIPTS_DIR%\scripts\AutoOwnership_Census_CT_SEMCOG.R %PARAMETERS_FILE%
IF %ERRORLEVEL% NEQ 0 GOTO MODEL_ERROR


:: Call the master R script to generate full visualizer
:: #####################################################
ECHO %startTime%%Time%: Running R script to generate visualizer...
SET SWITCH=FULL
%R_SCRIPT% %SCRIPTS_DIR%\scripts\Master.R %PARAMETERS_FILE%
IF %ERRORLEVEL% EQU 11 (
   ECHO File missing error. Check error file in outputs.
   EXIT \b %errorlevel%
)
IF %ERRORLEVEL% NEQ 0 GOTO MODEL_ERROR


ECHO %startTime%%Time%: Dashboard creation complete...
GOTO END

:MODEL_ERROR
ECHO Model Failed
PAUSE

:END