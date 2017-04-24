﻿# This script is named WindowsDesktop.psm1


function global:New-PSDesktopShortcut {

<#
    .SYNOPSIS

    Creates a desktop shortcut to run a powershell script.
    .DESCRIPTION

 
 [CmdletBinding()]

    Param(
    

    if ($targetPSFile.StartsWith("\\")) {
        Write-Host "* Aborting New-PSDesktopShortcut as running from unc path"
        return
    }

    # set execution policy for this user, so that script can run later from desktop.
    # catch and mute warning message if more lapse policy is currently in use.

    try {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    }
    catch [System.Security.SecurityException] {
        write-host "* Script signed for CurrentUser but currently bypassed (OK)"
    }
    catch {
        throw
    }


     # remap target to drive c:
    if ($RemapLocal) {
        $targetPSFile = "C" + $targetPSFile.substring(1)
    }

    $linkFilePath = "$Home\Desktop\$lnkFile"

    $WshShell = New-Object -ComObject WScript.Shell
    
    # don't recreate it
    if (!(Test-Path $linkFilePath)) {
       
       $Shortcut = $WshShell.CreateShortcut($linkFilePath)
       $Shortcut.TargetPath = 'Powershell'
       $Shortcut.Arguments = '-File ' + $targetPSFile
       $Shortcut.Save()

       # hack link so 'run as administrator' properties checkbox is ticked
       $bytes = [System.IO.File]::ReadAllBytes($linkFilePath)
    }
}
