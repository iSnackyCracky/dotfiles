# Set PowerShell default encoding to utf8 (this is especially needed later for Oh-My-Posh)
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

$PROFILEPATH = (Get-Item $PROFILE).DirectoryName

#region ---- Oh-My-Posh ----
oh-my-posh init pwsh | Invoke-Expression
#endregion ---- /Oh-My-Posh ----


# Deferred profile loading, taken from
# https://fsackur.github.io/2023/11/20/Deferred-profile-loading-for-better-performance/
$Deferred = {
    Import-Module "Terminal-Icons"

    # Functions / scripts / further profile config
    foreach ($script in (Get-ChildItem -Path "$PROFILEPATH\Functions","$PROFILEPATH\Config" -Filter *.ps1 -Recurse)) {
        Invoke-Expression ". ""$script"""
    }

    # Function definitions - larger functions should go into their own script-file and be imported (see above)
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
    function Edit-Profile { chezmoi edit $PROFILE }
    function ccd { Set-Location (chezmoi source-path) }

    $EDITOR = if (Test-CommandExists nvim) { 'nvim' }
          elseif (Test-CommandExists pvim) { 'pvim' }
          elseif (Test-CommandExists vim) { 'vim' }
          elseif (Test-CommandExists vi) { 'vi' }
          elseif (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists codium) { 'codium' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }

    # Alias Definitions
    #region ---- Aliases ----
    New-Alias -Name dig -Value Resolve-Dns
    New-Alias -Name e -Value Start-Explorer
    New-Alias -Name vi -Value $EDITOR
    New-Alias -Name vim -Value $EDITOR
    #endregion ---- /Aliases ----

    # add zoxide
    Invoke-Expression (& { (zoxide init powershell | Out-String) })

    # winget ArgumentCompleter
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $Local:word = $wordToComplete.Replace('"', '""')
        $Local:ast = $commandAst.ToString().Replace('"', '""')
        winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    # Uncomment this to clear all errors stored in the $error variable after initializing profile
    # This includes errors hidden by the '-ErrorAction SilentlyContinue' parameter
    #$error.clear()
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