# minecraft-server

## Join

- **Windows:** download [Join-Grisch-Windows.bat](https://github.com/pronnmark/minecraft-server/releases/latest/download/Join-Grisch-Windows.bat) and double-click it. "Windows protected your PC" → **More info → Run anyway**.
- **Mac:** paste in Terminal: `curl -fsSL https://github.com/pronnmark/minecraft-server/releases/latest/download/join-mac.sh | sh`

Then press **Play** in the Minecraft Launcher (the **Grisch** profile is picked) → **Multiplayer** → **Grisch**. Voice chat and the in-game terminal (press K) come with it. Needs the official Minecraft Launcher, signed in and opened once; your normal Minecraft is not changed.

Update the files: `client/release.sh` (pins the newest 26.3 Fabric API, Simple Voice Chat and [minecraft-terminal](https://github.com/pronnmark/minecraft-terminal) with SHA-512s and publishes a release).

Production-ready Minecraft Java Edition server running on pbox via Docker Compose.

- **Engine:** PaperMC (high-performance vanilla-compatible Java Edition)
- **Port:** `25565` (TCP/UDP)
- **Proximity voice chat:** [Simple Voice Chat](https://modrinth.com/plugin/simple-voice-chat) plugin, auto-installed from Modrinth (`MODRINTH_PROJECTS`). Voice uses UDP `24454`. Each player needs the Simple Voice Chat client mod (Fabric/NeoForge/Forge); press `V` in-game for settings.
- **Everyone hears everyone:** [VoiceServer](https://modrinth.com/plugin/voiceserver) auto-joins every player to one persistent open voice group, `Everyone`, so voice works at any distance and across dimensions. Players can leave it with `G`.
- **Join instructions:** [Custom Join Messages](https://modrinth.com/plugin/custom-join-messages) sends every joining player a private chat message with the voice-chat mod link. The text lives in `configs.join-messages-chat` in the compose file; edit it there and redeploy.
- **Public Domains & Fun Hostnames:**
  - `grisch.nu` (or `mc.grisch.nu`)
  - `lall.se` (or `mc.lall.se`)
  - `pcplay.se` (or `mc.pcplay.se`)
  - `gaymasen.se` (or `mc.gaymasen.se`)
  - `daq.se` (or `mc.daq.se`)
  - `blpk.cc` (or `mc.blpk.cc`)
- **Internal / Mesh Reachability:**
  - Tailscale mesh: `100.64.0.2:25565` or `pbox.mesh.hostbun.cc:25565`
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
