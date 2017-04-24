@echo off
echo # InScript-Deploy external UNC launch script
echo # By Tenwiseman April 2017
echo.
rem
rem This launch script executes directly from its network shared folder.
rem It copies files and ISD scripts to the target machine and invokes the
rem deployment shell powershell script located at:
rem
rem    %DepDrive%\Deployment\shell\shell.ps1
rem
rem For development convenience, set the "DepDrive" variable to an
rem available drive letter which will then be mapped. Configuration
rem changes that affect script connectivity (network, hostname changes)
rem will not be performed when running from this mapped drive.
rem
rem Otherwise, set this variable to C:

set DepDrive=S:

if not %~d0==\\ (
  echo ** This script must be run from a network share **
  pause
  exit /b
)

net session >NUL 2>&1
if not %errorLevel% == 0 (
  echo ** This script must be run as an elevated user **
  pause
  exit /b
)

if not %DepDrive%==C: (
    echo * For debug: Mapping %DepDrive% to network share.
    net use %DepDrive% /d /y >NUL 2>&1
    net use %DepDrive% %~dp0. >NUL
)

echo * Copying Deployment Files ...

mkdir c:\Deployment 2>NUL
robocopy /E %~dp0\Deployment c:\Deployment 

echo * Running deployment shell from %DepDrive% ...

cd /d %DepDrive%\Deployment\shell
powershell -ExecutionPolicy ByPass -File shell.ps1

pause