#!/bin/bash
echo "1) Sistema"
echo "2) Usuarios"
echo "3) Red"
echo "4) Servicios"
echo "5) Backup"
echo "0) Salir"
read -p "Opcion: " op
case $op in
1) bash /opt/jitter-manager/modules/system.sh ;;
2) bash /opt/jitter-manager/modules/users.sh ;;
3) bash /opt/jitter-manager/modules/network.sh ;;
4) bash /opt/jitter-manager/modules/services.sh ;;
5) bash /opt/jitter-manager/modules/backup.sh ;;
0) exit ;;
esac
