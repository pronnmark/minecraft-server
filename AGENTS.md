# minecraft-server — Minecraft Java Edition on pbox

Docker Compose-managed PaperMC server running on `pbox` exposing standard Java port `25565`.

## Commands

| action | command | notes |
|---|---|---|
| start | `./manage.sh start` | `docker compose up -d` |
| stop | `./manage.sh stop` | graceful shutdown via `docker compose down` |
| restart | `./manage.sh restart` | restarts container |
| status | `./manage.sh status` | container state + port listener test |
| logs | `./manage.sh logs` | streams stdout |
| rcon | `./manage.sh rcon "<cmd>"` | runs Minecraft command |
| backup | `./manage.sh backup` | creates tar.gz snapshot of `./data` |

## Rules

- **Do not commit world data or secrets.** World data lives in `./data/` and credentials live in `.env`, both gitignored.
- **Port 25565 is the SSOT.** Do not remap default Minecraft port unless explicitly instructed.
- **Tailscale reachability:** The server binds `0.0.0.0:25565` and is reachable across the Tailscale mesh at `100.64.0.2:25565`.
- **Voice chat:** Simple Voice Chat plugin via `MODRINTH_PROJECTS`; UDP `24454` published on pbox; hostbun forwards it with kernel DNAT (3 rules tagged `minecraft voice chat -> pbox` in `/etc/iptables/rules.v4`). Never use socat/userspace UDP proxies: they change the source port per packet and break the voice handshake ("Voice not connected").
- **One voice group:** VoiceServer plugin creates a persistent open group `Everyone` and auto-joins every player (compose `configs.voiceserver-config`).
- **Join messages:** Custom Join Messages plugin; `chat.yml` comes from compose `configs:` and overwrites the live file on every start (`PLUGINS_SYNC_UPDATE=false`). Edit the compose file, not `data/plugins`.
- **Join files:** `client/release.sh` builds `join-windows.ps1` (Win+R `irm | iex` one-liner), `Join-Grisch-Windows.bat` (same script) and `join-mac.sh` from `client/join.ps1` / `client/join-mac.sh` and publishes them as this repo's latest GitHub release. They install the official launcher if missing (signature checked: Microsoft on Windows, Mojang team `UBF8T346G9` on Mac), wait for sign-in, add a `Grisch` profile (own `gameDir` `.minecraft/grisch`) on version `grisch-26.3` = Fabric's version JSON plus `--quickPlayMultiplayer grisch.nu` (Play joins directly), pin each mod by SHA-512, seed `servers.dat`, and skip the first-start accessibility screen via `options.txt` (it blocks quick play). Re-run it after a Minecraft or mod update. Tested 2026-10-24: Windows script on `ww` (signed-in copy + fresh-PC installer path); quick-play join proven with a real 26.3 client against grisch.nu; Mac script only on Linux with macOS stubs (pmac was offline).
- **Live deploy is Coolify** (app `zlqnp3ytyoyfrxptqhrbddt3`, compose `/docker-compose.yaml`). `coolify app start zlqnp3ytyoyfrxptqhrbddt3` brings it back; `manage.sh` here conflicts with that container name.
- **Memory safety:** Default is 4GB heap (`MEMORY=4G`) with Aikar tuning flags enabled.
