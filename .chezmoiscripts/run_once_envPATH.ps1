#!/bin/pwsh
# add C:\bin to PATH
$binPath = 'C:\bin'
$userPATH = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)

if (-not $userPATH -match [regex]::Escape($binPath)) {
    [System.Environment]::SetEnvironmentVariable('PATH', $binPath + ';' + $userPATH, [System.EnvironmentVariableTarget]::User)
    $env:Path = $binPath + ';' + $env:Path
}