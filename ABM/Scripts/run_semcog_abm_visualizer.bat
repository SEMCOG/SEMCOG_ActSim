@ECHO Off
ECHO %startTime%%Time%
SET BATCH_DRV=%~d0
SET BATCH_DIR=%~dp0
ECHO %BATCH_DIR%

set input_dir=%1
set BASE_IS_SURVEY=%2
set ANACONDA_DIR=%3
set ENV_DIR=%4
set output_dir=%5
set ee_file=%6
::set env_name=%7 -- removed for UV
set env_name=""
set BASE_SCEN_DIR=%8
set R_DIR=%9
:: max variable that can be addressed is %9, need to shift to move remaining variables into %9
shift
set R_LIBRARY=%9
shift
set PANDOC_DIR=%9

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

ECHO Activate ActivitySim....
CD /d %ANACONDA_DIR%\Scripts
CALL %CONDA_ACT% %env_name%

CD /d %BATCH_DIR%
CD ..\..
CD ABM\Visualizer

ECHO Running initial reports...
%PYTHON% scripts\transcad_reports.py  %output_dir% %ee_file%
IF ERRORLEVEL 1 (
    ECHO.
    ECHO *** ERROR: transcad_reports.py FAILED ***
    ECHO Script crashed at: scripts\transcad_reports.py
    ECHO Check the console output above for details.
    ECHO.
    pause
    EXIT /B 1
)

start generateDashboard.bat %input_dir% %BASE_IS_SURVEY% %output_dir% %BASE_SCEN_DIR% %R_DIR% %R_LIBRARY% %PANDOC_DIR%