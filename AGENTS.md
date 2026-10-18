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
- **Memory safety:** Default is 4GB heap (`MEMORY=4G`) with Aikar tuning flags enabled.
