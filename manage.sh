#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|console|rcon <cmd>|backup}"
    exit 1
}

case "${1:-}" in
    start)
        echo "Starting Minecraft server..."
        docker compose up -d
        echo "Server starting. Run '$0 logs' to watch startup."
        ;;
    stop)
        echo "Stopping Minecraft server gracefully..."
        docker compose down
        echo "Server stopped."
        ;;
    restart)
        echo "Restarting Minecraft server..."
        docker compose restart
        ;;
    status)
        echo "=== Container Status ==="
        docker compose ps
        echo ""
        echo "=== Port Listeners ==="
        ss -tulpn | grep 25565 || echo "Port 25565 is not currently listening."
        echo ""
        echo "=== Tailscale Address ==="
        echo "Direct Tailscale connect: 100.64.0.2:25565"
        ;;
    logs)
        docker compose logs -f
        ;;
    console)
        echo "Connecting to Minecraft console (rcon)... Press Ctrl+C to exit."
        docker compose exec minecraft rcon-cli
        ;;
    rcon)
        shift
        if [ "$#" -eq 0 ]; then
            echo "Error: Command required for rcon. Example: $0 rcon 'list'"
            exit 1
        fi
        docker compose exec minecraft rcon-cli "$@"
        ;;
    backup)
        TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
        BACKUP_FILE="backup_minecraft_${TIMESTAMP}.tar.gz"
        echo "Creating backup: ${BACKUP_FILE}..."
        tar -czf "${BACKUP_FILE}" data/
        echo "Backup created: ${BACKUP_FILE}"
        ;;
    *)
        usage
        ;;
esac
