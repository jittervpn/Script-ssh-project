#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta el instalador como root: sudo bash install.sh" >&2
  exit 1
fi

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/jitter-vpn"

if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y openssh-server
elif command -v yum >/dev/null 2>&1; then
  yum install -y openssh-server
else
  echo "Gestor de paquetes no compatible. Instala OpenSSH manualmente." >&2
  exit 1
fi

install -d -m 0755 "$INSTALL_DIR/lib"
install -m 0755 "$SOURCE_DIR/jitter-vpn.sh" "$INSTALL_DIR/jitter-vpn.sh"
install -m 0644 "$SOURCE_DIR/lib/ui.sh" "$INSTALL_DIR/lib/ui.sh"
ln -sfn "$INSTALL_DIR/jitter-vpn.sh" /usr/local/bin/jitter-vpn

SSH_SERVICE="sshd"
systemctl list-unit-files ssh.service >/dev/null 2>&1 && SSH_SERVICE="ssh"
systemctl enable --now "$SSH_SERVICE"

echo "Jitter VPN instalado correctamente. Ejecuta: sudo jitter-vpn"