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

# Descargar menu.sh y dejarlo como comando "menu"
curl -fsSL "$REPO_RAW/menu.sh" -o /usr/local/bin/menu || {
  echo "❌ Error al descargar menu.sh"
  exit 1
}

# Corregir finales de línea por si fue editado en Windows
sed -i 's/\r$//' /usr/local/bin/menu

# Permisos de ejecución
chmod +x /usr/local/bin/menu

echo ""
echo "✅ Instalación completada"
echo "👉 Escribí: menu"
