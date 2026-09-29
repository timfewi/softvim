[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
    [string]$AppName = 'nvim',
    [string]$ConfigRoot = $env:LOCALAPPDATA
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ConfigRoot)) {
    throw 'LOCALAPPDATA is not set. Specify -ConfigRoot explicitly.'
}
$source = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'nvim'))
$destination = [IO.Path]::GetFullPath((Join-Path $ConfigRoot $AppName))
$separator = [IO.Path]::DirectorySeparatorChar
if ($source.Equals($destination, [StringComparison]::OrdinalIgnoreCase) -or
    $source.StartsWith($destination.TrimEnd($separator) + $separator, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The installation destination must not contain the source configuration.'
}
if (-not (Test-Path -LiteralPath (Join-Path $source 'init.lua') -PathType Leaf)) {
    throw "Configuration source is missing: $source"
}
if (Test-Path -LiteralPath $destination) {
    $existing = Get-Item -LiteralPath $destination -Force
    if (-not $existing.PSIsContainer -or ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'The destination must be a regular directory, not a file or link.'
    }
}
if (-not $PSCmdlet.ShouldProcess($destination, 'Install Softvim; back up the existing configuration')) {
    return
}

$parent = [IO.Path]::GetDirectoryName($destination)
$suffix = [Guid]::NewGuid().ToString('N')
$staging = Join-Path $parent "$AppName.softvim-staging-$suffix"
$backup = $null
New-Item -ItemType Directory -Path $parent -Force | Out-Null
try {
    New-Item -ItemType Directory -Path $staging | Out-Null
    Get-ChildItem -LiteralPath $source -Force | Copy-Item -Destination $staging -Recurse -Force
    # Keep user overrides on upgrades, while replacing the generated mirror and plugins.
    $localSettings = Join-Path $destination 'lua/softvim/local.lua'
    if (Test-Path -LiteralPath $localSettings -PathType Leaf) {
        Copy-Item -LiteralPath $localSettings -Destination (Join-Path $staging 'lua/softvim/local.lua') -Force
    }
    if (Test-Path -LiteralPath $destination) {
        $backup = "$destination.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$suffix"
        Move-Item -LiteralPath $destination -Destination $backup
    }
    Move-Item -LiteralPath $staging -Destination $destination
} catch {
    if ($backup -and (Test-Path -LiteralPath $backup) -and -not (Test-Path -LiteralPath $destination)) {
        Move-Item -LiteralPath $backup -Destination $destination
    }
    throw
} finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
}
Write-Output "Installed Softvim at $destination"
if ($backup) {
    Write-Output "Previous configuration saved at $backup"
}
Write-Output 'Start Neovim to install plugins and language tools. Use :checkhealth softvim to inspect prerequisites.'
if ($AppName -ne 'nvim') {
    Write-Output "Set `$env:NVIM_APPNAME = '$AppName' before starting Neovim."
}
