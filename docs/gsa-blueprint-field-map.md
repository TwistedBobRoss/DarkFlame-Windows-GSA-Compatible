# GameServerApp Blueprint Field Map

Blueprint name: `Darkflame Universe Windows`

Game:
- Game: `Custom game`
- Template: `Import Custom Docker Container`
- OS: `Windows`
- Monitoring: `Container`
- Recovery mode: `Enabled`
- Command/control: leave disabled. Darkflame Universe does not expose standard RCON.

Docker image:
- Image: `ghcr.io/twistedbobross/darkflame-windows-gsa-compatible`
- Version/tag: `server-2022`

If you only build one image, use that exact tag instead, for example `server-2022`.

Ports:
- `1001/udp` to `1001/udp` - auth/login
- `2005/udp` to `2005/udp` - chat server port used by the default config
- `3000-3300/udp` to `3000-3300/udp` - world instances

Darkflame uses fixed LEGO Universe ports. Plan on one Darkflame Universe server per public IP unless you customize the client and server config.

Mounts:
- Host: `{container.home_root}/client`
  Container: `C:\darkflame\client`
  Mode: read-only after upload
- Host: `{container.home_root}/configs`
  Container: `C:\darkflame\configs`
- Host: `{container.home_root}/resServer`
  Container: `C:\darkflame\resServer`
- Host: `{container.home_root}/logs`
  Container: `C:\darkflame\logs`
- Host: `{container.home_root}/dump`
  Container: `C:\darkflame\dump`

Environment variables:
- `CLIENT_LOCATION=C:\darkflame\client`
- `DLU_CONFIG_DIR=C:\darkflame\configs`
- `DUMP_FOLDER=C:\darkflame\dump`
- `DATABASE_TYPE=sqlite`
- `SQLITE_DATABASE_PATH=C:\darkflame\resServer\dlu.sqlite`
- `EXTERNAL_IP={machine.ip}`
- `CLIENT_NET_VERSION=171022`
- `SKIP_ACCOUNT_CREATION=1`
- `LOG_TO_CONSOLE=1`

Use `CLIENT_NET_VERSION=171023` only if your client is the Darkflame Universe client build that expects that network version.

Directories:
- `client`, path `\client`, create `Yes`
- `configs`, path `\configs`, create `Yes`
- `resServer`, path `\resServer`, create `Yes`
- `logs`, path `\logs`, create `Yes`, type `Logs`
- `dump`, path `\dump`, create `Yes`, type `Logs` or `Other`

Config template files:
- `sharedconfig.ini`, path `\configs\sharedconfig.ini`
- `authconfig.ini`, path `\configs\authconfig.ini`
- `chatconfig.ini`, path `\configs\chatconfig.ini`
- `masterconfig.ini`, path `\configs\masterconfig.ini`
- `worldconfig.ini`, path `\configs\worldconfig.ini`

Backup folders:
- Name: `configs`, path `\configs`
- Name: `resServer`, path `\resServer`

Wipe folders:
- `\resServer`
- `\logs`
- `\dump`

Do not wipe `\client` or `\configs` unless you want to reinstall from scratch.
