#!/bin/sh
# Grisch Minecraft setup for macOS:
#   curl -fsSL https://github.com/pronnmark/minecraft-server/releases/latest/download/join-mac.sh | sh
# Installs the official Minecraft Launcher if it is missing (Mojang-signed app, signature checked),
# waits for the player to sign in, then adds a "Grisch" profile with Fabric, Simple Voice Chat and
# Minecraft Terminal in its own folder (normal Minecraft untouched). Play joins the server directly.
# Every mod download is checked against the SHA-512 pinned when this release was built.
set -eu

VERSION_ID="@VERSION_ID@"
VERSION_JSON_B64="@VERSION_JSON_B64@"
SERVERS_DAT_B64="@SERVERS_DAT_B64@"
SERVER="@SERVER@"
# url sha512 file-prefix
MODS="
@MODS_SH@
"

say() { printf '%s\n' "$*"; }
die() { printf '\nProblem: %s\nSend a screenshot of this window to Philip.\n' "$*" >&2; exit 1; }

MC="$HOME/Library/Application Support/minecraft"
PROFILES="$MC/launcher_profiles.json"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

signed_in() {
	[ -f "$PROFILES" ] && perl -MJSON::PP -e 'local $/; for (@ARGV) { open my $f, "<", $_ or next; my $d = eval { decode_json(<$f>) } or next;
		for (values %{ $d->{accounts} || {} }) { exit 0 if ref $_->{minecraftProfile} && $_->{minecraftProfile}{name} } } exit 1' "$MC"/launcher_accounts*.json 2>/dev/null
}
app() { for a in /Applications/Minecraft.app "$HOME/Applications/Minecraft.app"; do [ -d "$a" ] && { echo "$a"; return; }; done; }

if ! signed_in; then
	if [ -z "$(app)" ]; then
		say "Installing the official Minecraft Launcher..."
		curl -fsSL --retry 3 -o "$TMP/Minecraft.dmg" https://launcher.mojang.com/download/Minecraft.dmg || die "could not download the Minecraft Launcher"
		vol=$(hdiutil attach -nobrowse -readonly "$TMP/Minecraft.dmg" | tail -1 | cut -f3-)
		codesign -dv "$vol/Minecraft.app" 2>&1 | grep -q '^TeamIdentifier=UBF8T346G9$' || { hdiutil detach "$vol" -quiet; die "the Minecraft Launcher failed its signature check"; }
		dest=/Applications; [ -w "$dest" ] || { dest="$HOME/Applications"; mkdir -p "$dest"; }
		cp -R "$vol/Minecraft.app" "$dest/"
		hdiutil detach "$vol" -quiet || true
	fi
	open "$(app)"
	say ""
	say ">>> Sign in to the Minecraft Launcher with the Microsoft account that owns Minecraft Java."
	say "    Leave this window open: it continues by itself once you are signed in."
	until signed_in; do sleep 3; done
	sleep 5
fi

# The launcher rewrites its profile file when it quits, so it must be closed while we edit it.
if pgrep -f "Minecraft.app/Contents/MacOS/launcher" >/dev/null 2>&1; then
	say "Closing the Minecraft Launcher for a moment..."
	osascript -e 'quit app "Minecraft"' >/dev/null 2>&1 || true
	sleep 3
	pkill -f "Minecraft.app/Contents/MacOS/launcher" 2>/dev/null || true
fi

GAME="$MC/grisch"
mkdir -p "$GAME/mods"

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

# Fabric version that also passes --quickPlayMultiplayer, so Play goes straight into the server.
mkdir -p "$MC/versions/$VERSION_ID"
printf '%s' "$VERSION_JSON_B64" | base64 -D > "$MC/versions/$VERSION_ID/$VERSION_ID.json"

[ -f "$GAME/servers.dat" ] || printf '%s' "$SERVERS_DAT_B64" | base64 -D > "$GAME/servers.dat"
# Skip the first-start accessibility screen, which would stop the auto-join.
[ -f "$GAME/options.txt" ] || printf 'onboardAccessibility:false\nskipMultiplayerWarning:true\n' > "$GAME/options.txt"

ID="$VERSION_ID" GAME="$GAME" perl -MJSON::PP -MPOSIX=strftime -e '
	my $f = shift; local $/; open my $in, "<", $f or die; my $d = JSON::PP->new->decode(<$in>); close $in;
	my $now = strftime("%Y-%m-%dT%H:%M:%S.000Z", gmtime);
	$d->{profiles}{grisch} = { name => "Grisch", type => "custom", icon => "Grass", created => $now,
		lastUsed => $now, lastVersionId => $ENV{ID}, gameDir => $ENV{GAME} };
	open my $out, ">", $f or die; print $out JSON::PP->new->pretty->canonical->encode($d); close $out;
' "$PROFILES"

say ""
say "Done! Press the green PLAY button in the Minecraft Launcher."
say "You join $SERVER automatically. Voice chat: V. Terminal: K."
open "$(app)" 2>/dev/null || open -a Minecraft 2>/dev/null || say "Open the Minecraft Launcher yourself."
