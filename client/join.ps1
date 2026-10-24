# Grisch Minecraft setup for Windows. Two ways to run it:
#   Win+R, paste:  powershell -c "irm https://github.com/pronnmark/minecraft-server/releases/latest/download/join-windows.ps1 | iex"
#   or double-click Join-Grisch-Windows.bat (same script).
# Installs the official Minecraft Launcher if it is missing (Microsoft-signed installer, signature checked),
# waits for the player to sign in, then adds a "Grisch" profile with Fabric, Simple Voice Chat and
# Minecraft Terminal in its own folder (normal Minecraft untouched). Play joins the server directly.
# Every mod download is checked against the SHA-512 pinned when this release was built.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$VersionId = '@VERSION_ID@'
$VersionJson = '@VERSION_JSON_B64@'
$Mods = @(
@MODS_PS@
)
$ServersDat = '@SERVERS_DAT_B64@'
$Server = '@SERVER@'

function Say($m) { Write-Host $m }
function Fail($m) {
	Write-Host ''; Write-Host "Problem: $m" -ForegroundColor Red
	Write-Host 'Send a screenshot of this window to Philip.'
	Read-Host 'Press Enter to close' | Out-Null; exit 1
}
trap { Fail $_.Exception.Message }

$mc = Join-Path $env:APPDATA '.minecraft'
$utf8 = New-Object System.Text.UTF8Encoding $false

function Find-Launcher {
	$store = Get-AppxPackage -Name 'Microsoft.4297127D64EC6' -ErrorAction SilentlyContinue | Select-Object -First 1
	if ($store) { return "shell:AppsFolder\$($store.PackageFamilyName)!Minecraft" }
	foreach ($p in @((Join-Path ${env:ProgramFiles(x86)} 'Minecraft Launcher\MinecraftLauncher.exe'),
			'C:\XboxGames\Minecraft Launcher\Content\Minecraft.exe')) { if (Test-Path $p) { return $p } }
	return $null
}
function Open-Launcher { $l = Find-Launcher; if ($l) { try { Start-Process $l } catch {} } }
function Test-SignedIn {
	if (-not (Test-Path (Join-Path $mc 'launcher_profiles.json'))) { return $false }
	foreach ($f in Get-ChildItem $mc -Filter 'launcher_accounts*.json' -ErrorAction SilentlyContinue) {
		try { $d = Get-Content -Raw -LiteralPath $f.FullName | ConvertFrom-Json } catch { continue }
		foreach ($a in @($d.accounts.PSObject.Properties)) { if ($a.Value.minecraftProfile.name) { return $true } }
	}
	return $false
}

if (-not (Test-SignedIn)) {
	if (-not (Find-Launcher)) {
		Say 'Downloading the official Minecraft Launcher...'
		$inst = Join-Path $env:TEMP 'MinecraftInstaller.exe'
		Invoke-WebRequest -UseBasicParsing -Uri 'https://launcher.mojang.com/download/MinecraftInstaller.exe' -OutFile $inst
		$sig = Get-AuthenticodeSignature $inst
		if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') { Fail 'the Minecraft installer failed its signature check.' }
		Start-Process $inst
		Say 'Click Install in the Minecraft installer.'
	} else { Open-Launcher }
	Write-Host 'Sign in to the Minecraft Launcher with the Microsoft account that owns Minecraft Java.' -ForegroundColor Yellow
	Say 'Leave this window open: it continues by itself once you are signed in.'
	while (-not (Test-SignedIn)) { Start-Sleep 3 }
	Start-Sleep 5
}

# The launcher rewrites its profile file when it closes, so it must be closed while we edit it.
$launcher = Get-Process -Name 'MinecraftLauncher', 'Minecraft' -ErrorAction SilentlyContinue
if ($launcher) { Say 'Closing the Minecraft Launcher for a moment...'; $launcher | Stop-Process -Force; Start-Sleep 2 }

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

# Fabric version that also passes --quickPlayMultiplayer, so Play goes straight into the server.
$verDir = Join-Path $mc "versions\$VersionId"
New-Item -ItemType Directory -Force -Path $verDir | Out-Null
[IO.File]::WriteAllBytes((Join-Path $verDir "$VersionId.json"), [Convert]::FromBase64String($VersionJson))

$serversFile = Join-Path $game 'servers.dat'
if (-not (Test-Path $serversFile)) { [IO.File]::WriteAllBytes($serversFile, [Convert]::FromBase64String($ServersDat)) }
# Skip the first-start accessibility screen, which would stop the auto-join.
$options = Join-Path $game 'options.txt'
if (-not (Test-Path $options)) { [IO.File]::WriteAllText($options, "onboardAccessibility:false`nskipMultiplayerWarning:true`n", $utf8) }

$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
foreach ($f in @('launcher_profiles.json', 'launcher_profiles_microsoft_store.json') | ForEach-Object { Join-Path $mc $_ } | Where-Object { Test-Path $_ }) {
	$data = Get-Content -Raw -LiteralPath $f | ConvertFrom-Json
	if (-not $data.profiles) { $data | Add-Member -Force -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{}) }
	$p = [pscustomobject]@{
		name = 'Grisch'; type = 'custom'; icon = 'Grass'; created = $now; lastUsed = $now
		lastVersionId = $VersionId; gameDir = $game
	}
	$data.profiles | Add-Member -Force -NotePropertyName 'grisch' -NotePropertyValue $p
	[IO.File]::WriteAllText($f, ($data | ConvertTo-Json -Depth 32), $utf8)
}

Say ''
Write-Host 'Done! Press the green PLAY button in the Minecraft Launcher.' -ForegroundColor Green
Say "You join $Server automatically. Voice chat: V. Terminal: K."
Open-Launcher
Start-Sleep 20
