using namespace System.Management.Automation
using namespace System.Management.Automation.Language

#region ---- Options ----
# move cursor to end when searching history
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
# show predictions as list instead of inline completion
Set-PSReadLineOption -PredictionViewStyle ListView
#endregion ---- /Options ----

#region ---- KeyHandlers ----
# search history using up and down arrows
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# screen-recording
Set-PSReadLineKeyHandler -Chord 'Ctrl+k,Ctrl+c' -Function CaptureScreen

# parenthesize current line
Set-PSReadLineKeyHandler -Key 'Alt+(' `
                         -BriefDescription ParenthesizeSelection `
                         -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
                         -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

Set-PSReadLineKeyHandler -Key 'Alt+[' `
                         -BriefDescription ParenthesizeSelection `
                         -LongDescription "Put square brackets around the selection or entire line and move the cursor to after the closing brackets" `
                         -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '[' + $line.SubString($selectionStart, $selectionLength) + ']')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '[' + $line + ']')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

Set-PSReadLineKeyHandler -Key 'Alt+{' `
                         -BriefDescription ParenthesizeSelection `
                         -LongDescription "Put curly braces around the selection or entire line and move the cursor to after the closing braces" `
                         -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '{' + $line.SubString($selectionStart, $selectionLength) + '}')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '{' + $line + '}')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

# open downloads folder
Set-PSReadLineKeyHandler -Key 'Ctrl+j' `
                         -BriefDescription OpenDownloads `
                         -LongDescription "Open the downloads folder in explorer" `
                         -ScriptBlock {
    explorer.exe (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
}

# Sometimes you enter a command but realize you forgot to do something else first.
# This binding will let you save that command in the history so you can recall it,
# but it doesn't actually execute.  It also clears the line with RevertLine so the
# undo stack is reset - though redo will still reconstruct the command line.
Set-PSReadLineKeyHandler -Key Alt+w `
                         -BriefDescription SaveInHistory `
                         -LongDescription "Save current line in history but do not execute" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}
#endregion ---- /KeyHandlers ----