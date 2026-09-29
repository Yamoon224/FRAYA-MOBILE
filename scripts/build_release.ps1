<#
.SYNOPSIS
    Construit un APK release Fraya, verifie sa signature et publie son empreinte SHA-256.

.DESCRIPTION
    Rien dans la configuration Gradle ne lie le flavor (`--flavor passenger`) au point
    d'entree Dart (`-t lib/main_passenger.dart`) : ce sont deux flags independants. Les
    inverser produit silencieusement un APK "Fraya Chauffeur" qui execute le code passager.
    Ce script appaire les deux automatiquement.

    Il produit un APK par ABI (--split-per-abi) : ~28 Mo pour arm64-v8a au lieu de 73 Mo
    pour l'APK "fat", soit 2,5x moins d'occasions d'etre tronque au telechargement.

.PARAMETER Flavor
    passenger | driver | all

.PARAMETER Minify
    Active R8 (-Pminify=true). A ne faire qu'apres validation du parcours complet
    (push OneSignal, carte Maps, Crashlytics) : R8 peut casser au runtime sans casser
    la compilation.

.PARAMETER Universal
    Construit EN PLUS l'APK universel (toutes ABI), utile comme repli pour un appareil
    dont on ignore l'architecture.

.EXAMPLE
    .\scripts\build_release.ps1 -Flavor passenger
    .\scripts\build_release.ps1 -Flavor all -Universal
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('passenger', 'driver', 'all')]
    [string]$Flavor,

    [switch]$Minify,
    [switch]$Universal
)

$ErrorActionPreference = 'Stop'

# Racine du projet Flutter = dossier parent de scripts/
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ApkDir = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk'

# Appariement flavor <-> point d'entree Dart. Seule source de verite.
$Entrypoints = @{
    'passenger' = 'lib/main_passenger.dart'
    'driver'    = 'lib/main_driver.dart'
}

function Find-BuildTool {
    param([string]$Name)
    $sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT }
           elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME }
           else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    $dir = Join-Path $sdk 'build-tools'
    if (-not (Test-Path $dir)) { return $null }
    $latest = Get-ChildItem $dir -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latest) { return $null }
    $tool = Join-Path $latest.FullName $Name
    if (Test-Path $tool) { return $tool } else { return $null }
}

function Build-Flavor {
    param([string]$Name)

    $entry = $Entrypoints[$Name]
    Write-Host ''
    Write-Host "=== Build $Name ($entry) ===" -ForegroundColor Cyan

    # Supprimer les APK precedents de ce flavor. Sans cela, un ancien APK (potentiellement
    # signe en debug, ou d'une version anterieure) reste dans le dossier de sortie et peut
    # etre envoye au client par erreur -- exactement le scenario qu'on cherche a eviter.
    if (Test-Path $ApkDir) {
        Get-ChildItem $ApkDir -Filter "app-*$Name-release.apk*" | ForEach-Object {
            Write-Host "  suppression de l'APK precedent : $($_.Name)" -ForegroundColor DarkGray
            Remove-Item $_.FullName -Force
        }
    }

    # `flutter build` ne relaie pas les -P vers Gradle ; en revanche Gradle lit toute
    # variable d'environnement ORG_GRADLE_PROJECT_<nom> comme propriete de projet.
    if ($Minify) {
        Write-Host "R8 ACTIVE : valider push OneSignal + carte Maps + Crashlytics avant diffusion." -ForegroundColor Yellow
        $env:ORG_GRADLE_PROJECT_minify = 'true'
    }
    else {
        Remove-Item Env:\ORG_GRADLE_PROJECT_minify -ErrorAction SilentlyContinue
    }

    $buildArgs = @('build', 'apk', '--release', '--flavor', $Name, '-t', $entry, '--split-per-abi')

    Push-Location $ProjectRoot
    try {
        & flutter @buildArgs
        if ($LASTEXITCODE -ne 0) { throw "flutter build apk a echoue (code $LASTEXITCODE) pour le flavor $Name." }

        if ($Universal) {
            Write-Host "--- APK universel (repli) ---" -ForegroundColor DarkGray
            & flutter build apk --release --flavor $Name -t $entry
            if ($LASTEXITCODE -ne 0) { throw "Build de l'APK universel echoue pour $Name." }
        }
    }
    finally {
        Pop-Location
    }
}

function Report-Apk {
    param([System.IO.FileInfo]$Apk)

    $hash = (Get-FileHash $Apk.FullName -Algorithm SHA256).Hash.ToLower()
    $sizeMo = [math]::Round($Apk.Length / 1MB, 2)

    # Fiche a joindre a chaque envoi client : le SHA-256 est la seule preuve que le
    # fichier telecharge est bien celui qu'on a construit.
    $sidecar = "$($Apk.FullName).sha256"
    "$hash *$($Apk.Name)" | Set-Content -Path $sidecar -Encoding utf8

    Write-Host ''
    Write-Host $Apk.Name -ForegroundColor Green
    Write-Host "  Taille    : $($Apk.Length) octets ($sizeMo Mio)"
    Write-Host "  SHA-256   : $hash"

    $signer = Find-BuildTool 'apksigner.bat'
    if ($signer) {
        $out = & $signer verify --verbose --print-certs $Apk.FullName 2>&1 | Out-String
        $v1 = $out -match 'v1 scheme \(JAR signing\): true'
        $v2 = $out -match 'v2 scheme[^:]*: true'
        $v3 = $out -match 'v3 scheme[^:]*: true'
        $isDebugCert = $out -match 'CN=Android Debug'

        # v1 est volontairement absent : AGP le desactive des que minSdk >= 24, ou il est
        # redondant. Seuls v2 et v3 sont exiges ici.
        Write-Host "  Signature : v1=$v1 v2=$v2 v3=$v3"
        if ($isDebugCert) {
            Write-Host "  !! SIGNE AVEC LA CLE DE DEBUG -- NE PAS DISTRIBUER." -ForegroundColor Red
            Write-Host "     Creer android/key.properties (voir android/key.properties.example)." -ForegroundColor Red
        }
        elseif (-not ($v2 -and $v3)) {
            Write-Host "  !! Schemas de signature incomplets (v2/v3 attendus) -- APK potentiellement non installable." -ForegroundColor Red
        }
    }
    else {
        Write-Host "  (apksigner introuvable : verification de signature ignoree)" -ForegroundColor DarkYellow
    }

    $badging = Find-BuildTool 'aapt2.exe'
    if ($badging) {
        $info = & $badging dump badging $Apk.FullName 2>&1 | Select-String -Pattern "^package:|^native-code:"
        $info | ForEach-Object { Write-Host "  $_" }
    }
}

# --- Execution ---------------------------------------------------------------

if (-not (Test-Path (Join-Path $ProjectRoot 'android\key.properties'))) {
    Write-Host ''
    Write-Host "ATTENTION : android/key.properties est absent." -ForegroundColor Yellow
    Write-Host "L'APK sera signe avec la cle de DEBUG et ne doit pas etre distribue." -ForegroundColor Yellow
    Write-Host "Voir android/key.properties.example pour le creer." -ForegroundColor Yellow
}

$targets = if ($Flavor -eq 'all') { @('passenger', 'driver') } else { @($Flavor) }
foreach ($t in $targets) { Build-Flavor -Name $t }

Write-Host ''
Write-Host '=== APK produits ===' -ForegroundColor Cyan
foreach ($t in $targets) {
    Get-ChildItem $ApkDir -Filter "app-*$t-release.apk" |
        Sort-Object Name |
        ForEach-Object { Report-Apk -Apk $_ }
}

Write-Host ''
Write-Host 'A distribuer : app-arm64-v8a-<flavor>-release.apk (tous les smartphones depuis ~2017).' -ForegroundColor Cyan
Write-Host 'Joindre au lien : taille en octets + SHA-256 + version + consigne de desinstallation prealable.' -ForegroundColor Cyan
