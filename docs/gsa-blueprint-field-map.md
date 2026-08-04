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
- `game` base `1001/udp` - auth/login, exposed to the container as `{gameserver.game_port}`
- `raw` base `2005/udp` - chat server port, exposed to the container as `{gameserver.raw_port}`
- `query` base `3000/udp` - world port start, exposed to the container as `{gameserver.query_port}`

The blueprint enables `automatic_ports` so GSA controls port assignment. Darkflame increments world ports from `world_port_start`; this blueprint maps the startup world port for GSA compatibility.

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
- `AUTH_SERVER_PORT={gameserver.game_port}`
- `CHAT_SERVER_PORT={gameserver.raw_port}`
- `WORLD_PORT_START={gameserver.query_port}`
- `MASTER_IP=localhost`
- `MASTER_SERVER_PORT=2000`
- `PRESTART_SERVERS=1`
- `DONT_USE_KEYS=1`
- `REWARDCODES=4,30`
- `CHAT_WEB_SERVER_ENABLED=0`

Use `CLIENT_NET_VERSION=171023` only if your client is the Darkflame Universe client build that expects that network version.

GSA configuration fields:
- `External IP` -> `sharedconfig.ini external_ip`, `authconfig.ini external_ip`, `chatconfig.ini external_ip`, and `masterconfig.ini external_ip`
- `Client Net Version` -> `sharedconfig.ini client_net_version`
- `Database Type` -> `sharedconfig.ini database_type`
- `Skip Interactive Account Check` -> `sharedconfig.ini skip_account_creation`
- `Log To Console` -> `sharedconfig.ini log_to_console`
- `Master IP` -> `masterconfig.ini master_ip`
- `Master Server Port` -> `masterconfig.ini master_server_port`
- `Prestart Servers` -> `masterconfig.ini prestart_servers`
- `Ignore Play Keys` -> `authconfig.ini dont_use_keys`
- `Default Reward Codes` -> `authconfig.ini rewardcodes`
- `Chat Web Server` -> `chatconfig.ini web_server_enabled`
- `MariaDB Host`, `MariaDB Database`, `MariaDB Username`, `MariaDB Password` -> `sharedconfig.ini mysql_*` when MariaDB is selected

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
