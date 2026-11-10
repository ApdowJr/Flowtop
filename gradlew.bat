@rem
@rem Gradle wrapper script for flowTop (Windows)
@rem

@if "%DEBUG%" == "" @echo off
@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_NAME=flowTop
set GRADLE_VERSION=8.1.1

if defined GRADLE_HOME goto useGradleHome
if exist "%DIRNAME%\..\gradle\bin\gradle.bat" set GRADLE_HOME=%DIRNAME%\..
:useGradleHome
if "%GRADLE_HOME%"=="" goto error
set GRADLE_HOME=%GRADLE_HOME:/=\%

if not exist "%GRADLE_HOME%\bin\gradle.bat" goto error
goto run

:error
echo Gradle ${GRADLE_VERSION} not found locally.
echo To use the Gradle wrapper, install Gradle ${GRADLE_VERSION} and set GRADLE_HOME,
echo or ensure the 'gradle' binary is on your PATH.
exit /b 1

:run
"%GRADLE_HOME%\bin\gradle.bat" %*
