# This script is named WindowsMachine.psm1

function Get-WindowsMachineSettings {<#    .SYNOPSIS    Returns machine settings for identified computer.
    .DESCRIPTION
    Given template file, return machines object for identified machine.    .EXAMPLE    $script:machine = Get-WindowsMachineSettings -TemplateFile $templateFile#>
    Param(
        [parameter(Mandatory=$false)]        [String] $TemplateFile
    )

    $identifier = Get-WindowsMachineIdentifier -TemplateFile $TemplateFile
    $t = get-content "$TemplateFile" | ConvertFrom-Json
    $t.machines | where-object {$_.identifier -eq  $identifier}
}

function Set-WindowsMachineIdentifier {<#    .SYNOPSIS    Set machine identifier.
    .DESCRIPTION
    Set machines identifer. This is a system environment variable.    .EXAMPLE    Set-WindowsMachineIdentifier#>
    $currentId  = [Environment]::GetEnvironmentVariable("ISM_MACHINE_ID","Machine") 

    if (!($identifier = Read-Host -Prompt "Enter ID [$currentId]")) {
        # if null entry, assign previous
        $identifier = $currentId
    }

    Write-Host "* ISM_MACHINE_ID = $identifier"

    [Environment]::SetEnvironmentVariable("ISM_MACHINE_ID", "$identifier", "Machine")

    return $identifer
}


function Get-WindowsMachineIdentifier {<#    .SYNOPSIS    Returns machine identifier.
    .DESCRIPTION
    return machines identifer. This is a system environment variable. If not found, create a valid one    .EXAMPLE    Get-WindowsMachineIdentifier#>    Param(
        [parameter(Mandatory=$false)]        [String] $TemplateFile
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
    Write-Host "* This machine will be configured using these settings"
    $mach | Write-ObjectProperties | Write-Host


    return $identifier
    
}





function Update-WindowsComputerName {<#    .SYNOPSIS    Update Computer name if incorrect
    .DESCRIPTION
     Update Computer name if incorrect. Will force an immediate reboot.    .EXAMPLE    $script:machine = Update-WindowsComputerName -NewName "CCTV1"#>

    Param(
        [parameter(Mandatory=$true)]        [String] $NewName
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
    .SYNOPSIS    Get network configuration
    .DESCRIPTION
    Get network configuration into a hash    .EXAMPLE

    Get-WindowsPCNetConfiguration -IFindx 11
#>

    Param(
            [parameter(Mandatory=$true)]        [String] $IFindx,
        [parameter(Mandatory=$false)]        [String] $ConfigSet
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
<#    .SYNOPSIS    Update Computer network configuration if incorrect
    .DESCRIPTION
    Update Computer network configuration if incorrect, and script running from C:    .EXAMPLE    Update-WindowsPCNetConfiguration -IPaddr $machine.IPaddr
     -GWaddr $machine.GWaddr -DNSaddr $machine.DNSaddr"
                #>
    Param(
            [parameter(Mandatory=$true)]        [String] $IPaddr,            [parameter(Mandatory=$true)]        [String] $GWaddr,            [parameter(Mandatory=$true)]        [String] $DNSaddr             )

    Write-Host "* Querying current network configuration ..."

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

# Export-ModuleMember -Function Get-WindowsMachineSettings, Set-WindowsMachineIdentifier,
#     Update-WindowsComputerName, Get-WindowsPCNetConfiguration, Update-WindowsPCNetConfiguration

