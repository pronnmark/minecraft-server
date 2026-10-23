#!/bin/sh
# Grisch Minecraft setup for macOS:
#   curl -fsSL https://github.com/pronnmark/minecraft-server/releases/latest/download/join-mac.sh | sh
# Adds a "Grisch" profile to the official Minecraft Launcher with Fabric, Simple Voice Chat and
# Minecraft Terminal, in its own folder so your normal Minecraft is untouched, and adds the server.
# Every mod download is checked against the SHA-512 pinned when this release was built.
set -eu

MC_VERSION="@MC_VERSION@"
LOADER="@LOADER_VERSION@"
SERVERS_DAT_B64="@SERVERS_DAT_B64@"
SERVER="@SERVER@"
# url sha512 file-prefix
MODS="
@MODS_SH@
"

say() { printf '%s\n' "$*"; }
die() { printf '\nProblem: %s\n' "$*" >&2; exit 1; }

MC="$HOME/Library/Application Support/minecraft"
PROFILES="$MC/launcher_profiles.json"
[ -f "$PROFILES" ] || die "Minecraft Launcher not found. Install it from minecraft.net, sign in, open it once, then run this again."

# The launcher rewrites its profile file when it quits, so it must be closed while we edit it.
if pgrep -f "Minecraft.app/Contents/MacOS/launcher" >/dev/null 2>&1; then
	say "Closing the Minecraft Launcher..."
	osascript -e 'quit app "Minecraft"' >/dev/null 2>&1 || true
	sleep 3
fi

GAME="$MC/grisch"
mkdir -p "$GAME/mods"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

say "Downloading mods..."
printf '%s\n' "$MODS" | while read -r url sha prefix; do
	[ -n "$url" ] || continue
	file=$(basename "$url" | sed 's/%2B/+/g')
	curl -fsSL --retry 3 -o "$TMP/$file" "$url" || die "could not download $file"
	[ "$(shasum -a 512 "$TMP/$file" | cut -d' ' -f1)" = "$sha" ] || die "$file downloaded damaged; run this again."
	rm -f "$GAME/mods/$prefix"*.jar
	mv "$TMP/$file" "$GAME/mods/$file"
	say "  $file"
done

say "Adding Fabric..."
ID="fabric-loader-$LOADER-$MC_VERSION"
mkdir -p "$MC/versions/$ID"
curl -fsSL --retry 3 -o "$MC/versions/$ID/$ID.json" \
	"https://meta.fabricmc.net/v2/versions/loader/$MC_VERSION/$LOADER/profile/json" || die "could not download Fabric"

[ -f "$GAME/servers.dat" ] || printf '%s' "$SERVERS_DAT_B64" | base64 -D > "$GAME/servers.dat"

ID="$ID" GAME="$GAME" perl -MJSON::PP -MPOSIX=strftime -e '
	my $f = shift; local $/; open my $in, "<", $f or die; my $d = JSON::PP->new->decode(<$in>); close $in;
	my $now = strftime("%Y-%m-%dT%H:%M:%S.000Z", gmtime);
	$d->{profiles}{grisch} = { name => "Grisch", type => "custom", icon => "Grass", created => $now,
		lastUsed => $now, lastVersionId => $ENV{ID}, gameDir => $ENV{GAME} };
	open my $out, ">", $f or die; print $out JSON::PP->new->pretty->canonical->encode($d); close $out;
' "$PROFILES"

say ""
say "Done! Opening the Minecraft Launcher. Press PLAY (the Grisch profile is picked), then Multiplayer -> $SERVER."
open -a Minecraft 2>/dev/null || say "Open the Minecraft Launcher yourself."
