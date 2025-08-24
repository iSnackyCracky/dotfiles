function Optimize-Rasphone {
    [CmdletBinding()]
    param (
        [string]$Phonebook = "$( $env:APPDATA )\Microsoft\Network\Connections\Pbk\rasphone.pbk",
        [string]$Prioritize
    )
    
    begin {
        # initialize empty array for later sorting
        $rasphoneEntries = @()
        $entryName = ""
        $entryContent = ""

        $prioFilter = "*$( $Prioritize )*"
        $entryCount = 0
    }
    
    process {
        Write-Verbose "Reading from $Phonebook"
        $rasphoneContent = Get-Content -Path $Phonebook

        foreach ($line in $rasphoneContent) {
            # lines starting with "[" are the beginning of a new entry in rasphone.pbk
            if ($line.StartsWith("[")) {
                $entryCount++
                $entry = [PSCustomObject]@{
                    Name    = $entryName
                    Content = $entryContent
                }
                $rasphoneEntries += $entry
                $entryName = $line.Substring($line.IndexOf("[") + 1, $line.Length - 2)
                $entryContent = ""
            }
            $entryContent += $line + [Environment]::NewLine
        }

        # create new entry object for the last entry
        $entry = [PSCustomObject]@{
            Name    = $entryName
            Content = $entryContent
        }
        $rasphoneEntries += $entry

        Write-Verbose "Read $entryCount entries"
        # remove empty entries (the first will always be an empty one,
        # cause we create it before reading any content), prioritize and sort by name
        $sortedRasphoneEntries = @()
        Write-Verbose "Prioritizing entries matching $prioFilter"
        $sortedRasphoneEntries += $rasphoneEntries | Where-Object { $_.Name -ne "" -and $_.Name -like "$prioFilter" } | Sort-Object -Property Name
        $sortedRasphoneEntries += $rasphoneEntries | Where-Object { $_.Name -ne "" -and $_.Name -notlike "$prioFilter" } | Sort-Object -Property Name

        # clear rasphone.pbk so we don't need to handle the first entry differently
        Write-Verbose "Writing $( $sortedRasphoneEntries.Count ) entries to $Phonebook"
        Set-Content -Path $Phonebook -Value ""
        foreach ($entry in $sortedRasphoneEntries) {
            $entry.Content | Out-File -Path $Phonebook -Force -Append
        }
    }
    
    end {
        
    }
}

