#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Ejecutá como root: sudo bash install.sh"
  exit 1
fi

clear
echo "================================="
echo "     JITTER SSH MANAGER"
echo "================================="
echo "Instalando..."

REPO_RAW="https://raw.githubusercontent.com/jittervpn/Script-ssh-project/main"

curl -fsSL "$REPO_RAW/menu.sh" -o /usr/local/bin/menu || {
  echo "❌ Error al descargar menu.sh"
  exit 1
}

sed -i 's/\r$//' /usr/local/bin/menu
chmod +x /usr/local/bin/menu

echo ""
echo "✅ Instalación completada"
echo "👉 Escribí: menu"
