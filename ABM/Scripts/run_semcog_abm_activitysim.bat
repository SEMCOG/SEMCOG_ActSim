@ECHO Off
ECHO %startTime%%Time%
SET BATCH_DRV=%~d0
SET BATCH_DIR=%~dp0
ECHO %BATCH_DIR%
%BATCH_DRV%
CD %BATCH_DIR%

::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
:: Run ActivitySim and associated scripts
::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
set ITERATION=%1
::set env_name=%2  -- removed for UV
set env_name=""
set input_dir=%3
set ANACONDA_DIR=%4
set ENV_DIR=%5
set hhfile_name=%6
set personfile_name=%7
set landusefile_name=%8
set output_dir=%9

SET SAMPLE_ITERATION1=1000000
SET SAMPLE_ITERATION2=1500000
SET SAMPLE_ITERATION3=0


ECHO ****MODEL ITERATION %ITERATION%

IF %ITERATION% EQU 1 SET SAMPLE=%SAMPLE_ITERATION1%
IF %ITERATION% EQU 2 SET SAMPLE=%SAMPLE_ITERATION2%
IF %ITERATION% EQU 3 SET SAMPLE=%SAMPLE_ITERATION3%
IF %ITERATION% EQU 4 SET SAMPLE=%SAMPLE_ITERATION3%
IF %ITERATION% EQU 5 SET SAMPLE=%SAMPLE_ITERATION3%

CD ..
:: Set sample_rate in configs file dynamically
ECHO # Configs File with Sample Rate set by Model Runner > configs_mp\settings.yaml
FOR /F "delims=*" %%i IN (configs_mp\settings_source.yaml) DO (
    SET LINE=%%i
    SETLOCAL EnableDelayedExpansion
    SET LINE=!LINE:%%sample_size%%=%SAMPLE%!
    ECHO !LINE!>>configs_mp\settings.yaml
    ENDLOCAL
)
:: -------------------------------------------------------------------------------------------------
:: Run SEMCOG ActivitySim
:: Anaconda installation directory is set in the Paremters tab in transcAD Add-In
:: ---------------------------------------------------------------------
ECHO CURRENT DIRECTORY: %cd%

SET PATH=%ANACONDA_DIR%\Lib;%PATH%
SET PATH=%ANACONDA_DIR%\Scripts;%ANACONDA_DIR%\bin;%PATH%

:: setup paths to Python application, Conda script, etc.
SET CONDA_ACT=%ANACONDA_DIR%\Scripts\activate.bat
ECHO CONDA_ACT: %CONDA_ACT%

SET CONDA_DEA=%ANACONDA_DIR%\Scripts\deactivate.bat
ECHO CONDA_DEA: %CONDA_DEA%

::SET PYTHON=%ENV_DIR%\envs\%env_name%\python.exe -- replaced with the following for UV
SET PYTHON=uv run

ECHO PYTHON: %PYTHON%

ECHO Activate %env_name% Environment....
CD /d %ANACONDA_DIR%\Scripts
CALL %CONDA_ACT% %env_name%

set MKL_NUM_THREADS=1
set MKL=1

CD /d %BATCH_DIR%

:: update input file names based on names pass from transcad
IF %ITERATION% EQU 1 (
%PYTHON% set_input_file_names_for_asim.py %hhfile_name% %personfile_name% %landusefile_name%
IF ERRORLEVEL 1 (
    ECHO.
    ECHO *** ERROR: set_input_file_names_for_asim.py FAILED ***
    ECHO Script crashed at: set_input_file_names_for_asim.py
    ECHO Check the console output above for details.
    ECHO.
    pause
    EXIT /B 1
)
)

:: Create Directory to Store ActivitySim Outputs
CD %output_dir%
ECHO Create Output Directory
MD ActivitySim
MD ActivitySim\trace
MD ActivitySim\log
MD ActivitySim\visualizer

CD /d %BATCH_DIR%
CD ..\..

:: Delete all previous iter files in %output_dir%ActivitySim
DEL /Q %output_dir%ActivitySim\*.*
DEL /Q %output_dir%ActivitySim\log\*.*
DEL /Q %output_dir%ActivitySim\trace\*.*
DEL /Q %output_dir%ActivitySim\visualizer\*.*

:: Run ActivitySim
%PYTHON% ABM/Scripts/simulation.py -c ABM/configs_mp -c ABM/configs -d %input_dir% -d %output_dir%skims -o %output_dir%ActivitySim
IF ERRORLEVEL 1 (
    ECHO.
    ECHO *** ERROR: simulation.py FAILED ***
    ECHO Script crashed at: ABM/Scripts/simulation.py
    ECHO Check the ActivitySim.log in the outpute for details.
    ECHO.
    pause
    EXIT /B 1
)

:: check to see if there are files starting with final_ and *.omx in the output directory, meaning the run was successful
cd %output_dir%ActivitySim

setlocal EnableDelayedExpansion
set found=0
for %%f in (final_*) do (
    set /a found+=1
)

if !found! gtr 0 (
    echo ActivitySim outputs correctly created.
) else (
    echo ActivitySim outputs not created.
    exit /b 1
)

@REM setlocal EnableDelayedExpansion
@REM set found=0
@REM for %%f in (*.omx) do (
@REM     set /a found+=1
@REM )

@REM if !found! gtr 0 (
@REM     echo ActivitySim outputs correctly created.
@REM ) else (
@REM     echo ActivitySim outputs not created.
@REM     pause
@REM     exit /b 1
@REM )

ECHO ActivitySim run complete!!
ECHO %startTime%%Time%
