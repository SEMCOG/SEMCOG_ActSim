@ECHO Off
ECHO %startTime%%Time%
SET BATCH_DRV=%~d0
SET BATCH_DIR=%~dp0
ECHO %BATCH_DIR%
%BATCH_DRV%
CD %BATCH_DIR%

::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
:: Prepare files and paths for ActivitySim input checker 
::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set input_dir=%1
set ANACONDA_DIR=%2
set ENV_DIR=%3
set hhfile_name=%4
set personfile_name=%5
set landusefile_dir=%6
set output_dir=%7
::set env_name=%8   -- removed for UV
set env_name=""

:: Print variable values for debugging
echo input_dir = %input_dir%
echo ANACONDA_DIR = %ANACONDA_DIR%
echo ENV_DIR = %ENV_DIR%
echo hhfile_name = %hhfile_name%
echo personfile_name = %personfile_name%
echo landusefile_dir = %landusefile_dir%
echo output_dir = %output_dir%
echo env_name = %env_name%

echo ARG1 = %1
echo ARG2 = %2
echo ARG3 = %3
echo ARG4 = %4
echo ARG5 = %5
echo ARG6 = %6
echo ARG7 = %7
echo ARG8 = %8


:: -------------------------------------------------------------------------------------------------
:: Activate SEMCOG ActivitySim Env
:: Anaconda installation directory is set in the Paremters tab in transcAD Add-In
:: ---------------------------------------------------------------------

SET PATH=%ANACONDA_DIR%\lib;%PATH%
SET PATH=%ANACONDA_DIR%\Scripts;%ANACONDA_DIR%\bin;%PATH%

:: setup paths to Python application, Conda script, etc.
SET CONDA_ACT=%ANACONDA_DIR%\Scripts\activate.bat
ECHO CONDA_ACT: %CONDA_ACT%

SET CONDA_DEA=%ANACONDA_DIR%\Scripts\deactivate.bat
ECHO CONDA_DEA: %CONDA_DEA%

::SET PYTHON=%ENV_DIR%\envs\%env_name%\python.exe -- replaced with the following for UV
SET PYTHON=uv run

ECHO PYTHON: %PYTHON%

ECHO Activate %env_name% environment....
CD /d %ANACONDA_DIR%\Scripts
CALL %CONDA_ACT% %env_name%

set MKL_NUM_THREADS=1
set MKL=1

CD /d %BATCH_DIR%
CD ..\..

:: Input Checker
ECHO Running Input Checker...

%PYTHON% ABM\data_model\input_checks.py ABM\configs\input_checker.yaml --data_root %input_dir% --hh_file %input_dir%%hhfile_name% --person_file %input_dir%%personfile_name% --landuse_file %landusefile_dir% --trace_label input_check_run > %output_dir%\ActivitySim_inputcheck_log.txt 2>&1

IF %ERRORLEVEL% EQU 1 (
     echo An error occurred when running input checker!
     pause
) ELSE (
    echo Input Checker Completed!
)
