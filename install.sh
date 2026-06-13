#!/bin/bash
set -e
[ "$EUID" -ne 0 ] && { echo "Ejecute como root"; exit 1; }

apt-get update -y
apt-get install -y curl wget git nano vim htop tmux screen vnstat net-tools sudo

mkdir -p /opt/jitter-manager/modules

cp panel.sh /opt/jitter-manager/panel.sh
cp menu.sh /opt/jitter-manager/menu.sh
cp modules/* /opt/jitter-manager/modules/ 2>/dev/null || true

chmod +x /opt/jitter-manager/panel.sh
chmod +x /opt/jitter-manager/menu.sh
chmod +x /opt/jitter-manager/modules/* 2>/dev/null || true

cat > /usr/local/bin/jitter-manager << 'EOF'
#!/bin/bash
bash /opt/jitter-manager/panel.sh
EOF

chmod +x /usr/local/bin/jitter-manager
echo "Instalado. Ejecuta: jitter-manager"
