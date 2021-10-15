# "Import" or "source" settings and functions from other .dotfiles (to prevent clutter in the profile.ps1)
#region ---- Imports ----
Import-Module -Name "Terminal-Icons"
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
oh-my-posh --init --shell pwsh --config ~/.dotfiles/ohmyposh/snacky.omp.json | Invoke-Expression
#endregion ---- /Oh-My-Posh 3 ----

#region ---- Chocolatey ----
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
#endregion ---- /Chocolatey ----

# This is here to fix a rendering issue. Not sure if it's related to the Font, OhMyPosh or the Terminal but it works ¯\_(ツ)_/¯.
Clear-Host