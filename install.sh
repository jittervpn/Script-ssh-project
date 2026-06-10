#!/bin/bash

[[ $EUID -ne 0 ]] && echo "Ejecutar como root: sudo bash install.sh" && exit 1

clear
echo "======================================"
echo " JITTER SSH MANAGER v2.0 - Ubuntu 24"
echo "======================================"

echo "[1/8] Instalando dependencias..."
apt update
apt install wget python3 ufw dropbear -y

echo "[2/8] Descargando menu..."
REPO_RAW="https://raw.githubusercontent.com/jittervpn/Script-ssh-project/main"
curl -fsSL "$REPO_RAW/menu.sh" -o /usr/bin/menu
chmod +x /usr/bin/menu

echo "[3/8] Configurando OpenSSH para HTTP Custom..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

if! grep -q "diffie-hellman-group1-sha1" /etc/ssh/sshd_config; then
cat >> /etc/ssh/sshd_config << 'EOF'

# HTTP Custom Compat
KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group1-sha1
Ciphers +aes128-cbc,3des-cbc,aes256-cbc
MACs +hmac-sha1,hmac-md5
EOF
fi

systemctl restart ssh

echo "[4/8] Instalando WebSocket en puerto 80..."
wget -O /usr/bin/ws.py https://raw.githubusercontent.com/sshwsock/ws-ssh/main/ws.py
chmod +x /usr/bin/ws.py

cat > /etc/systemd/system/ws-http.service << 'EOF'
[Unit]
Description=WebSocket HTTP
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/bin/ws.py 80
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-http
systemctl start ws-http

echo "[5/8] Instalando BadVPN UDP 7300..."
wget -O /usr/bin/badvpn-udpgw https://github.com/ambrop72/badvpn/releases/download/1.999.130/badvpn-1.999.130-linux-x86_64
chmod +x /usr/bin/badvpn-udpgw

cat > /etc/systemd/system/badvpn.service << 'EOF'
[Unit]
Description=BadVPN UDPGW
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000
Restart=always
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn
systemctl start badvpn

echo "[6/8] Configurando Banner SSH..."
cat > /etc/ssh/banner_jitter << 'EOF'

   JITTER VPN - CONECTADO

EOF

sed -i '/^Banner/d' /etc/ssh/sshd_config
echo "Banner /etc/ssh/banner_jitter" >> /etc/ssh/sshd_config
systemctl restart ssh

echo "[7/8] Instalando Dropbear puerto 444..."
sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=444/' /etc/default/dropbear
echo 'DROPBEAR_EXTRA_ARGS="-p 444"' >> /etc/default/dropbear
systemctl restart dropbear
systemctl enable dropbear

echo "[8/8] Configurando Firewall..."
ufw allow 22
ufw allow 80
ufw allow 444
ufw allow 7300
echo "y" | ufw enable

echo "======================================"
echo "Instalación completa!"
echo "SSH: 22 | Dropbear: 444 | WS: 80 | UDP: 7300"
echo "Ejecutá: sudo menu"
echo "======================================"
