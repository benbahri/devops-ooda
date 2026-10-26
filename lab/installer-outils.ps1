<#
.SYNOPSIS
  Installe les outils de la formation OODA sur Windows 10/11 : Git, JDK 21, Maven, Docker Desktop
  (backend WSL2), kubectl, kind et VS Code.
.DESCRIPTION
  Utilise winget (inclus dans Windows 11 et Windows 10 recent). Idempotent : ne reinstalle pas
  ce qui est deja present. A lancer dans PowerShell, de preference "Executer en tant
  qu'administrateur" (necessaire pour WSL2 et Docker Desktop).
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\installer-outils.ps1 -DryRun
  powershell -ExecutionPolicy Bypass -File .\installer-outils.ps1
#>
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
$MavenVersion = "3.9.9"
$KindVersion  = "v0.24.0"

function Log($m)  { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "  [OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Run([scriptblock]$b, [string]$desc) {
    if ($DryRun) { Write-Host "  (dry-run) $desc" } else { & $b }
}
function Have($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
}
function Winget-Install($id, $label) {
    Log $label
    Run { winget install --id $id -e --accept-package-agreements --accept-source-agreements --silent } "winget install $id"
}

# --- Pre-requis -------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $DryRun) { Warn "Non administrateur : l'installation de WSL2 / Docker Desktop peut echouer. Relancez PowerShell en administrateur." }
if (-not (Have winget)) { Warn "winget introuvable. Installez 'App Installer' depuis le Microsoft Store, puis relancez."; exit 1 }

# --- WSL2 (backend de Docker Desktop) ---------------------------------------
Log "WSL2"
$wslOk = $false
# cmd /c : evite qu'un message ecrit sur stderr devienne une erreur fatale (ErrorActionPreference=Stop)
cmd /c "wsl --status >nul 2>&1"
$wslOk = ($LASTEXITCODE -eq 0)
if ($wslOk) { Ok "WSL2 present" }
else {
    Run { wsl --install --no-distribution } "wsl --install --no-distribution"
    Warn "WSL2 vient d'etre installe : un REDEMARRAGE de Windows sera necessaire avant de lancer Docker Desktop."
}

# --- Git (fournit aussi Git Bash, utile pour les scripts .sh du lab) --------
if (Have git) { Ok "git" } else { Winget-Install "Git.Git" "Git" }

# --- JDK 21 ------------------------------------------------------------------
$javaOk = $false
# java -version ecrit sur stderr : on passe par cmd /c pour ne pas declencher une erreur PowerShell
if (Have java) { $v = (cmd /c "java -version 2>&1" | Out-String); $javaOk = ($v -match '"(2[1-9]|[3-9][0-9])[."]') }
if ($javaOk) { Ok "JDK 21+" } else { Winget-Install "EclipseAdoptium.Temurin.21.JDK" "JDK 21 (Temurin)" }

# --- Maven (telechargement direct : pas de dependance a un identifiant winget) ---
if (Have mvn) { Ok "maven" }
else {
    Log "Maven $MavenVersion"
    $root = Join-Path $env:USERPROFILE "tools"
    $dest = Join-Path $root "apache-maven-$MavenVersion"
    Run {
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        $zip = Join-Path $env:TEMP "maven.zip"
        Invoke-WebRequest "https://archive.apache.org/dist/maven/maven-3/$MavenVersion/binaries/apache-maven-$MavenVersion-bin.zip" -OutFile $zip
        Expand-Archive $zip -DestinationPath $root -Force
        $bin = Join-Path $dest "bin"
        [Environment]::SetEnvironmentVariable("MAVEN_HOME", $dest, "User")
        $userPath = [Environment]::GetEnvironmentVariable("Path","User")
        if ($userPath -notlike "*$bin*") { [Environment]::SetEnvironmentVariable("Path", "$userPath;$bin", "User") }
    } "telecharger et decompresser Maven dans $dest, ajouter au PATH utilisateur"
}

# --- kubectl -----------------------------------------------------------------
if (Have kubectl) { Ok "kubectl" } else { Winget-Install "Kubernetes.kubectl" "kubectl" }

# --- kind (winget, sinon binaire officiel) -----------------------------------
if (Have kind) { Ok "kind" }
else {
    Log "kind"
    Run {
        winget install --id Kubernetes.kind -e --accept-package-agreements --accept-source-agreements --silent
        if ($LASTEXITCODE -ne 0) {
            $bin = Join-Path $env:USERPROFILE "tools\bin"
            New-Item -ItemType Directory -Force -Path $bin | Out-Null
            Invoke-WebRequest "https://kind.sigs.k8s.io/dl/$KindVersion/kind-windows-amd64" -OutFile (Join-Path $bin "kind.exe")
            $userPath = [Environment]::GetEnvironmentVariable("Path","User")
            if ($userPath -notlike "*$bin*") { [Environment]::SetEnvironmentVariable("Path", "$userPath;$bin", "User") }
        }
    } "winget install Kubernetes.kind (repli : binaire kind-windows-amd64)"
}

# --- VS Code + extensions --------------------------------------------------------
if ((Have code) -or (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") -or (Test-Path "$env:ProgramFiles\Microsoft VS Code\Code.exe")) { Ok "VS Code" }
else { Winget-Install "Microsoft.VisualStudioCode" "VS Code"; if (-not $DryRun) { Refresh-Path } }
$extensions = "vscjava.vscode-java-pack","redhat.vscode-yaml","ms-azuretools.vscode-docker","ms-kubernetes-tools.vscode-kubernetes-tools","ms-vscode-remote.remote-wsl"
if (Have code) {
    Log "Extensions VS Code"
    foreach ($e in $extensions) { Run { cmd /c "code --install-extension $e --force >nul 2>&1" } "code --install-extension $e" }
} else { Warn "Commande 'code' introuvable dans cette fenetre : rouvrez PowerShell puis relancez le script pour installer les extensions." }

# --- Docker Desktop ------------------------------------------------------------
if (Have docker) { Ok "docker" }
else {
    Winget-Install "Docker.DockerDesktop" "Docker Desktop"
    Warn "Apres redemarrage : lancez Docker Desktop, acceptez les conditions, puis"
    Warn "Settings > Resources : memoire 10 Go ; Settings > General : 'Use the WSL 2 based engine' coche."
}

if (-not $DryRun) { Refresh-Path }

Log "Termine"
Write-Host @"

Etapes suivantes :
  1. Redemarrez Windows si WSL2 ou Docker Desktop vient d'etre installe.
  2. Lancez Docker Desktop et attendez l'icone 'Engine running'.
  3. Ouvrez *Git Bash* (installe avec Git) dans le dossier de la formation, puis :
       bash 05-stagiaire/verifier-poste.sh
     Les scripts .sh du lab (kind-setup.sh...) se lancent depuis Git Bash.
"@
