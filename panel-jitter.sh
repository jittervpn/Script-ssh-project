#!/bin/bash

while true
do

clear

IP=$(hostname -I | awk '{print $1}')
RAM=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2}')
UPTIME=$(uptime -p)

echo "=================================="
echo "     JITTER VPS MANAGER"
echo "=================================="

echo "IP      : $IP"
echo "RAM     : $RAM"
echo "DISCO   : $DISK"
echo "UPTIME  : $UPTIME"

echo
echo "1) Usuarios"
echo "2) Sistema"
echo "3) Red"
echo "4) Servicios"
echo "5) Backup"
echo
echo "0) Salir"

read -p "Seleccione: " op

case $op in

1. bash /opt/jitter-manager/modules/users.sh ;;
2. bash /opt/jitter-manager/modules/system.sh ;;
3. bash /opt/jitter-manager/modules/network.sh ;;
4. bash /opt/jitter-manager/modules/services.sh ;;
5. bash /opt/jitter-manager/modules/backup.sh ;;
6. exit ;;
   esac

done
