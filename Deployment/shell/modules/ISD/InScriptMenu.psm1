﻿# This script is named InScriptMenu.psm1


function Show-InScriptMenu {
<#
    .DESCRIPTION

 
 [CmdletBinding()]

 Param(
    

    [parameter(Mandatory=$false)]

    [parameter(Mandatory=$false)]

    [parameter(Mandatory=$false)]

    )

    if ($TemplateFile) {
        <#

        $script:myTemplates = get-content "$TemplateFile" | ConvertFrom-Json

        # save name of this script, to create a desktop shortcut
        $script:caller = $PSCmdlet.MyInvocation.ScriptName

        if ($DefaultsFile) {
            if (Test-Path "$DefaultsFile") {
                $script:mySettings = get-content "$DefaultsFile" | ConvertFrom-Json
            } else {
                $script:mySettings = $myTemplates.defaultSets
                $script:mySettings.activeTemplate = $DefaultTemplate
            }
            $script:DefaultsFilename = $DefaultsFile
        }
    }


    do {

        # either show active template menu, or the menu passed explicitly
        if ($menu = Get-InScriptMenu -UseMenu $UseMenu) {
    
            $menu | Write-InScriptMenu | Write-BoxBorder -Title $menu.name | Write-Host
        
            $menuKey = Read-Host -Prompt 'Enter Choice '

            switch ($menuKey) {
                "Q" {
                    write-host "Quit"
                    break;   
                }

                "R" {
                    write-host "Restart"
                    break;
                }

                "" {
                    clear   
                }

                default {
                
                    $e = ($menu | Start-SingleMenuCommand -MenuCommand $menuKey)
                    if ($e.menuExitKey) {
                        if ($e.menuExitKey -eq "R") {
                            # exit parent menu, the 'R' command cascades out to shell.ps1 and restarts it from the top
                            $menuKey = "R"
                        }
                    } elseif ($e) {
                        # display script standard output if any
                        Write-Host "$e" -foregroundcolor "Yellow"
                    }

                }
            }
        } else {
            break
        }
    } until ($menuKey -in ("Q","R"))

    return @{"menuExitKey" = "$menuKey"}

}

function Get-InScriptMenu {
# Get menu for the activeTemplate, or same for supplied sub menu name.
    Param(
    
    )

    if ($UseMenu -eq '') {
        $UseTemplate = $mySettings.activeTemplate
    } else {
        $UseTemplate = $UseMenu
    }

    $myTemplates.menus | where-object {$_.name -eq $UseTemplate} 

}


function Save-InScriptMenuDefaultSettings {
# Save default settings to be used as a default in future use of this ISM

    Write-Host "* saving to $DefaultsFilename"

    $mySettings | ConvertTo-Json | Out-File "$DefaultsFilename"
    Write-Host "Settings Saved"
}

function Reset-InScriptMenuDefaultSettings {
# remove saved defaults file to reinstate template defaults instead

    if (Test-Path "$DefaultsFilename") {
        Write-Host "* Removing $DefaultsFilename"
        Remove-Item -Path "$DefaultsFilename"

        Write-Host "* Restarting script"
        @{"menuExitKey" = "R"}
    }
}

function Write-InScriptMenu {
<#

    Param(

    )
    
    # show mysettings

    $mySettings | Write-ObjectProperties -lenName 20 -Title "current run settings"

    foreach ($sname in $menu.sections) {

        $sect = ($myTemplates.sections | where-object {$_.name -eq $sname})

        "$($sect.name) commands:"

        foreach ($item in $sect.items) {
            if ($item.menukey) {
                "{0,8}  {1}" -f "$($sect.prefix)$($item.menukey)", $item.descr
            }
        } 
        ""
         
    }
  
}


function Invoke-InScriptMenuCommand {

    [CmdletBinding()]

    Param(


        [parameter(Mandatory=$false)]
    )


    process {
    
        write-host "SELECTED $($sect.prefix)$($item.menukey) : $($item.descr)" -foregroundcolor "Yellow"

        if ($item.skipConfirm -or $AutoRun) {
            $key = 'yes'
        } else {
            $key = Read-Host -Prompt 'Run this? (y/n)'
        }

        if ($key[0] -eq 'y') {

            if ($item.installCmd) {
                if ($AutoRun -and $DummyRun) {
                    write-host "CMD NOT RUN : $($item.installCmd)" -foregroundcolor "Cyan"
                } else {
                    write-host "CMD $($item.installCmd)" -foregroundcolor "Cyan"
                    
                    cmd /c "$($item.installCmd)"
                }
            }

            if ($item.scriptPs1) {
                if ($AutoRun -and $DummyRun) {
                    write-host "PS NOT RUN : $($item.scriptPs1)" -foregroundcolor "Cyan"
                } else {
                    write-host "PS $($item.scriptPs1)" -foregroundcolor "Cyan"
                    Invoke-Expression $item.scriptPs1
                }
            }

            if ($item.scriptAu3) {
                if ($AutoRun -and $DummyRun) {
                    write-host "AU3 NOT RUN : $($item.scriptAu3)" -foregroundcolor "Cyan"
                } else {
                    write-host "AU3 $($item.scriptAu3)" -foregroundcolor "Cyan"
                    if (Test-Path "c:\program files (x86)\autoit3\autoit3.exe") {
                        cmd /c "`"c:\program files (x86)\autoit3\autoit3.exe`" `"$($item.scriptAu3)`""
                    } else {
                        write-host "AU3 AutoIT.exe NOT FOUND!" -foregroundcolor "Red"
                    }
                }
            }
        }
    }

}

function write-MultipleMenuCommands {
# consecutively show all commands in menu

    Param(
    )


    foreach ($sname in $menu.sections) {

        $sect = ($myTemplates.sections | where-object {$_.name -eq $sname})

        if ($sect.name -notin 'menu','main') {
                    
            foreach ($item in $sect.items) {
                if ($item.menukey) {
                    "{0,8}  {1}" -f "$($sect.prefix)$($item.menukey)", $item.descr
                }
            } 
        }
    }
  

    "NOTE : dummyRun = {0}, singleStep = {1}" -f $mySettings.dummyRun, $mySettings.singleStep

}







function Start-MultipleMenuCommands {
# consecutively run all commands in menu

    Param(
    )

    $menu |  write-MultipleMenuCommands | write-BoxBorder -Title "run preview" | Write-Host
    

   
    $key = Read-Host -Prompt '? Run ALL of these commands? (y/n)'
        
    if ($key[0] -eq 'y') {

        foreach ($sname in $menu.sections) {

            $sect = ($myTemplates.sections | where-object {$_.name -eq $sname})

            if ($sect.name -notin 'menu','main') {
                   
                    write-host " *** $($sect.name) running ***"
                    $autoRun = ![System.Convert]::ToBoolean($mySettings.singleStep)
                    $dummyRun = [System.Convert]::ToBoolean($mySettings.dummyRun)

                   
                    $sect.items |
                        Invoke-InScriptMenuCommand -AutoRun $autoRun -DummyRun $dummyRun
            }
        }

        "RUN COMPLETED!" | Write-BoxBorder | Write-BoxBorder | Write-Host -foregroundcolor "Yellow"
    }

}


function Start-SingleMenuCommand {
# run a single command from menu

    Param(

        [parameter(ValueFromPipeline)]
    
        [parameter(Mandatory=$true)]
    foreach ($sname in $menu.sections) {

        $sect = ($myTemplates.sections | where-object {$_.name -eq $sname})

        if ($sect.prefix -eq $MenuCommand[0]) {
            $sect.items | where-object {$_.menukey -eq $MenuCommand.substring(1)} |
                Invoke-InScriptMenuCommand
        }
         
    } 

}

     
# Export-ModuleMember -Function Show-InScriptMenu