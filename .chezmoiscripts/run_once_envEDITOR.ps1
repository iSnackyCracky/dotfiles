#!/bin/pwsh
# Sets up the EDITOR environment variable
function Test-CommandExists($command) { return ($null -ne (Get-Command $command -ErrorAction SilentlyContinue)) }

$env:EDITOR = if (Test-CommandExists nvim) { 'nvim' }
elseif (Test-CommandExists pvim) { 'pvim' }
elseif (Test-CommandExists vim) { 'vim' }
elseif (Test-CommandExists vi) { 'vi' }
elseif (Test-CommandExists code) { 'code' }
elseif (Test-CommandExists codium) { 'codium' }
elseif (Test-CommandExists notepad++) { 'notepad++' }
elseif (Test-CommandExists sublime_text) { 'sublime_text' }
else { 'notepad' }

[System.Environment]::SetEnvironmentVariable('EDITOR', $env:EDITOR, [System.EnvironmentVariableTarget]::User)