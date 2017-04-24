﻿#Windows desktop


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
