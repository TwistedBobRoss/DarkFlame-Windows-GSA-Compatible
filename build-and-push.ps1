param(
    [string] $ImageName = "ghcr.io/twistedbobross/darkflame-windows-gsa-compatible",

    [switch] $Server2025
)

$ErrorActionPreference = "Stop"

docker build --build-arg WINDOWS_TAG=ltsc2022 -t "${ImageName}:server-2022" .
docker push "${ImageName}:server-2022"

if ($Server2025) {
    docker build --build-arg WINDOWS_TAG=ltsc2025 -t "${ImageName}:server-2025" .
    docker push "${ImageName}:server-2025"
}

Write-Host ""
Write-Host "Use this in GameServerApp:"
Write-Host "  Image: $ImageName"
Write-Host "  Version/tag: {dynamic-os-tag}"
