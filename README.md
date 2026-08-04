# Darkflame Universe for GameServerApp on Windows

Windows container and GameServerApp blueprint draft for hosting Darkflame Universe servers.

Darkflame Universe is an open-source LEGO Universe server emulator. This project packages the official Darkflame Windows release into a Windows Server container wrapper with persistent configuration, SQLite server data, logs, crash dumps, and GameServerApp-friendly startup behavior.

## Project Information

- Container and blueprint author: **TwistedBobRoss**
- Upstream server project: **DarkflameUniverse/DarkflameServer**
- Project type: unofficial community hosting integration
- Host operating system: Windows Server 2022 with Windows containers
- Primary image: `ghcr.io/twistedbobross/darkflame-windows-gsa-compatible:server-2022`
- Raw blueprint: [gsa-blueprint.json](https://raw.githubusercontent.com/TwistedBobRoss/DarkFlame-Windows-GSA-Compatible/main/gsa-blueprint.json)
- Release notes: [CHANGELOG.md](CHANGELOG.md)

Darkflame Universe is AGPL-3.0 software. This repository does not include LEGO Universe client files, game assets, or LEGO trademarks.

## What This Provides

- Windows Server Core container wrapper
- Automatic download of the latest upstream Darkflame Windows release at image build time
- GameServerApp custom Docker blueprint draft
- Persistent mounted `client`, `configs`, `resServer`, `logs`, and `dump` folders
- SQLite-first setup for a self-contained GSA game server
- Startup wrapper that seeds missing upstream INI defaults, applies GSA settings, and launches `MasterServer.exe`
- Helper script for creating the initial admin account with `MasterServer.exe -a`
- Container monitoring support for GSA recovery

## Requirements

- Windows Server 2022 or a host compatible with LTSC 2022 Windows containers
- GameServerApp DediConnect installed and connected
- Docker configured for Windows containers
- Your own final-version LEGO Universe client files
- Enough disk space for Windows container layers and the Darkflame release

Darkflame Universe does not distribute LEGO Universe client files. Upload your own client files through GSA FTP into the blueprint's `client` directory before starting the server.

## GameServerApp Installation

Manual import path:

```text
https://raw.githubusercontent.com/TwistedBobRoss/DarkFlame-Windows-GSA-Compatible/main/gsa-blueprint.json
```

Alternative custom Docker import command:

```text
docs/docker-run-for-gsa-import.txt
```

After importing, review the fields in:

```text
docs/gsa-blueprint-field-map.md
```

Use **Container** monitoring in the GSA blueprint. Darkflame Universe does not expose a standard RCON interface for GSA player/control integration.

## First Start

1. Install a server with the blueprint.
2. Upload your LEGO Universe client files into `\client` via GSA FTP.
3. Start the container.
4. Confirm logs show Darkflame starting from `C:\darkflame\release\...\msvc`.
5. Create the first admin account.

Admin account helper:

```powershell
docker exec -it CONTAINER_NAME powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\darkflame\Create-Admin.ps1
```

The container name is shown in the GSA game server settings page. If SQLite reports a database lock, stop the server before running the admin helper, then start it again afterward.

## Ports

Darkflame Universe uses fixed LEGO Universe ports:

| Purpose | Protocol | Default |
| --- | --- | ---: |
| Auth/login | UDP | `1001` |
| Chat | UDP | `2005` |
| World start | UDP | GSA `query` port, base `3000` |

The blueprint enables GSA automatic port assignment. Darkflame increments world ports from `world_port_start`; this GSA blueprint maps the startup world port and writes the assigned values into the Darkflame INI files on container startup.

## Persistent Storage

The blueprint mounts:

```text
Host:      {container.home_root}/client
Container: C:\darkflame\client

Host:      {container.home_root}/configs
Container: C:\darkflame\configs

Host:      {container.home_root}/resServer
Container: C:\darkflame\resServer

Host:      {container.home_root}/logs
Container: C:\darkflame\logs

Host:      {container.home_root}/dump
Container: C:\darkflame\dump
```

Important paths:

```text
\client       Your LEGO Universe client files
\configs      Darkflame INI files
\resServer    SQLite database and generated server resource data
\logs         Runtime logs
\dump         Crash dumps
```

Back up `\configs` and `\resServer`. Do not wipe `\client` unless you are reinstalling from scratch.

## Configuration

GSA exposes the startup-critical Darkflame settings:

| Parameter | Default | Purpose |
| --- | --- | --- |
| External IP | `{machine.ip}` | Public IP advertised to clients. |
| Client Net Version | `171022` | LEGO Universe 1.10.64 compatibility. |
| Database Type | `sqlite` | Self-contained default. |
| Skip Interactive Account Check | `1` | Required for non-interactive startup. |
| Log To Console | `1` | Mirrors logs into Docker/GSA logs. |
| Master IP | `localhost` | Internal all-in-one master server address. |
| Master Server Port | `2000` | Internal master server port. |
| Prestart Servers | `1` | Starts the child services automatically. |
| Ignore Play Keys | `1` | Allows test accounts without LU play keys. |
| Default Reward Codes | `4,30` | Upstream default account reward codes. |
| Chat Web Server | `0` | Keeps the optional chat web server disabled. |
| MariaDB Host | `localhost` | Used only when MariaDB is selected. |
| MariaDB Database | `darkflame` | Used only when MariaDB is selected. |
| MariaDB Username | `darkflame` | Used only when MariaDB is selected. |
| MariaDB Password | empty | Used only when MariaDB is selected. |

Use `171023` only for a Darkflame Universe client build that expects that network version.

The wrapper seeds missing INI keys from the upstream Darkflame release, then applies the GSA-controlled values at every start. Advanced manual INI edits in `\configs` are preserved unless they target a key that GSA intentionally manages.

## Build The Image

```powershell
.\build-and-push.ps1
```

Or explicitly:

```powershell
.\build-and-push.ps1 -ImageName "ghcr.io/twistedbobross/darkflame-windows-gsa-compatible"
```

For Windows Server 2025 too:

```powershell
.\build-and-push.ps1 -Server2025
```

## Direct Docker Example

```powershell
docker run -d --name darkflame-test `
  -p 1001:1001/udp `
  -p 2005:2005/udp `
  -p 3000-3300:3000-3300/udp `
  -v C:\darkflame-test\client:C:\darkflame\client:ro `
  -v C:\darkflame-test\configs:C:\darkflame\configs `
  -v C:\darkflame-test\resServer:C:\darkflame\resServer `
  -v C:\darkflame-test\logs:C:\darkflame\logs `
  -v C:\darkflame-test\dump:C:\darkflame\dump `
  -e EXTERNAL_IP="127.0.0.1" `
  ghcr.io/twistedbobross/darkflame-windows-gsa-compatible:server-2022
```

## Troubleshooting

### Container Exits Immediately

- Confirm the `client` mount contains your LEGO Universe client files.
- The wrapper exits with code `2` when it cannot find `legouniverse.exe`, `res`, or `client\legouniverse.exe`.
- Upload the client via GSA FTP and restart.

### Players Cannot Connect

- Confirm `EXTERNAL_IP` is reachable by the players.
- Confirm GSA assigned and opened the `game`, `raw`, and `query` UDP ports.
- Confirm the client `boot.cfg` points to your server IP and disables LEGO's old UGC 3D services setting.
- Confirm the client network version matches `CLIENT_NET_VERSION`.

### Admin Creation Hangs Or Fails

- Stop the running server first if SQLite is locked.
- Run `Create-Admin.ps1` through `docker exec`.
- Restart the server after the account is created.

### Config Changes Do Not Stick

- Edit the persistent files under `\configs`.
- Check whether the key is one of the GSA-managed startup values.
- Restart the container after edits.

## Repository Files

```text
blueprints/darkflame-windows-gsa-compatible.json  GameServerApp blueprint draft
Dockerfile                                      Windows container image
Start-Darkflame.ps1                            Runtime startup wrapper
Create-Admin.ps1                               Initial admin helper
docs/                                          GSA import/reference notes
.github/workflows/                             GHCR image build workflow
```

## Sources And Credits

- [DarkflameUniverse/DarkflameServer](https://github.com/DarkflameUniverse/DarkflameServer)
- [Darkflame Universe website](https://www.darkflameuniverse.org/)
- [GameServerApp blueprint documentation](https://docs.gameserverapp.com/dashboard/blueprints/create_and_manage_blueprints/)

Darkflame Universe is maintained by the Darkflame Universe contributors. This GameServerApp integration, container wrapper, and documentation are maintained by TwistedBobRoss.
