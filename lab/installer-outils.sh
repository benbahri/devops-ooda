#!/usr/bin/env bash
# Installe les outils de la formation OODA : git, JDK 21, Maven, Docker (+ Compose), kubectl, kind, VS Code.
# Supporte : macOS (Homebrew) et Debian/Ubuntu (y compris WSL2). Idempotent : ne reinstalle pas
# ce qui est deja present. Usage :  bash installer-outils.sh        (--dry-run pour simuler)
set -euo pipefail

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
KUBECTL_VERSION="v1.31.0"
KIND_VERSION="v0.24.0"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '  [OK] %s\n' "$*"; }
warn() { printf '  [!!] %s\n' "$*" >&2; }
run()  { if [ "$DRY" -eq 1 ]; then echo "  (dry-run) $*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  x86_64|amd64)  ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) warn "Architecture non geree : $ARCH_RAW"; exit 1 ;;
esac

java_ok() { have java && java -version 2>&1 | grep -Eq '"(2[1-9]|[3-9][0-9])[."]'; }


EXTENSIONS="vscjava.vscode-java-pack redhat.vscode-yaml ms-azuretools.vscode-docker ms-kubernetes-tools.vscode-kubernetes-tools"
vscode_extensions() {
  have code || { warn "Commande 'code' introuvable : dans VS Code, Ctrl/Cmd+Maj+P > 'Shell Command: Install code command in PATH', puis relancez."; return 0; }
  for e in $EXTENSIONS; do run code --install-extension "$e" --force; done
}

install_macos() {
  have brew || { warn "Homebrew est requis : https://brew.sh puis relancez ce script."; exit 1; }
  git --version >/dev/null 2>&1 && ok "git" || { log "git"; run brew install git; }
  java_ok    && ok "JDK 21+" || { log "JDK 21"; run brew install --cask temurin@21; }
  have mvn   && ok "maven" || { log "Maven";  run brew install maven; }
  have kubectl && ok "kubectl" || { log "kubectl"; run brew install kubectl; }
  have kind  && ok "kind"  || { log "kind";   run brew install kind; }
  if have code || [ -d "/Applications/Visual Studio Code.app" ]; then ok "VS Code"; else
    log "VS Code"; run brew install --cask visual-studio-code
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
  fi
  vscode_extensions
  if have docker; then ok "docker"; else
    log "Docker Desktop"; run brew install --cask docker
    warn "Lancez Docker Desktop une premiere fois (Applications), acceptez les conditions,"
    warn "puis Settings > Resources : allouez 10 Go de memoire."
  fi
}

install_debian() {
  SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
  log "Mise a jour des paquets"; run $SUDO apt-get update -y
  git --version >/dev/null 2>&1 && ok "git" || { log "git"; run $SUDO apt-get install -y git curl ca-certificates; }
  have curl  || run $SUDO apt-get install -y curl ca-certificates
  if java_ok; then ok "JDK 21+"; else
    log "JDK 21"; run $SUDO apt-get install -y openjdk-21-jdk || \
      warn "openjdk-21 indisponible sur cette distribution : installez Temurin 21 (https://adoptium.net)."
  fi
  have mvn   && ok "maven" || { log "Maven"; run $SUDO apt-get install -y maven; }
  if have docker; then ok "docker"; else
    log "Docker Engine + Compose (script officiel get.docker.com)"
    run bash -c 'curl -fsSL https://get.docker.com | '"${SUDO:-}"' sh'
    run $SUDO usermod -aG docker "${SUDO_USER:-$USER}"
    warn "Deconnectez-vous puis reconnectez-vous pour que le groupe 'docker' soit pris en compte."
    warn "Sous WSL2 : preferez Docker Desktop cote Windows avec l'integration WSL activee."
  fi
  if have kubectl; then ok "kubectl"; else
    log "kubectl ${KUBECTL_VERSION}"
    run curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
    run $SUDO install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  fi
  if have kind; then ok "kind"; else
    log "kind ${KIND_VERSION}"
    run curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
    run $SUDO install -m 0755 /tmp/kind /usr/local/bin/kind
  fi
  if grep -qi microsoft /proc/version 2>/dev/null; then
    warn "WSL2 : installez VS Code cote Windows (installer-outils.ps1) ; l'extension 'WSL' s'y ajoute automatiquement."
  elif have code; then ok "VS Code"; vscode_extensions
  else
    log "VS Code (paquet .deb officiel)"
    VSARCH=x64; [ "$ARCH" = "arm64" ] && VSARCH=arm64
    run curl -fsSLo /tmp/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-${VSARCH}"
    run $SUDO apt-get install -y /tmp/vscode.deb
    vscode_extensions
  fi
}

log "Systeme detecte : $OS / $ARCH"
case "$OS" in
  Darwin) install_macos ;;
  Linux)
    if [ -f /etc/debian_version ]; then install_debian
    else warn "Distribution non geree automatiquement. Installez a la main : git, JDK 21, Maven, Docker, kubectl, kind (voir guide-installation.md)."; exit 1; fi ;;
  *) warn "Sous Windows : lancez installer-outils.ps1 dans PowerShell (voir guide-installation.md), ou ce script dans un terminal WSL2 (Ubuntu)."; exit 1 ;;
esac

log "Termine. Verification :"
bash "$(dirname "$0")/verifier-poste.sh" || warn "Certains controles sont KO : corrigez-les (Docker non demarre ? shell non relance ?)."
