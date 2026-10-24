#!/bin/sh
# Builds the join files and publishes them as the latest release of this repo.
#   client/release.sh            # newest 26.3 versions of every mod, then `gh release create`
#   client/release.sh --dry-run  # only build client/dist/
# The files pin each mod's URL and SHA-512, so players get exactly what was checked here.
set -eu
cd "$(dirname "$0")"
MC_VERSION=26.3
SERVER=grisch.nu
mkdir -p dist
python3 - "$MC_VERSION" "$SERVER" <<'PY'
import base64, hashlib, json, re, struct, sys, urllib.parse, urllib.request
mc, server = sys.argv[1], sys.argv[2]
def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "grisch-join-builder"})
    return urllib.request.urlopen(req, timeout=60).read()
def modrinth(slug):
    q = urllib.parse.quote(json.dumps([mc]))
    v = json.loads(get(f"https://api.modrinth.com/v2/project/{slug}/version?game_versions={q}&loaders=%5B%22fabric%22%5D"))[0]
    f = next(x for x in v["files"] if x["primary"])
    return f["url"], f["hashes"]["sha512"]
import subprocess  # gh: authenticated, so no anonymous API rate limit
term = subprocess.check_output(["gh", "release", "view", "-R", "pronnmark/minecraft-terminal", "--json", "assets",
                                "-q", '.assets[] | select(.name | endswith(".jar")) | .url'], text=True).strip()
mods = [(*modrinth("fabric-api"), "fabric-api-"), (*modrinth("simple-voice-chat"), "voicechat-"),
        (term, hashlib.sha512(get(term)).hexdigest(), "minecraft-terminal-")]
for url, sha, _ in mods:  # every pinned hash is re-checked against the real download
    assert hashlib.sha512(get(url)).hexdigest() == sha, url
loader = next(l["loader"]["version"] for l in json.loads(get(f"https://meta.fabricmc.net/v2/versions/loader/{mc}")) if l["loader"]["stable"])
def nbt_str(tag, name, val):
    n, v = name.encode(), val.encode()
    return bytes([tag]) + struct.pack(">H", len(n)) + n + struct.pack(">H", len(v)) + v
entry = nbt_str(8, "name", "Grisch") + nbt_str(8, "ip", server) + b"\x00"
dat = b"\x0a\x00\x00" + b"\x09" + struct.pack(">H", 7) + b"servers" + b"\x0a" + struct.pack(">i", 1) + entry + b"\x00"
# Fabric's launcher version plus --quickPlayMultiplayer: pressing Play joins the server directly.
vid = f"grisch-{mc}"
ver = json.loads(get(f"https://meta.fabricmc.net/v2/versions/loader/{mc}/{loader}/profile/json"))
ver["id"] = vid
ver.setdefault("arguments", {}).setdefault("game", []).extend(["--quickPlayMultiplayer", server])
common = {"@VERSION_ID@": vid, "@VERSION_JSON_B64@": base64.b64encode(json.dumps(ver).encode()).decode(), "@SERVER@": server,
          "@SERVERS_DAT_B64@": base64.b64encode(dat).decode()}
def fill(text, extra):
    for k, v in {**common, **extra}.items(): text = text.replace(k, v)
    assert not re.search(r"@[A-Z_]+@", text), "unfilled placeholder"
    return text
file = lambda url: urllib.parse.unquote(url.rsplit("/", 1)[1])
ps_mods = ",\n".join(f"\t@{{ Url = '{u}'; Sha512 = '{s}'; File = '{file(u)}'; Prefix = '{p}' }}" for u, s, p in mods)
ps = fill(open("join.ps1").read(), {"@MODS_PS@": ps_mods})
open("dist/join-windows.ps1", "w", newline="\r\n").write(ps)
bat = open("bat-header.cmd").read() + ps
open("dist/Join-Grisch-Windows.bat", "w", newline="\r\n").write(bat)
sh = fill(open("join-mac.sh").read(), {"@MODS_SH@": "\n".join(f"{u} {s} {p}" for u, s, p in mods)})
open("dist/join-mac.sh", "w").write(sh)
for f in ("dist/join-windows.ps1", "dist/join-mac.sh"): open(f, encoding="ascii").read()  # irm|iex on PS 5.1 needs ASCII
print("loader", loader); [print(file(u)) for u, _, _ in mods]
PY
chmod +x dist/join-mac.sh
[ "${1:-}" = "--dry-run" ] && exit 0
tag="join-$(date -u +%Y%m%d-%H%M)"
gh release create "$tag" dist/join-windows.ps1 dist/Join-Grisch-Windows.bat dist/join-mac.sh --latest --title "Join Grisch ($tag)" --notes-file release-notes.md
