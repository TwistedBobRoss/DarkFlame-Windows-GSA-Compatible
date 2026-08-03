$ErrorActionPreference = "Stop"

function Get-EnvOrDefault {
    param(
        [Parameter(Mandatory = $true)][string] $Name,
        [Parameter(Mandatory = $true)][string] $Default
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value
}

function Get-DarkflameServerDirectory {
    param([Parameter(Mandatory = $true)][string] $ReleaseDir)

    $serverDirectory = Get-ChildItem -LiteralPath $ReleaseDir -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq "msvc" -and (Test-Path -LiteralPath (Join-Path $_.FullName "MasterServer.exe")) } |
        Select-Object -First 1

    if (-not $serverDirectory) {
        throw "Could not find MasterServer.exe under $ReleaseDir."
    }

    return $serverDirectory.FullName
}

$homeDir = Get-EnvOrDefault -Name "DFU_HOME" -Default "C:\darkflame"
$releaseDir = Get-EnvOrDefault -Name "DFU_RELEASE_DIR" -Default (Join-Path $homeDir "release")
$serverDir = Get-DarkflameServerDirectory -ReleaseDir $releaseDir
$env:DLU_CONFIG_DIR = Get-EnvOrDefault -Name "DLU_CONFIG_DIR" -Default (Join-Path $homeDir "configs")
$env:CLIENT_LOCATION = Get-EnvOrDefault -Name "CLIENT_LOCATION" -Default (Join-Path $homeDir "client")
$env:DUMP_FOLDER = Get-EnvOrDefault -Name "DUMP_FOLDER" -Default (Join-Path $homeDir "dump")
$env:DATABASE_TYPE = Get-EnvOrDefault -Name "DATABASE_TYPE" -Default "sqlite"
$env:SQLITE_DATABASE_PATH = Get-EnvOrDefault -Name "SQLITE_DATABASE_PATH" -Default (Join-Path $homeDir "resServer\dlu.sqlite")
$env:EXTERNAL_IP = Get-EnvOrDefault -Name "EXTERNAL_IP" -Default "localhost"
$env:CLIENT_NET_VERSION = Get-EnvOrDefault -Name "CLIENT_NET_VERSION" -Default "171022"
$env:SKIP_ACCOUNT_CREATION = "1"

Push-Location $serverDir
try {
    & (Join-Path $serverDir "MasterServer.exe") -a
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
