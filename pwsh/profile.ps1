# "Import" or "source" settings and functions from other .dotfiles (to prevent clutter in the profile.ps1)
#region ---- Imports ----
# Modules
Import-Module -Name "Terminal-Icons"

# Functions / Scripts
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
function Set-VpnSplitTunneling { Get-VpnConnection | Set-VpnConnection -SplitTunneling $true }
#endregion ---- /Functions ----

#region ---- Oh-My-Posh 3 ----
oh-my-posh --init --shell pwsh --config ~/.dotfiles/ohmyposh/snacky.omp.json | Invoke-Expression
#endregion ---- /Oh-My-Posh 3 ----

# shouldn't be necessary anymore - mostly replaced by winget
#region ---- Chocolatey ----
# $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
# if (Test-Path($ChocolateyProfile)) {
#     Import-Module "$ChocolateyProfile"
# }
#endregion ---- /Chocolatey ----

#region ---- PSReadLine ----
# enable intellisense predictions from history
Set-PSReadLineOption -PredictionSource History
# move cursor to end when searching history
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
# search history using up and down arrows
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
# screen-recording
Set-PSReadLineKeyHandler -Chord 'Ctrl+k,Ctrl+c' -Function CaptureScreen
#endregion ---- /PSReadLine ----

# ArgumentCompleters add tab-completion for 3rd-party tools
#region ---- ArgumentCompleters ----
# winget
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf7Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
#endregion ---- /ArgumentCompleters ----

# This is here to fix a rendering issue. Not sure if it's related to the Font, OhMyPosh or the Terminal but it works ¯\_(ツ)_/¯.
Clear-Host