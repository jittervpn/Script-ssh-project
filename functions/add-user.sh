#!/bin/bash

read -p "Usuario: " user
read -p "Contraseña: " pass
read -p "Días: " days

useradd -M -s /bin/false $user
echo "$user:$pass" | chpasswd

expire=$(date -d "+$days days" +"%Y-%m-%d")
chage -E $expire $user

echo ""
echo "Usuario creado correctamente"
echo "Usuario: $user"
echo "Expira: $expire"

read
