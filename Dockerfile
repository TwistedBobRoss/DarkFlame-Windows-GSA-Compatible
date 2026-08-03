# escape=`
ARG WINDOWS_TAG=ltsc2022
FROM mcr.microsoft.com/windows/servercore:${WINDOWS_TAG}

SHELL ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

ARG DARKFLAME_RELEASE_URL=https://github.com/DarkflameUniverse/DarkflameServer/releases/latest/download/darkflameserver-windows.zip
ENV DARKFLAME_RELEASE_URL=${DARKFLAME_RELEASE_URL}
ENV DFU_HOME=C:\darkflame
ENV DFU_RELEASE_DIR=C:\darkflame\release
ENV CLIENT_LOCATION=C:\darkflame\client
ENV DLU_CONFIG_DIR=C:\darkflame\configs
ENV DUMP_FOLDER=C:\darkflame\dump
ENV DATABASE_TYPE=sqlite
ENV SQLITE_DATABASE_PATH=C:\darkflame\resServer\dlu.sqlite
ENV EXTERNAL_IP=localhost
ENV CLIENT_NET_VERSION=171022
ENV SKIP_ACCOUNT_CREATION=1
ENV LOG_TO_CONSOLE=1

WORKDIR C:\darkflame

RUN $ErrorActionPreference = 'Stop'; `
    $ProgressPreference = 'SilentlyContinue'; `
    New-Item -ItemType Directory -Force -Path `
        $env:DFU_RELEASE_DIR, `
        $env:CLIENT_LOCATION, `
        $env:DLU_CONFIG_DIR, `
        $env:DUMP_FOLDER, `
        'C:\darkflame\logs', `
        'C:\darkflame\resServer' | Out-Null; `
    Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile 'C:\darkflame\vc_redist.x64.exe'; `
    Start-Process 'C:\darkflame\vc_redist.x64.exe' -ArgumentList '/install', '/quiet', '/norestart' -Wait; `
    Remove-Item 'C:\darkflame\vc_redist.x64.exe' -Force; `
    Invoke-WebRequest -Uri $env:DARKFLAME_RELEASE_URL -OutFile 'C:\darkflame\darkflameserver-windows.zip'; `
    Expand-Archive -LiteralPath 'C:\darkflame\darkflameserver-windows.zip' -DestinationPath $env:DFU_RELEASE_DIR -Force; `
    Remove-Item 'C:\darkflame\darkflameserver-windows.zip' -Force

COPY Start-Darkflame.ps1 C:\darkflame\Start-Darkflame.ps1
COPY Create-Admin.ps1 C:\darkflame\Create-Admin.ps1

EXPOSE 1001/udp 2005/udp 3000-3300/udp

ENTRYPOINT ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "C:\\darkflame\\Start-Darkflame.ps1"]
