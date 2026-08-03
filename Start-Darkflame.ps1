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

function Set-IniValue {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Key,
        [AllowEmptyString()][string] $Value
    )

    $line = "$Key=$Value"
    $found = $false

    if (Test-Path -LiteralPath $Path) {
        $content = Get-Content -LiteralPath $Path
    } else {
        $content = @()
    }

    $escapedKey = [regex]::Escape($Key)
    $updated = foreach ($row in $content) {
        if ($row -match "^\s*$escapedKey\s*=") {
            $found = $true
            $line
        } else {
            $row
        }
    }

    if (-not $found) {
        $updated += $line
    }

    Set-Content -LiteralPath $Path -Value $updated -Encoding ASCII
}

function Merge-IniDefaults {
    param(
        [Parameter(Mandatory = $true)][string] $SourcePath,
        [Parameter(Mandatory = $true)][string] $DestinationPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        return
    }

    if (Test-Path -LiteralPath $DestinationPath) {
        $destination = Get-Content -LiteralPath $DestinationPath
    } else {
        $destination = @()
    }

    $knownKeys = @{}
    foreach ($row in $destination) {
        if ($row -match "^\s*([^#;\s][^=]*)\s*=") {
            $knownKeys[$matches[1].Trim()] = $true
        }
    }

    $merged = @($destination)
    foreach ($row in (Get-Content -LiteralPath $SourcePath)) {
        if ($row -match "^\s*([^#;\s][^=]*)\s*=") {
            $key = $matches[1].Trim()
            if (-not $knownKeys.ContainsKey($key)) {
                $merged += $row
                $knownKeys[$key] = $true
            }
        }
    }

    Set-Content -LiteralPath $DestinationPath -Value $merged -Encoding ASCII
}

function Get-DarkflameServerDirectory {
    param([Parameter(Mandatory = $true)][string] $ReleaseDir)

    $serverDirectory = Get-ChildItem -LiteralPath $ReleaseDir -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq "msvc" -and (Test-Path -LiteralPath (Join-Path $_.FullName "MasterServer.exe")) } |
        Select-Object -First 1

    if (-not $serverDirectory) {
        throw "Could not find MasterServer.exe under $ReleaseDir. Check the Darkflame Windows release zip layout."
    }

    return $serverDirectory.FullName
}

$homeDir = Get-EnvOrDefault -Name "DFU_HOME" -Default "C:\darkflame"
$releaseDir = Get-EnvOrDefault -Name "DFU_RELEASE_DIR" -Default (Join-Path $homeDir "release")
$serverDir = Get-DarkflameServerDirectory -ReleaseDir $releaseDir
$configDir = Get-EnvOrDefault -Name "DLU_CONFIG_DIR" -Default (Join-Path $homeDir "configs")
$clientDir = Get-EnvOrDefault -Name "CLIENT_LOCATION" -Default (Join-Path $homeDir "client")
$dumpDir = Get-EnvOrDefault -Name "DUMP_FOLDER" -Default (Join-Path $homeDir "dump")
$logsDir = Get-EnvOrDefault -Name "LOGS_DIR" -Default (Join-Path $homeDir "logs")
$databaseType = Get-EnvOrDefault -Name "DATABASE_TYPE" -Default "sqlite"
$sqlitePath = Get-EnvOrDefault -Name "SQLITE_DATABASE_PATH" -Default (Join-Path $homeDir "resServer\dlu.sqlite")
$resServerDir = Split-Path -Path $sqlitePath -Parent
$externalIp = Get-EnvOrDefault -Name "EXTERNAL_IP" -Default "localhost"
$clientNetVersion = Get-EnvOrDefault -Name "CLIENT_NET_VERSION" -Default "171022"
$skipAccountCreation = Get-EnvOrDefault -Name "SKIP_ACCOUNT_CREATION" -Default "1"
$chatServerPort = Get-EnvOrDefault -Name "CHAT_SERVER_PORT" -Default "2005"
$maxClients = Get-EnvOrDefault -Name "MAX_CLIENTS" -Default "999"

foreach ($dir in @($configDir, $clientDir, $dumpDir, $logsDir, $resServerDir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$clientLooksPresent =
    (Test-Path -LiteralPath (Join-Path $clientDir "legouniverse.exe")) -or
    (Test-Path -LiteralPath (Join-Path $clientDir "res")) -or
    (Test-Path -LiteralPath (Join-Path $clientDir "client\legouniverse.exe"))

if (-not $clientLooksPresent) {
    Write-Host "Darkflame client files were not found in $clientDir."
    Write-Host "Upload your own LEGO Universe client files to the GSA 'client' directory before starting this container."
    exit 2
}

$configFiles = @(
    "sharedconfig.ini",
    "authconfig.ini",
    "chatconfig.ini",
    "masterconfig.ini",
    "worldconfig.ini"
)

foreach ($fileName in $configFiles) {
    $source = Join-Path $serverDir $fileName
    $destination = Join-Path $configDir $fileName

    if ((Test-Path -LiteralPath $source) -and (-not (Test-Path -LiteralPath $destination))) {
        Copy-Item -LiteralPath $source -Destination $destination
    }

    Merge-IniDefaults -SourcePath $source -DestinationPath $destination
}

$sharedConfig = Join-Path $configDir "sharedconfig.ini"
$masterConfig = Join-Path $configDir "masterconfig.ini"
$authConfig = Join-Path $configDir "authconfig.ini"
$chatConfig = Join-Path $configDir "chatconfig.ini"
Set-IniValue -Path $sharedConfig -Key "log_to_console" -Value (Get-EnvOrDefault -Name "LOG_TO_CONSOLE" -Default "1")
Set-IniValue -Path $sharedConfig -Key "external_ip" -Value $externalIp
Set-IniValue -Path $sharedConfig -Key "max_clients" -Value $maxClients
Set-IniValue -Path $sharedConfig -Key "dump_folder" -Value $dumpDir
Set-IniValue -Path $sharedConfig -Key "client_location" -Value $clientDir
Set-IniValue -Path $sharedConfig -Key "client_net_version" -Value $clientNetVersion
Set-IniValue -Path $sharedConfig -Key "chat_server_port" -Value $chatServerPort
Set-IniValue -Path $sharedConfig -Key "database_type" -Value $databaseType
Set-IniValue -Path $sharedConfig -Key "skip_account_creation" -Value $skipAccountCreation
Set-IniValue -Path $masterConfig -Key "master_ip" -Value (Get-EnvOrDefault -Name "MASTER_IP" -Default "localhost")
Set-IniValue -Path $masterConfig -Key "master_server_port" -Value (Get-EnvOrDefault -Name "MASTER_SERVER_PORT" -Default "2000")
Set-IniValue -Path $masterConfig -Key "world_port_start" -Value (Get-EnvOrDefault -Name "WORLD_PORT_START" -Default "3000")
Set-IniValue -Path $masterConfig -Key "prestart_servers" -Value (Get-EnvOrDefault -Name "PRESTART_SERVERS" -Default "1")
Set-IniValue -Path $authConfig -Key "auth_server_port" -Value (Get-EnvOrDefault -Name "AUTH_SERVER_PORT" -Default "1001")
Set-IniValue -Path $chatConfig -Key "web_server_listen_port" -Value $chatServerPort

if ($databaseType -match "^(sqlite)$") {
    Set-IniValue -Path $sharedConfig -Key "sqlite_database_path" -Value $sqlitePath
} else {
    Set-IniValue -Path $sharedConfig -Key "mysql_host" -Value (Get-EnvOrDefault -Name "MYSQL_HOST" -Default "localhost")
    Set-IniValue -Path $sharedConfig -Key "mysql_database" -Value (Get-EnvOrDefault -Name "MYSQL_DATABASE" -Default "darkflame")
    Set-IniValue -Path $sharedConfig -Key "mysql_username" -Value (Get-EnvOrDefault -Name "MYSQL_USERNAME" -Default "darkflame")
    Set-IniValue -Path $sharedConfig -Key "mysql_password" -Value (Get-EnvOrDefault -Name "MYSQL_PASSWORD" -Default "")
}

foreach ($fileName in @("authconfig.ini", "chatconfig.ini", "masterconfig.ini")) {
    $configPath = Join-Path $configDir $fileName
    if (Test-Path -LiteralPath $configPath) {
        Set-IniValue -Path $configPath -Key "external_ip" -Value $externalIp
    }
}

$env:DLU_CONFIG_DIR = $configDir
$env:CLIENT_LOCATION = $clientDir
$env:DUMP_FOLDER = $dumpDir
$env:DATABASE_TYPE = $databaseType
$env:SQLITE_DATABASE_PATH = $sqlitePath
$env:EXTERNAL_IP = $externalIp
$env:CLIENT_NET_VERSION = $clientNetVersion
$env:SKIP_ACCOUNT_CREATION = $skipAccountCreation
$env:LOG_TO_CONSOLE = Get-EnvOrDefault -Name "LOG_TO_CONSOLE" -Default "1"

Write-Host "Starting Darkflame Universe from $serverDir"
Write-Host "Config directory: $configDir"
Write-Host "Client directory: $clientDir"
Write-Host "External IP: $externalIp"
Write-Host "Database type: $databaseType"

Push-Location $serverDir
try {
    & (Join-Path $serverDir "MasterServer.exe")
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
