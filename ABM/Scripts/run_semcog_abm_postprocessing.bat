@ECHO Off
ECHO %startTime%%Time%
SET BATCH_DRV=%~d0
SET BATCH_DIR=%~dp0
ECHO %BATCH_DIR%
%BATCH_DRV%
CD %BATCH_DIR%

::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
:: Run ActivitySim postprocessing and associated scripts
::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:: user specified for now; once model is stable, automatically calculate many of these
set ITERATION=%1
::set env_name=%2  -- removed for UV
set env_name=""
set input_dir=%3
set ANACONDA_DIR=%4
set ENV_DIR=%5
set EE_file=%6
set output_dir=%7

:: -------------------------------------------------------------------------------------------------
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

ECHO Activate ActivitySim....
CD /d %ANACONDA_DIR%\Scripts
CALL %CONDA_ACT% %env_name%

set MKL_NUM_THREADS=1
set MKL=1

CD /d %BATCH_DIR%

:: Run Python script to separate highway and transit skims and add external and airport demand to ActivitySim trip tables
CD ..\..
ECHO Creating Trip Tables...
ECHO %startTime%%Time%
%PYTHON% ABM\Scripts\add_auxiliary_demand.py %input_dir% %output_dir%HAssign %output_dir%TrnAssign ABM\Scripts %output_dir%ActivitySim %EE_file% %output_dir%
IF ERRORLEVEL 1 (
    ECHO.
    ECHO *** ERROR: add_auxiliary_demand.py FAILED ***
    ECHO Script crashed at: ABM\Scripts\add_auxiliary_demand.py
    ECHO Check the console output above for details.
    ECHO.
    pause
    EXIT /B 1
)

ECHO %startTime%%Time%
ECHO Trip Tables Complete!!