@ECHO OFF
ECHO %startTime%%Time%
SET BATCH_DRV=%~d0
SET BATCH_DIR=%~dp0
ECHO %BATCH_DIR%
%BATCH_DRV%
CD %BATCH_DIR%

set ITERATION=%1
set LU_DIR=%2
set LU_TAZ=%3
set ANACONDA_DIR=%4
set ENV_DIR=%5
set output_dir=%6
::set env_name=%7 -- removed for UV
set env_name=""
set other_zonaldata_dir=%8 
set merged_landuse_output_dir=%9

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
CD /d %BATCH_DIR%
CD ..\..

if %ITERATION% == 1 (
    ECHO Join Land use data...

    :: check to see if output file already exists and delete it if it does
    IF EXIST %merged_landuse_output_dir% (
        DEL %merged_landuse_output_dir%
    )
    :: run Python script to aggregate join land use data  
    %PYTHON% ABM\Scripts\join_landuse_data.py %LU_DIR% %other_zonaldata_dir% %merged_landuse_output_dir% %output_dir%
    IF ERRORLEVEL 1 (
        ECHO.
        ECHO *** ERROR: join_landuse_data.py FAILED ***
        ECHO Script crashed at: ABM\Scripts\join_landuse_data.py
        ECHO Check the console output above for details.
        ECHO.
        pause
        EXIT /B 1
    )
    
    :: return error code if land_use_taz.csv was not created
    IF NOT EXIST %merged_landuse_output_dir% (
        ECHO.
        ECHO *** ERROR: Output file not created by join_landuse_data.py ***
        ECHO Expected file: %merged_landuse_output_dir%
        ECHO.
        pause
        EXIT /B 1
    )
    ECHO Join Land Use Data Complete!!

) ELSE (
    ECHO Skipping Join Land Use Step
)

:: Run Python script 
if %ITERATION% == 1 (
    ECHO Aggregating Land use data to TAZ level...

    :: check to see if land_use_taz.csv already exists and delete it if it does
    IF EXIST %LU_TAZ% (
        DEL %LU_TAZ%
    )
    :: run Python script to aggregate land use data to TAZ level  
    %PYTHON% ABM\Scripts\aggregate_landuse.py %merged_landuse_output_dir% %LU_TAZ% %output_dir%
    IF ERRORLEVEL 1 (
        ECHO.
        ECHO *** ERROR: aggregate_landuse.py FAILED ***
        ECHO Script crashed at: ABM\Scripts\aggregate_landuse.py
        ECHO Check the console output above for details.
        ECHO.
        pause
        EXIT /B 1
    )
    
    :: return error code if land_use_taz.csv was not created
    IF NOT EXIST %LU_TAZ% (
        ECHO.
        ECHO *** ERROR: Output file not created by aggregate_landuse.py ***
        ECHO Expected file: %LU_TAZ%
        ECHO.
        pause
        EXIT /B 1
    )
    ECHO Aggregate Land Use Data Complete!!

    :: copy land_use_taz to %output_dir%/WorkingFiles\input_to_activitysim so it can also be read in by ActivitySim
    MD %output_dir%\WorkingFiles\input_to_activitysim
    COPY %LU_TAZ% %output_dir%\WorkingFiles\input_to_activitysim\land_use_taz.csv

) ELSE (
    ECHO Skipping Aggregate Land Use Step
)
