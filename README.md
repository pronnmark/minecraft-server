# minecraft-server

Production-ready Minecraft Java Edition server running on pbox via Docker Compose.

- **Engine:** PaperMC (high-performance vanilla-compatible Java Edition)
- **Port:** `25565` (TCP/UDP)
- **Network Reachability:**
  - Tailscale mesh: `100.64.0.2:25565` (accessible from pmac, phones, laptops, and all servers)
  - Localhost / LAN: `127.0.0.1:25565` or `pbox:25565`
- **Memory Allocation:** 2GB Initial / 4GB Max (Aikar garbage collection flags enabled)
- **Data Persistence:** `./data` volume mount

## Quick Start

```bash
# Start the server in background
./manage.sh start

# View real-time logs
./manage.sh logs

# Check container and port status
./manage.sh status

# Open interactive Minecraft console (RCON)
./manage.sh console

# Run a single command via RCON
./manage.sh rcon "list"

# Graceful stop
./manage.sh stop

# Create a timestamped backup archive
./manage.sh backup
```

## Configuration

Server options are configured in `.env` (copied from `.env.example`):

- `SERVER_TYPE`: `PAPER` (default), `VANILLA`, `FABRIC`, `SPIGOT`, etc.
- `MINECRAFT_VERSION`: `LATEST` or a specific release (e.g. `1.21.1`).
- `MEMORY`: Memory limit (e.g. `4G`).
- `ONLINE_MODE`: `TRUE` for Mojang account auth, `FALSE` for offline mode.
- `RCON_PASSWORD`: Password for remote console (bound to `127.0.0.1:25575`).
