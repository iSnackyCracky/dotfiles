#region ---- Oh-My-Posh ----
oh-my-posh init pwsh | Invoke-Expression
#endregion ---- /Oh-My-Posh ----

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
#Clear-Host


# Deferred profile loading, taken from
# https://fsackur.github.io/2023/11/20/Deferred-profile-loading-for-better-performance/
$Deferred = {
    # "Import" or "source" settings and functions from other .dotfiles (to prevent clutter in the profile.ps1)
    #region ---- Imports ----
    # Modules
    Import-Module -Name "Terminal-Icons"

    # Functions / Scripts
    foreach ($script in (Get-ChildItem -Path "$env:dotfiles\pwsh" -Exclude profile.ps1 -Filter *.ps1 -Recurse)) {
        Invoke-Expression ". ""$script"""
    }
    #endregion ---- /Imports ----

    # Function definitions - larger functions should go into their own script-file and be imported (see above)
    #region ---- Functions ----
    function Set-VpnSplitTunneling($name) { if ($name) { $vpn = Get-VpnConnection $name } else { $vpn = Get-VpnConnection }; $vpn | Set-VpnConnection -SplitTunneling $true }

    function which($name) { Get-Command $name | Select-Object -ExpandProperty Definition }

    function tail { param($Path, $n = 10, [switch]$f = $false); Get-Content $Path -Tail $n -Wait:$f }

    # Open explorer in current directory (or given Path)
    function Start-Explorer {
        param(
            # Specifies a path to one or more locations.
            [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
            [Alias("PSPath")]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path = ".\"
        )
        Start-Process -FilePath explorer.exe -ArgumentList $Path
    }

    function Test-CommandExists($command) { return ($null -ne (Get-Command $command -ErrorAction SilentlyContinue)) }
    function Edit-Profile { vim "$env:DOTFILES\pwsh\profile.ps1" }
    #endregion ---- /Functions ----

    #region ---- Variables ----
    $EDITOR = if (Test-CommandExists nvim) { 'nvim' }
          elseif (Test-CommandExists pvim) { 'pvim' }
          elseif (Test-CommandExists vim) { 'vim' }
          elseif (Test-CommandExists vi) { 'vi' }
          elseif (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists codium) { 'codium' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }
    #endregion ---- /Variables ----

    # Alias Definitions
    #region ---- Aliases ----
    New-Alias -Name dig -Value Resolve-Dns
    New-Alias -Name e -Value Start-Explorer
    New-Alias -Name vi -Value $EDITOR
    New-Alias -Name vim -Value $EDITOR
    #endregion ---- /Aliases ----

    #region ---- zoxide ----
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
    #endregion ---- /zoxide ----
}


# https://seeminglyscience.github.io/powershell/2017/09/30/invocation-operators-states-and-scopes
$GlobalState = [psmoduleinfo]::new($false)
$GlobalState.SessionState = $ExecutionContext.SessionState

# to run our code asynchronously
$Runspace = [runspacefactory]::CreateRunspace($Host)
$Powershell = [powershell]::Create($Runspace)
$Runspace.Open()
$Runspace.SessionStateProxy.PSVariable.Set('GlobalState', $GlobalState)

# ArgumentCompleters are set on the ExecutionContext, not the SessionState
# Note that $ExecutionContext is not an ExecutionContext, it's an EngineIntrinsics 😡
$Private = [Reflection.BindingFlags]'Instance, NonPublic'
$ContextField = [Management.Automation.EngineIntrinsics].GetField('_context', $Private)
$Context = $ContextField.GetValue($ExecutionContext)

# Get the ArgumentCompleters. If null, initialise them.
$ContextCACProperty = $Context.GetType().GetProperty('CustomArgumentCompleters', $Private)
$ContextNACProperty = $Context.GetType().GetProperty('NativeArgumentCompleters', $Private)
$CAC = $ContextCACProperty.GetValue($Context)
$NAC = $ContextNACProperty.GetValue($Context)
if ($null -eq $CAC)
{
    $CAC = [Collections.Generic.Dictionary[string, scriptblock]]::new()
    $ContextCACProperty.SetValue($Context, $CAC)
}
if ($null -eq $NAC)
{
    $NAC = [Collections.Generic.Dictionary[string, scriptblock]]::new()
    $ContextNACProperty.SetValue($Context, $NAC)
}

# Get the AutomationEngine and ExecutionContext of the runspace
$RSEngineField = $Runspace.GetType().GetField('_engine', $Private)
$RSEngine = $RSEngineField.GetValue($Runspace)
$EngineContextField = $RSEngine.GetType().GetFields($Private) | Where-Object {$_.FieldType.Name -eq 'ExecutionContext'}
$RSContext = $EngineContextField.GetValue($RSEngine)

# Set the runspace to use the global ArgumentCompleters
$ContextCACProperty.SetValue($RSContext, $CAC)
$ContextNACProperty.SetValue($RSContext, $NAC)

$Wrapper = {
    # Without a sleep, you get issues:
    #   - occasional crashes
    #   - prompt not rendered
    #   - no highlighting
    # Assumption: this is related to PSReadLine.
    # 20ms seems to be enough on my machine, but let's be generous - this is non-blocking
    Start-Sleep -Milliseconds 200

    . $GlobalState {. $Deferred; Remove-Variable Deferred}
}

$null = $Powershell.AddScript($Wrapper.ToString()).BeginInvoke()