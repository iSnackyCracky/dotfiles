# "Import" or "source" settings and functions from other .dotfiles (to prevent clutter in the profile.ps1)
#region ---- Imports ----
foreach ($script in (Get-ChildItem -Path "$env:dotfiles\pwsh" -Exclude profile.ps1 -Filter *.ps1 -Recurse)) {
    Invoke-Expression ". ""$script"""
}
#endregion ---- /Imports ----

# Alias Definitions
#region ---- Aliases ----
New-Alias -Name dig -Value Resolve-Dns
#endregion ---- /Aliases ----

# Function definitions - larger functions should go into their own script-file and be imported (see above)
#region ---- Functions ----
function Set-VpnSplitTunneling {
    Get-VpnConnection | Set-VpnConnection -SplitTunneling $true
}
#endregion ---- /Functions ----

#region ---- Oh-My-Posh 3 ----
[ScriptBlock]$Prompt = {
    # ThemeName (i.e. the theme-configfile without .omp.json)
    $themeName = "snacky"
    
    $lastCommandSuccess = $?
    $realLASTEXITCODE = $global:LASTEXITCODE
    $errorCode = 0
    if ($lastCommandSuccess -eq $false) {
        #native app exit code
        if ($realLASTEXITCODE -is [int] -and $realLASTEXITCODE -gt 0) {
            $errorCode = $realLASTEXITCODE
        }
        else {
            $errorCode = 1
        }
    }

    $executionTime = -1
    $history = Get-History -ErrorAction Ignore -Count 1
    if ($null -ne $history -and $null -ne $history.EndExecutionTime -and $null -ne $history.StartExecutionTime) {
        $executionTime = ($history.EndExecutionTime - $history.StartExecutionTime).TotalMilliseconds
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "oh-my-posh"
    $cleanPWD = $PWD.ProviderPath.TrimEnd("\")
    $startInfo.Arguments = "-config=""$env:dotfiles\ohmyposh\$themeName.omp.json"" -error=$errorCode -pwd=""$cleanPWD"" -execution-time=$executionTime"
    $startInfo.Environment["TERM"] = "xterm-256color"
    $startInfo.CreateNoWindow = $true
    $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    if ($PWD.Provider.Name -eq 'FileSystem') {
        $startInfo.WorkingDirectory = $PWD.ProviderPath
    }
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    $standardOut = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    $standardOut
    $global:LASTEXITCODE = $realLASTEXITCODE
    #remove temp variables
    Remove-Variable realLASTEXITCODE -Confirm:$false
    Remove-Variable lastCommandSuccess -Confirm:$false
    Remove-Variable themeName -Confirm:$false
}
Set-Item -Path Function:prompt -Value $Prompt -Force
#endregion ---- /Oh-My-Posh 3 ----

#region ---- Chocolatey ----
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
#endregion ---- /Chocolatey ----

# This is here to fix a rendering issue. Not sure if it's related to the Font, OhMyPosh or the Terminal but it works ¯\_(ツ)_/¯.
Clear-Host