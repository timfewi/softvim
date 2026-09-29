Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('softvim runtime test ' + [Guid]::NewGuid().ToString('N'))
$variables = @('LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CACHE_HOME', 'NVIM_APPNAME')
$previous = @{}
foreach ($name in $variables) {
    $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
Push-Location $root
try {
    $env:LOCALAPPDATA = $temporary
    $env:XDG_CONFIG_HOME = Join-Path $temporary 'config'
    $env:XDG_DATA_HOME = Join-Path $temporary 'data'
    $env:XDG_STATE_HOME = Join-Path $temporary 'state'
    $env:XDG_CACHE_HOME = Join-Path $temporary 'cache'
    $env:NVIM_APPNAME = 'softvim-test'
    & (Join-Path $PSScriptRoot 'install.ps1')
    & nvim --headless -u NONE -l checks/core.lua
    if ($LASTEXITCODE -ne 0) { throw 'Core checks failed.' }
    # Ask Neovim for its native path rather than assume Unix path conventions.
    $config = (& nvim --headless -u NONE -c "lua io.write(vim.fn.stdpath('config'))" -c 'qa') -join ''
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($config)) {
        throw 'Could not resolve the Neovim config path.'
    }
    & (Join-Path $root 'install.ps1') -ConfigRoot ([IO.Path]::GetDirectoryName($config)) -AppName $env:NVIM_APPNAME
    Set-Content -LiteralPath (Join-Path $config 'lua/softvim/local.lua') -Value 'return { install_tools = false, install_parsers = false }'
    & nvim --headless '+Lazy! restore' '+qa'
    if ($LASTEXITCODE -ne 0) { throw 'Plugin bootstrap failed.' }
    $capture = 'lua _G.softvim_errors = {}; vim.notify = function(msg, level) if level == vim.log.levels.ERROR then table.insert(_G.softvim_errors, tostring(msg)) end end'
    & nvim --headless --cmd $capture -c "lua dofile('checks/windows-tools.lua')"
    if ($LASTEXITCODE -ne 0) { throw 'Windows parser and Mason checks failed.' }
    & nvim --headless --cmd $capture -c "lua dofile('checks/runtime.lua')"
    if ($LASTEXITCODE -ne 0) { throw 'Windows runtime checks failed.' }
} finally {
    Pop-Location
    foreach ($name in $variables) {
        [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process')
    }
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
}
