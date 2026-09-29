Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('softvim installer test ' + [Guid]::NewGuid().ToString('N'))
function Assert-True($Condition, $Message) {
    if (-not $Condition) { throw $Message }
}
try {
    & (Join-Path $root 'install.ps1') -ConfigRoot $temporary -AppName 'nvim-test' -WhatIf
    Assert-True (-not (Test-Path -LiteralPath $temporary)) 'WhatIf wrote files'
    & (Join-Path $root 'install.ps1') -ConfigRoot $temporary -AppName 'nvim-test'
    $destination = Join-Path $temporary 'nvim-test'
    Assert-True (Test-Path -LiteralPath (Join-Path $destination 'init.lua')) 'First install failed'
    Set-Content -LiteralPath (Join-Path $destination 'existing.txt') -Value 'keep me'
    $settings = Join-Path $destination 'lua/softvim/local.lua'
    Set-Content -LiteralPath $settings -Value 'return { theme = "tentaflake" }'
    & (Join-Path $root 'install.ps1') -ConfigRoot $temporary -AppName 'nvim-test'
    $backups = @(Get-ChildItem -LiteralPath $temporary -Directory -Filter 'nvim-test.backup-*')
    Assert-True ($backups.Count -eq 1) 'Upgrade did not create exactly one backup'
    Assert-True (Test-Path -LiteralPath (Join-Path $backups[0].FullName 'existing.txt')) 'Backup lost existing files'
    Assert-True ((Get-Content -LiteralPath $settings -Raw).Contains('tentaflake')) 'Upgrade lost local settings'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $destination 'existing.txt'))) 'Stale configuration was retained'
    Assert-True (@(Get-ChildItem -LiteralPath $temporary -Filter '*.softvim-staging-*').Count -eq 0) 'Staging was not cleaned'
    $refused = $false
    try {
        & (Join-Path $root 'install.ps1') -ConfigRoot $root -AppName 'nvim'
    } catch { $refused = $true }
    Assert-True $refused 'Installer allowed overwriting its own source'
    Write-Output 'Installer checks passed (WhatIf, paths with spaces, install, backup, upgrade, source protection).'
} finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
}
