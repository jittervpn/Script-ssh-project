#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Ejecutá como root: sudo bash install.sh${NC}"
  exit 1
fi

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}   JITTER SSH MANAGER v2.0 - Ubuntu 24${NC}"
echo -e "${BLUE}========================================${NC}"

# 1. Dependencias
echo -e "${YELLOW}[1/8] Instalando dependencias...${NC}"
apt update -y > /dev/null 2>&1
apt install wget curl python3 ufw dropbear badvpn net-tools dos2unix -y > /dev/null 2>&1

# 2. Descargar Menu
echo -e "${YELLOW}[2/8] Descargando menu...${NC}"
REPO_RAW="https://raw.githubusercontent.com/jittervpn/Script-ssh-project/main"
curl -fsSL "$REPO_RAW/menu.sh" -o /usr/bin/menu
chmod +x /usr/bin/menu

# 3. Configurar SSH Legacy para HTTP Custom/Injector
echo -e "${YELLOW}[3/8] Configurando OpenSSH para HTTP Custom...${NC}"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Eliminar config vieja si existe
sed -i '/# HTTP Custom Compat/,/^$/d' /etc/ssh/sshd_config

cat >> /etc/ssh/sshd_config << 'EOF'

# HTTP Custom Compat - JitterVPN
KexAlgorithms +diffie-hellman-group14-sha1,diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha1
Ciphers +aes128-cbc,3des-cbc,aes256-cbc,aes192-cbc
MACs +hmac-sha1,hmac-md5,hmac-sha1-96,hmac-md5-96
HostKeyAlgorithms +ssh-rsa,ssh-dss
PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss
EOF

systemctl restart sshd

# 4. WebSocket Python
echo -e "${YELLOW}[4/8] Instalando WebSocket en puerto 80...${NC}"
wget -q -O /usr/bin/ws.py https://raw.githubusercontent.com/sshwsock/ws-ssh/main/ws.py
chmod +x /usr/bin/ws.py

cat > /etc/systemd/system/ws-http.service << 'EOF'
[Unit]
Description=WebSocket HTTP Jitter
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/bin/ws.py 80
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ws-http > /dev/null 2>&1
systemctl start ws-http

# 5. BadVPN UDP para juegos/llamadas
echo -e "${YELLOW}[5/8] Instalando BadVPN UDP 7300...${NC}"
cat > /etc/systemd/system/badvpn.service << 'EOF'
[Unit]
Description=BadVPN UDPGW
After=network.target
[Service]
Type=forking
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000
Restart=always
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable badvpn > /dev/null 2>&1
systemctl start badvpn

# 6. Banner SSH
echo -e "${YELLOW}[6/8] Configurando Banner SSH...${NC}"
cat > /etc/ssh/banner_jitter << 'EOF'

       JITTER VPN - CONEXION SSH

 Prohibido: Torrent, Spam, DDoS
 Soporte: @jittervpn

EOF

sed -i 's|#Banner none|Banner /etc/ssh/banner_jitter|' /etc/ssh/sshd_config
grep -q "Banner /etc/ssh/banner_jitter" /etc/ssh/sshd_config || echo "Banner /etc/ssh/banner_jitter" >> /etc/ssh/sshd_config
systemctl restart sshd

# 7. Dropbear puerto 444 para backup
echo -e "${YELLOW}[7/8] Instalando Dropbear puerto 444...${NC}"
sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=444/' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 444"/' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
systemctl enable dropbear > /dev/null 2>&1
systemctl restart dropbear

# 8. Firewall + Anti-Torrent
echo -e "${YELLOW}[8/8] Configurando Firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 444/tcp
ufw allow 7300/udp

# Bloquear torrent
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "ann
