#!/bin/bash

while true; do
clear

```
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
echo "=================================="
echo
echo "1) Información del sistema"
echo "2) Usuarios locales"
echo "3) Servicios activos"
echo "4) Conexiones de red"
echo "5) Actualizar sistema"
echo
echo "0) Salir"
echo

read -p "Seleccione una opción: " op

case $op in
    1)
        clear
        hostnamectl
        echo
        free -h
        echo
        df -h
        read -p "ENTER para continuar..."
        ;;
    2)
        clear
        awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd
        echo
        read -p "ENTER para continuar..."
        ;;
    3)
        clear
        systemctl --type=service --state=running
        read -p "ENTER para continuar..."
        ;;
    4)
        clear
        ss -tulnp
        read -p "ENTER para continuar..."
        ;;
    5)
        apt update && apt upgrade -y
        read -p "ENTER para continuar..."
        ;;
    0)
        exit
        ;;
    *)
        echo "Opción inválida"
        sleep 1
        ;;
esac
```

done
