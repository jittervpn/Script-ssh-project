#!/bin/bash

============================================
JITTER SERVER MANAGER v1.0
============================================

R="\033[1;31m"
V="\033[1;32m"
A="\033[1;33m"
AZ="\033[1;34m"
C="\033[1;36m"
B="\033[1;37m"
N="\033[0m"

[[ $EUID -ne 0 ]] && {
echo -e "${R}Ejecute como root${N}"
exit 1
}

pausa() {
echo
read -p "Presione ENTER para continuar..."
}

dashboard() {

RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
RAM_USADA=$(free -h | awk '/Mem:/ {print $3}')

DISCO_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISCO_USADO=$(df -h / | awk 'NR==2 {print $3}')

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}')

UPTIME=$(uptime -p)

IP=$(hostname -I | awk '{print $1}')

clear

echo -e "${AZ}"
echo "╔══════════════════════════════════════╗"
echo "║       JITTER SERVER MANAGER         ║"
echo "╚══════════════════════════════════════╝"
echo -e "${N}"

echo -e "${B}IP:${N} $IP"
echo -e "${B}CPU:${N} ${CPU}%"
echo -e "${B}RAM:${N} $RAM_USADA / $RAM_TOTAL"
echo -e "${B}DISCO:${N} $DISCO_USADO / $DISCO_TOTAL"
echo -e "${B}UPTIME:${N} $UPTIME"

echo

}

listar_usuarios() {
clear
echo "===== USUARIOS ====="
awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd
pausa
}

crear_usuario() {
clear

read -p "Usuario: " user

if id "$user" &>/dev/null; then
    echo "Usuario existente"
    pausa
    return
fi

useradd -m "$user"

passwd "$user"

echo "Usuario creado"

pausa

}

eliminar_usuario() {
clear

read -p "Usuario: " user

if id "$user" &>/dev/null; then
    userdel -r "$user"
    echo "Eliminado"
else
    echo "No existe"
fi

pausa

}

info_sistema() {
clear

echo "===== SISTEMA ====="
hostnamectl

echo
echo "===== MEMORIA ====="
free -h

echo
echo "===== DISCO ====="
df -h

pausa

}

procesos() {
clear
htop
}

servicios() {
clear

echo "===== SERVICIOS ====="

systemctl --type=service --state=running

pausa

}

reiniciar_servicio() {
clear

read -p "Servicio: " srv

systemctl restart "$srv"

systemctl status "$srv" --no-pager

pausa

}

backup() {

mkdir -p /root/backups

FILE="/root/backups/backup-$(date +%F-%H%M).tar.gz"

tar -czf "$FILE" /home 2>/dev/null

echo
echo "Backup creado:"
echo "$FILE"

pausa

}

logs() {
clear
journalctl -n 100 --no-pager
pausa
}

red() {
clear

echo "===== RED ====="

ss -tulnp

pausa

}

actualizar() {

apt update
apt upgrade -y

pausa

}

while true
do

dashboard

echo -e "${V}1)${N} Usuarios"
echo -e "${V}2)${N} Crear usuario"
echo -e "${V}3)${N} Eliminar usuario"

echo
echo -e "${C}4)${N} Información sistema"
echo -e "${C}5)${N} Procesos (htop)"
echo -e "${C}6)${N} Servicios activos"
echo -e "${C}7)${N} Reiniciar servicio"

echo
echo -e "${A}8)${N} Backup"
echo -e "${A}9)${N} Logs"
echo -e "${A}10)${N} Red"
echo -e "${A}11)${N} Actualizar sistema"

echo
echo -e "${R}0)${N} Salir"
echo

read -p "Seleccione: " op

case $op in

listar_usuarios ;;
crear_usuario ;;
eliminar_usuario ;;
info_sistema ;;
procesos ;;
servicios ;;
reiniciar_servicio ;;
backup ;;
logs ;;
red ;;
actualizar ;;
clear; exit ;;
*) echo "Opción inválida"; sleep 1 ;;
esac

done