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
cat >> /etc/ssh/sshd_config << 'EOF'
KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group1-sha1
Ciphers +aes128-cbc,3des-cbc,aes256-cbc
MACs +hmac-sha1,hmac-md5
EOF
systemctl restart sshd
sed -i 's/\r$//' /usr/local/bin/menu
chmod +x /usr/local/bin/menu
}
echo ""
echo "✅ Instalación completada"
echo "👉 Escribí: menu"
