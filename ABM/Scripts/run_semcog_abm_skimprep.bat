@ECHO Off
ECHO %startTime%%Time%
SET BATCH_DRV=%~d0
SET BATCH_DIR=%~dp0
ECHO %BATCH_DIR%
%BATCH_DRV%
CD %BATCH_DIR%

::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
:: Run ActivitySim preprocessing and associated scripts
::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set ITERATION=%1
set REINDEX=%2
set input_dir=%3
set ANACONDA_DIR=%4
set ENV_DIR=%5
set hhfile_name=%6
set personfile_name=%7
set landusefile_dir=%8
set output_dir=%9
shift
shift
::set env_name=%9   -- removed for UV
set env_name=""

:: Print variable values for debugging
echo ITERATION = %ITERATION%
echo REINDEX = %REINDEX%
echo input_dir = %input_dir%
echo ANACONDA_DIR = %ANACONDA_DIR%
echo ENV_DIR = %ENV_DIR%
echo hhfile_name = %hhfile_name%
echo personfile_name = %personfile_name%
echo landusefile_dir = %landusefile_dir%
echo output_dir = %output_dir%
echo env_name = %env_name%
echo PYTHON = %PYTHON%


:: -------------------------------------------------------------------------------------------------
:: Run SEMCOG ActivitySim
:: Anaconda installation directory is set in the Paremters tab in transcAD Add-In
:: ---------------------------------------------------------------------

SET PATH=%ANACONDA_DIR%\lib;%PATH%
SET PATH=%ANACONDA_DIR%\Scripts;%ANACONDA_DIR%\bin;%PATH%

:: setup paths to Python application, Conda script, etc.
SET CONDA_ACT=%ANACONDA_DIR%\Scripts\activate.bat
ECHO CONDA_ACT: %CONDA_ACT%

SET CONDA_DEA=%ANACONDA_DIR%\Scripts\deactivate.bat
ECHO CONDA_DEA: %CONDA_DEA%

::SET PYTHON=%ENV_DIR%\envs\%env_name%\python.exe -- replaced for the following for UV
SET PYTHON=uv run
ECHO PYTHON: %PYTHON%

ECHO Activate %env_name% environment....
CD /d %ANACONDA_DIR%\Scripts
CALL %CONDA_ACT% %env_name%

set MKL_NUM_THREADS=1
set MKL=1

CD /d %BATCH_DIR%
CD ..\..


:: Reindex Synthetic Population
IF %REINDEX% == 1 (
%PYTHON% ABM\Scripts\reindex.py %input_dir%SE_Data %hhfile_name% %personfile_name% %landusefile_dir%
IF ERRORLEVEL 1 (
    ECHO.
    ECHO *** ERROR: reindex.py FAILED ***
    ECHO Script crashed at: ABM\Scripts\reindex.py
    ECHO Check the console output above for details.
    ECHO.
    pause
    EXIT /B 1
)
) ELSE (
    ECHO Skip Reindex Synthetic Population
)


:: Input Checker
IF %ITERATION% EQU 1 (
ECHO Running Input Checker...
%PYTHON% ABM\data_model\input_checks.py ABM\configs\input_checker.yaml --data_root %input_dir% --hh_file %input_dir%%hhfile_name% --person_file %input_dir%%personfile_name% --landuse_file %landusefile_dir% --trace_label input_check_run > %output_dir%\ActivitySim_inputcheck_log.txt 2>&1
:: Check for success message in the log
findstr /C:"Input checking completed." "%output_dir%\ActivitySim_inputcheck_log.txt" >nul

	IF ERRORLEVEL 1 (
		echo Input check failed: Message not found in log.

		:: Optional: show popup dialog
		powershell -Command "Add-Type -AssemblyName PresentationFramework; [System.Windows.MessageBox]::Show('Input check failed. Check the log file for errors.', 'Input Checker', 'OK', 'Error')"

		EXIT /B 1
	)
)
 

:: Run COUNTY.py on the first iteration only
IF %ITERATION% EQU 1 (
%PYTHON% ABM/Scripts/County_script.py %input_dir% %output_dir%
IF ERRORLEVEL 1 (
    ECHO.
    ECHO *** ERROR: County_script.py FAILED ***
    ECHO Script crashed at: ABM/Scripts/County_script.py
    ECHO Check the console output above for details.
    ECHO.
    pause
    EXIT /B 1
)
)

:: Build skims.omx
ECHO Building skims.omx...
ECHO %startTime%%Time%
%PYTHON% ABM\Scripts\build_omx.py ABM\Scripts %output_dir%Skims
IF ERRORLEVEL 1 (
    ECHO.
    ECHO *** ERROR: build_omx.py FAILED ***
    ECHO Script crashed at: ABM\Scripts\build_omx.py
    ECHO Check the console output above for details.
    ECHO.
    pause
    EXIT /B 1
)
ECHO %startTime%%Time%
ECHO Building skims.omx complete!

:: Run 2zone.py on the first iteration only
IF %ITERATION% EQU 1 (
ECHO Running 2-zone preparation script...
%PYTHON% ABM/Scripts/2zone_prep.py %output_dir% %landusefile_dir%
IF ERRORLEVEL 1 (
    ECHO.
    ECHO *** ERROR: 2zone_prep.py FAILED ***
    ECHO Script crashed at: ABM/Scripts/2zone_prep.py
    ECHO Check the console output above for details.
    ECHO.
    pause
    EXIT /B 1
)
) ELSE (
    ECHO Not the first iteration, skipping 2-zone preparation
)
