<#
.SYNOPSIS
    Get the current public IP-Address.
.DESCRIPTION
    Uses ipify.org to retrieve the current public IP-Adress associated to the system/internet connection.

    By default uses the "universal IPv4/IPv6" endpoint api64.ipify.org.
    This will use either IPv4 or IPv6 depending on what is available on the system.
    If both Protocols are available, the operating system will most likely prefer the usage of IPv6.

    To get both IPv4 and IPv6 addresses at once, specify both -IPv4 and -IPv6 parameters.
.PARAMETER IPv4
    Retrieve the public IPv4 Address.
    Forces the usage of IPv4 (ipify API endpoint: api.ipify.org).
.PARAMETER IPv6
    Retrieve the public IPv6 Address.
    Forces the usage of IPv6 (ipify API endpoint: api6.ipify.org).
.EXAMPLE
    Get-PublicIPAddress

    AddressFamily IPAddress
    ------------- ---------
    IPv6          2001:db8:85a3:8d3:1319:8a2e:370:7344
.EXAMPLE
    Get-PublicIPAddress -IPv4

    AddressFamily IPAddress
    ------------- ---------
    IPv4          203.0.113.12
.EXAMPLE
    Get-PublicIPAddress -IPv4 -IPv6

    AddressFamily IPAddress
    ------------- ---------
    IPv4          203.0.113.12
    IPv6          2001:db8:85a3:8d3:1319:8a2e:370:7344
.INPUTS
    None. You cannot pipe objects to Get-PublicIPAddress.
.OUTPUTS
    System.String[]. Get-PublicIPAddress returns a string or array of strings with the IPv4/IPv6 Address(es).
.LINK
    ipify.org: https://www.ipify.org/
#>
function Get-PublicIPAddress {
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
                   PositionalBinding=$false,
                   ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        [Parameter()]
        [Alias("v4")] 
        [switch]
        $IPv4,
        
        [Parameter()]
        [Alias("v6")] 
        [switch]
        $IPv6
    )
    
    begin {
        $serviceUriV4 = "https://api.ipify.org"
        $serviceUriV6 = "https://api6.ipify.org"
        $serviceUriV64 = "https://api64.ipify.org"
    }
    
    process {
        $output = @()
        if ($IPv4) {
            try {
                $result = [ipaddress]"$( Invoke-RestMethod -Uri $serviceUriV4 )"
                $output += [PSCustomObject]@{
                    AddressFamily = if ($result.AddressFamily -eq "InterNetwork") {"IPv4"} elseif ($result.AddressFamily -eq "InterNetworkV6") {"IPv6"} else {$result.AddressFamily}
                    IPAddress = $result.IPAddressToString
                }
            }
            catch { Write-Error -Message "Could not retrieve IPv4 Address." }
        }
        if ($IPv6) {
            try {
                $result = [ipaddress]"$( Invoke-RestMethod -Uri $serviceUriV6 )"
                $output += [PSCustomObject]@{
                    AddressFamily = if ($result.AddressFamily -eq "InterNetwork") {"IPv4"} elseif ($result.AddressFamily -eq "InterNetworkV6") {"IPv6"} else {$result.AddressFamily}
                    IPAddress = $result.IPAddressToString
                }
            }
            catch { Write-Error -Message "Could not retrieve IPv6 Address." }
        }
        if (!$IPv4 -and !$IPv6) {
            $result = [ipaddress]"$( Invoke-RestMethod -Uri $serviceUriV64 )"
            $output += [PSCustomObject]@{
                AddressFamily = if ($result.AddressFamily -eq "InterNetwork") {"IPv4"} elseif ($result.AddressFamily -eq "InterNetworkV6") {"IPv6"} else {$result.AddressFamily}
                IPAddress = $result.IPAddressToString
            }
        }
        $output
    }
    
    end {
    }
}