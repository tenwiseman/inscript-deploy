# This script is named WindowsDesktop.psm1


function global:New-PSDesktopShortcut {

<#
    .SYNOPSIS

    Creates a desktop shortcut to run a powershell script.
    .DESCRIPTION
    Creates a desktop shortcut, setting RunAsAdmin flag as default    .EXAMPLE    New-PSDesktopShortcut -lnkFile machine.lnk -targetPSFile $caller -RemapLocal:$true    Creates the link file '$HOME/desktop/machine.lnk' that calls the $caller script        If RemapLocal is $true, then the targetPSFile path is changed to launch from drive C:    If the $caller script is a UNC path, then the shortcut is not created       #>
 
 [CmdletBinding()]

    Param(
            [parameter(Mandatory=$true)]        [String] $lnkFile,        [parameter(Mandatory=$true)]        [String] $targetPSFile,        [parameter(Mandatory=$true)]        [Bool] $RemapLocal    )

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
       $bytes = [System.IO.File]::ReadAllBytes($linkFilePath)       # set byte 21 (0x15) bit 6 (0x20) ON       $bytes[0x15] = $bytes[0x15] -bor 0x20       [System.IO.File]::WriteAllBytes($linkFilePath, $bytes)
    }
}

