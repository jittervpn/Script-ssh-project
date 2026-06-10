#!/bin/bash

while true
do
clear

echo "==============================="
echo "      JITTER SSH MANAGER"
echo "==============================="
echo ""
echo "1) Crear Usuario"
echo "2) Eliminar Usuario"
echo "3) Ver Usuarios"
echo "0) Salir"
echo ""

read -p "Seleccione una opción: " op

case $op in

1)
echo "Crear usuario"
read
;;

2)
echo "Eliminar usuario"
read
;;

3)
cut -d: -f1 /etc/passwd
read
;;

0)
exit
;;

esac

done
