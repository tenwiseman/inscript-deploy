Windows10 as a service Start Script - Install.cmd

This script is intended to be run from it's public network share (UNC)
Currently this is:

\\TICTAC2\public\Win10aaS

When run it does the following (run as admin)

1. mkdir c:\Deployment
2. copy deployment folder contents from this share (including powershell script)
3. IF DepDrive==S: (
     NET USE S: \\TICTAC2\public\Win10aaS
     powershell S:\Deployment\machine1.ps1
   ) ELSE (
     powershell C:\Deployment\machine1.ps1
   ) 

from powershell script (S:|C:\Deployment\machine1.ps1, run as admin)
 ac-set-executionPolicy        - unblock script for future running
 ac-update-PCComputerName      - configure machine name & reboot   *
 ac-update-PCNetConfiguration  - configure network card IP address *
 ac-create-DesktopShortcut     - to rerun C:\Deployment\machine1.ps1 
 ac-install-RunInstaller       - to run software installer
				* skipped, if powershell running from S:



