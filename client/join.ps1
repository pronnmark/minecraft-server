# Grisch Minecraft setup for Windows. Shipped inside Join-Grisch-Windows.bat; double-click that.
# Adds a "Grisch" profile to the official Minecraft Launcher with Fabric, Simple Voice Chat and
# Minecraft Terminal, in its own folder so your normal Minecraft is untouched, and adds the server.
# Every mod download is checked against the SHA-512 pinned when this release was built.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$McVersion = '@MC_VERSION@'
$Loader = '@LOADER_VERSION@'
$Mods = @(
@MODS_PS@
)
$ServersDat = '@SERVERS_DAT_B64@'
$Server = '@SERVER@'

function Say($m) { Write-Host $m }
function Fail($m) { Write-Host ''; Write-Host "Problem: $m" -ForegroundColor Red; exit 1 }

$mc = Join-Path $env:APPDATA '.minecraft'
$profileFiles = @('launcher_profiles.json', 'launcher_profiles_microsoft_store.json') |
	ForEach-Object { Join-Path $mc $_ } | Where-Object { Test-Path $_ }
if (-not $profileFiles) {
	Fail 'Minecraft Launcher not found. Install it from minecraft.net, sign in, open it once, then run this again.'
}

# The launcher rewrites its profile file when it closes, so it must be closed while we edit it.
$launcher = Get-Process -Name 'MinecraftLauncher', 'Minecraft' -ErrorAction SilentlyContinue
if ($launcher) { Say 'Closing the Minecraft Launcher...'; $launcher | Stop-Process -Force; Start-Sleep 2 }

$game = Join-Path $mc 'grisch'
$modsDir = Join-Path $game 'mods'
New-Item -ItemType Directory -Force -Path $modsDir | Out-Null

Say 'Downloading mods...'
foreach ($m in $Mods) {
	$tmp = Join-Path $env:TEMP $m.File
	Invoke-WebRequest -UseBasicParsing -Uri $m.Url -OutFile $tmp
	if ((Get-FileHash $tmp -Algorithm SHA512).Hash.ToLower() -ne $m.Sha512) { Fail "$($m.File) downloaded damaged; run this again." }
	Get-ChildItem $modsDir -Filter "$($m.Prefix)*.jar" | Remove-Item -Force
	Move-Item -Force $tmp (Join-Path $modsDir $m.File)
	Say "  $($m.File)"
}

Say 'Adding Fabric...'
$id = "fabric-loader-$Loader-$McVersion"
$verDir = Join-Path $mc "versions\$id"
New-Item -ItemType Directory -Force -Path $verDir | Out-Null
$json = (Invoke-WebRequest -UseBasicParsing -Uri "https://meta.fabricmc.net/v2/versions/loader/$McVersion/$Loader/profile/json").Content
$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText((Join-Path $verDir "$id.json"), $json, $utf8)

$serversFile = Join-Path $game 'servers.dat'
if (-not (Test-Path $serversFile)) { [IO.File]::WriteAllBytes($serversFile, [Convert]::FromBase64String($ServersDat)) }

$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
foreach ($f in $profileFiles) {
	$data = Get-Content -Raw -LiteralPath $f | ConvertFrom-Json
	if (-not $data.profiles) { $data | Add-Member -Force -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{}) }
	$p = [pscustomobject]@{
		name = 'Grisch'; type = 'custom'; icon = 'Grass'; created = $now; lastUsed = $now
		lastVersionId = $id; gameDir = $game
	}
	$data.profiles | Add-Member -Force -NotePropertyName 'grisch' -NotePropertyValue $p
	[IO.File]::WriteAllText($f, ($data | ConvertTo-Json -Depth 32), $utf8)
}

Say ''
Write-Host 'Done!' -ForegroundColor Green
Say "Opening the Minecraft Launcher. Press PLAY (the Grisch profile is picked), then Multiplayer -> $Server."
$store = Get-AppxPackage -Name 'Microsoft.4297127D64EC6' -ErrorAction SilentlyContinue
$exe = Join-Path ${env:ProgramFiles(x86)} 'Minecraft Launcher\MinecraftLauncher.exe'
try {
	if ($store) { Start-Process "shell:AppsFolder\$($store.PackageFamilyName)!Minecraft" }
	elseif (Test-Path $exe) { Start-Process $exe }
} catch { Say 'Open the Minecraft Launcher yourself.' }
