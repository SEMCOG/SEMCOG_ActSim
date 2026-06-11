:: SEMCOG Commercial Vehicle Model Batch File
:: Batch file intended to be called from SEMCOG ABM TransCAD model
:: Set up to run component as called from the calling TransCAD macro which will send command line arguments:
:: %1 path to the installation of Rscript.exe to use to run the CVM (relative to the root of the main model system)
:: %2 - %6 TRUE/FALSE switches for each of the CVM components in this order:
:: firm synthesis, long distance, commercial vehicle touring model, trip table export, and dashboard.
:: If manually run (e.g., executed by double clicking the batch) defaults to running all steps of the base scenario

:: Path to the model installation
:: find the location of this batch file
:: it is assumed that this is one level down in the /CVM directory
set pathtocvtmmodel=%~dp0
cd /D %pathtocvtmmodel%

:: Variable definitions
:: Check for command line arguments
:getcommandargs
if [%1]==[] goto setsteps
set pathtorinsidemodel=%1
set runfirmsyn=%2
set runlongdist=%3
set runcvtm=%4
set runttexp=%5
set rundashboard=%6
goto rpath

:: No command line arguments passed (e.g., batch file run manually)
:setsteps
:: for R installed inside the model, e.g. pkgs\R-4.5.1\bin\x64
:: (if there is not an R installation at this location inside the model,
:: the C drive location specified in "pathtorcdrive" below will be checked)
set pathtorinsidemodel=pkgs\R-4.5.1\bin\x64
:: set true or false for each step of the model, true runs the step
set runfirmsyn="TRUE"
set runlongdist="TRUE"
set runcvtm="TRUE"
set runttexp="TRUE"
set rundashboard="TRUE"
echo No command line arguments so all steps will be run
goto rpath

:: Check the paths to R installation
:rpath

:: for R installed outside model in the typical program files location, for example "C:\Program Files\R\R-4.5.1\bin\x64"
:: (if there is not an R installation at this location or in the model either, the batch file will pause with a message and then exit)
set pathtorcdrive="C:\Program Files\R\R-4.5.1\bin\x64"

if EXIST ..\%pathtorinsidemodel%\Rscript.exe (
  set pathtor=..\%pathtorinsidemodel%
  echo %pathtor%  
  goto runcvm
)

set pathtor=%pathtorcdrive%

if NOT EXIST %pathtor%\Rscript.exe (
  echo Check settings for pathtorinsidemodel or pathtorcdrive variables in the %pathtocvtmmodel%\run_semong_cvtm.bat batch file, Rscript.exe not found
  echo %pathtor%  
  pause
)

echo %pathtor%  

:: Run CV Model For Selected Components
:runcvm
%pathtor%\Rscript.exe run_semcog_cvtm.R %runfirmsyn% %runlongdist% %runcvtm% %runttexp% %rundashboard% >run_semcog_cvtm_log.txt 2>&1

:: Check for errors, exit and return error code if error
if %errorlevel% neq 0 exit /B %errorlevel%

:: Remove the run_semcog_cvtm.txt file used to pass path information to the CVM
if EXIST "run_semcog_cvtm.txt" del "run_semcog_cvtm.txt" /f /q

:: Add pause to pause the run at the end of the component
::pause
