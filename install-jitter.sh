#!/bin/bash

set -e

echo "===================================="
echo " JITTER VPS MANAGER INSTALLER"
echo "===================================="

[ "$EUID" -ne 0 ] && {
echo "Ejecute como root"
exit 1
}

apt-get update -y

apt-get install -y 
curl 
wget 
git 
nano 
vim 
htop 
tmux 
screen 
vnstat 
net-tools 
sudo

mkdir -p /opt/jitter-manager
mkdir -p /opt/jitter-manager/modules

echo "Dependencias instaladas."

cat > /usr/local/bin/jitter-manager << 'EOF'
#!/bin/bash
bash /opt/jitter-manager/panel.sh
EOF

chmod +x /usr/local/bin/jitter-manager

echo
echo "Instalación completada."
echo
echo "Comando:"
echo "jitter-manager"
