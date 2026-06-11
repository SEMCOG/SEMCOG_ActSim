@ECHO off
ECHO %startTime%%Time%
SET BATCH_DRV=%~d0
SET BATCH_DIR=%~dp0
ECHO %BATCH_DIR%

set input_dir=%1
set output_dir=%2
set ANACONDA_DIR=%3
set ENV_DIR=%4
::set env_name=%5  -- removed for UV
set env_name=""

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

MD %output_dir%EJ
DEL /Q %output_dir%EJ\*.dcc

CD /d %BATCH_DIR%

ECHO Running EJ utility...
%PYTHON% EJ_Utility.py  %input_dir% %output_dir%
IF ERRORLEVEL 1 (
    ECHO.
    ECHO *** ERROR: EJ_Utility.py FAILED ***
    ECHO Script crashed at: EJ_Utility.py
    ECHO Check the console output above for details.
    ECHO.
    pause
    EXIT /B 1
)