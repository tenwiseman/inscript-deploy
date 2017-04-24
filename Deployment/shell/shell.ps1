# This script is named shell.ps1

Write-Host "## Inscript-Deployment Script"
Write-Host "## By Tenwiseman, 2017`n"

# JSON template file.
# This will require editing to include new packages and desired machine settings.

$templateFile = "$PSScriptRoot\templates\template.json"

# JSON defaults file. Created if new running defaults are saved to override
# those defined in the template.

$defaultsFile = "$PSScriptRoot\local\defaults.json"

# load modules
Import-Module -Name NetAdapter
Import-Module -Name "$PSScriptRoot\modules\ISD" -Force

do {
    # get machine settings that match the current identified machine
    $script:machine = Get-WindowsMachineSettings -TemplateFile $templateFile
    
    # run the menu shell until either restarted or quit
    $ret = Show-InScriptMenu -TemplateFile $templateFile -DefaultsFile $defaultsFile `
        -DefaultTemplate "$($machine.template)"

} until ($ret.menuExitKey -eq "Q")