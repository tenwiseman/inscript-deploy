﻿# This script is named WindowsMachine.psm1

function Get-WindowsMachineSettings {
    .DESCRIPTION

    Param(
        [parameter(Mandatory=$false)]
    )

    $identifier = Get-WindowsMachineIdentifier -TemplateFile $TemplateFile

    $t = get-content "$TemplateFile" | ConvertFrom-Json
    
    $t.machines | where-object {$_.identifier -eq  $identifier}
 
}

function Set-WindowsMachineIdentifier {
    .DESCRIPTION

    $currentId  = [Environment]::GetEnvironmentVariable("ISM_MACHINE_ID","Machine") 

    if (!($identifier = Read-Host -Prompt "Enter ID [$currentId]")) {
        # if null entry, assign previous
        $identifier = $currentId
    }

    Write-Host "* ISM_MACHINE_ID = $identifier"

    [Environment]::SetEnvironmentVariable("ISM_MACHINE_ID", "$identifier", "Machine")

    return $identifer
}


function Get-WindowsMachineIdentifier {
    .DESCRIPTION

        [parameter(Mandatory=$false)]
    )
    $t = get-content "$TemplateFile" | ConvertFrom-Json

    do {
        $identifier = [Environment]::GetEnvironmentVariable("ISM_MACHINE_ID","Machine")

        if (!($mach = $t.machines | where-object {$_.identifier -eq $identifier})) {
            Write-Host "? ISM_MACHINE_ID = $identifier"
            Write-Host "* This machine ID is undefined or does not exist in the template file!"
            Write-Host "* Please assign a valid one from this list!"
           
            $t.machines | Write-ObjectProperties | Write-Host

            $identifier = Set-WindowsMachineIdentifier
        }
    } until ($mach)

    # show set identifier
    $mach | Write-ObjectProperties | Write-Host


    return $identifier
    
}





function Update-WindowsComputerName {
    .DESCRIPTION


    Param(
        [parameter(Mandatory=$true)]
    )

    # need to read this from machine not env
    $currentName = [system.environment]::MachineName
    

    Write-Host "Computer Name : $currentName"

    if ((get-location).drive.name -ne "C") {
        Write-Host "* Aborting Update-WindowsComputerName as NOT running from C:" 
        return
    }

    if ($currentName -ne $NewName) {

        "RESTARTING NOW!!" | Write-BoxBorder | Write-BoxBorder | Write-Host -ForegroundColor "Yellow"
        
        Rename-Computer -NewName $NewName -Force -Restart

        Start-Sleep -Seconds 120
        
    }

}

function Get-WindowsPCNetConfiguration {
<#
    .SYNOPSIS
    .DESCRIPTION


    Get-WindowsPCNetConfiguration -IFindx 11
#>

    Param(
    
        [parameter(Mandatory=$false)]
    )

    # IP address
    $myIPaddr = get-netipaddress -InterfaceIndex $IFindx -AddressFamily IPv4

    if (($myIPaddr | measure).Count -eq 1) {
    
        $net = New-Object –TypeName PSObject
        $net | Add-Member -Name 'IPaddr0' -MemberType Noteproperty -Value $myIPaddr[0].IPAddress

        # gateway address
        $myGWaddr = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue).NextHop
        $net | Add-Member -Name 'GWaddr' -MemberType Noteproperty -Value $myGWaddr

        # DNS address 
        $myDNSaddr = Get-DnsClientServerAddress -InterfaceIndex $IFindx -AddressFamily IPv4
        $net | Add-Member -Name 'DNSaddr0' -MemberType Noteproperty -Value $myDNSaddr.ServerAddresses[0]

        # ConfigSet
        $net | Add-Member -Name 'Config' -MemberType Noteproperty -Value $ConfigSet

   
    } else {

        Write-Host "* Aborting, Non-Distinct IP addressses $myIPaddr found at interface #$IFindx"

    }

    return $net

}




function Update-WindowsPCNetConfiguration
{  
<#
    .DESCRIPTION

     -GWaddr $machine.GWaddr -DNSaddr $machine.DNSaddr"
                
    Param(
    

    # find interface with current active Ip configuration
    $IFindx = (Get-WmiObject win32_networkadapterconfiguration -Filter 'IPEnabled="true"').InterfaceIndex
   
    $ConfigSet = ""

    $IPtable = @()

    if ($net = Get-WindowsPCNetConfiguration -IFindx $IFindx -ConfigSet $ConfigSet) {
        
        $IPtable += $net

        # avoid disconnection if this script is running from network
        if ((get-location).drive.name -eq "C") {

            $myGWaddr = $net.GWaddr
            $myDNSaddr0 = $net.DNSaddr0

            ## if not correct IP address
            if ( $net.IPaddr0 -ne $IPaddr ) {

                ## remove all IP addresses at this interface
                remove-NetIPAddress -InterfaceIndex $IFindx -AddressFamily IPv4 -confirm:$false

                ## new IP address
                Write-Host "Creating new IP address, $IPaddr"
                New-NetIPAddress -InterfaceIndex $IFindx -IPAddress $IPaddr -PrefixLength 24 | Out-Null

                ## refetch gateway address, may have changed?
                $myGWaddr = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue).NextHop 

                ## DNS address will have to be redefined
                $myDNSaddr0 = ""
                $ConfigSet += "+IP"

            }

            ## remove gateway if defined and incorrect
            if ( $myGWaddr -and $myGWaddr -ne $GWaddr ) {

                Write-Host "Removing Incorrect Gateway, $myGWaddr"
                Remove-NetRoute -InterfaceIndex $IFindx -NextHop $net.GWaddr -confirm:$false

                $ConfigSet += "-GW"
            }

            ## new gateway address
            if ( $myGWaddr -ne $GWaddr ) {

                Write-Host "Adding New Gateway, $GWaddr"
                New-NetRoute -InterfaceIndex $IFindx -NextHop $GWaddr -DestinationPrefix "0.0.0.0/0" | Out-Null

                $ConfigSet += "+GW"
            }

            ## correct DNS address
            if ( $myDNSaddr0 -ne $DNSaddr) {

                Write-Host "Adding New DNSaddr, $DNSaddr"
                Set-DnsClientServerAddress -InterfaceIndex $IFindx -ServerAddresses $DNSaddr

                $ConfigSet += "+DNS"
            }

            # get changes if made
            if ($ConfigSet -ne "") {
                $net = Get-WindowsPCNetConfiguration -IFindx $IFindx -ConfigSet $ConfigSet
                $IPtable += $net
            } else {
                Write-Host "* Aborting ac-update-PCNetConfiguration as NOT running from C:" 
            }
        }


        # show side by side with changes if made
        if ($IPtable){
            $IPtable |  Write-ObjectProperties | Write-Host
        }
    }
       
}

Export-ModuleMember -Function Get-WindowsMachineSettings, Set-WindowsMachineIdentifier,
    Update-WindowsComputerName, Get-WindowsPCNetConfiguration, Update-WindowsPCNetConfiguration
