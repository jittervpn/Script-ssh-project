#!/bin/bash

# Colores
CIAN='\033[1;36m'
VERDE='\033[1;32m'
ROJO='\033[1;31m'
AMARILLO='\033[1;33m'
AZUL='\033[1;34m'
NC='\033[0m'

# --------------------------
# Instalar paquetes
# --------------------------
instalar_paquetes() {
    echo -e "${AZUL}🔧 Instalando paquetes necesarios...${NC}"
    apt update -y
    apt install -y openssh-server net-tools curl wget iptables ufw libpam-time-guard
    systemctl enable --now ssh
    ufw enable -y
    ufw allow 22/tcp
    ufw reload
    echo -e "${VERDE}✅ Paquetes instalados correctamente${NC}"
}

# --------------------------
# Cambiar puerto SSH
# --------------------------
configurar_puerto() {
    read -p "$(echo -e "${CIAN}🔌 Nuevo puerto SSH (1-65535): ${NC}")" puerto
    if ! [[ "$puerto" =~ ^[0-9]+$ ]] || [ "$puerto" -lt 1 ] || [ "$puerto" -gt 65535 ]; then
        echo -e "${ROJO}❌ Puerto inválido${NC}"
        return
    fi

    # Eliminar configuraciones anteriores
    sed -i '/^Port /d' /etc/ssh/sshd_config
    echo "Port $puerto" >> /etc/ssh/sshd_config

    # Firewall
    ufw allow "$puerto"/tcp
    ufw delete allow 22/tcp 2>/dev/null
    ufw reload

    systemctl restart ssh
    echo -e "${VERDE}✅ Puerto cambiado a: $puerto${NC}"
}

# --------------------------
# Crear usuario completo
# --------------------------
crear_usuario() {
    read -p "$(echo -e "${CIAN}👤 Nombre de usuario: ${NC}")" usuario
    if id "$usuario" &>/dev/null; then
        echo -e "${AMARILLO}⚠️ El usuario $usuario ya existe${NC}"
        return
    fi

    read -s -p "$(echo -e "${CIAN}🔑 Contraseña: ${NC}")" contrasena
    echo
    read -p "$(echo -e "${CIAN}📅 Días de vencimiento (0 = sin límite): ${NC}")" dias
    read -p "$(echo -e "${CIAN}🔢 Límite de conexiones simultáneas: ${NC}")" limite_conexiones
    read -p "$(echo -e "${CIAN}⏰ Hora inicio permitido (ej: 08): ${NC}")" hora_inicio
    read -p "$(echo -e "${CIAN}⏰ Hora fin permitido (ej: 22): ${NC}")" hora_fin

    # Crear usuario
    useradd -m -s /bin/bash "$usuario"
    echo "$usuario:$contrasena" | chpasswd

    # Vencimiento
    if [ "$dias" -gt 0 ]; then
        chage -E "$(date -d "+$dias days" +%Y-%m-%d)" "$usuario"
    else
        chage -E -1 "$usuario"
    fi

    # Límite de conexiones
    echo -e "\n# Límite de conexiones para $usuario" >> /etc/security/limits.conf
    echo "$usuario hard maxlogins $limite_conexiones" >> /etc/security/limits.conf

    # Restricción por horario
    echo -e "\n# Restricción horaria para $usuario" >> /etc/pam.d/sshd
    echo "account    required    pam_time.so" >> /etc/pam.d/sshd
    echo "* ; * ; $usuario ; Al0000-$hora_inicio00, $hora_fin00-2400" >> /etc/security/time.conf

    echo -e "${VERDE}✅ Usuario $usuario creado con todas las configuraciones${NC}"
}

# --------------------------
# Ver usuarios
# --------------------------
ver_usuarios() {
    echo -e "${AZUL}📋 Usuarios con acceso SSH:${NC}"
    awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh)/ {printf "👤 %s\n", $1}' /etc/passwd
}

# --------------------------
# Eliminar usuario
# --------------------------
eliminar_usuario() {
    read -p "$(echo -e "${ROJO}❌ Usuario a eliminar: ${NC}")" usuario
    if id "$usuario" &>/dev/null; then
        userdel -r "$usuario"
        # Limpiar configuraciones
        sed -i "/$usuario/d" /etc/security/limits.conf
        sed -i "/$usuario/d" /etc/pam.d/sshd
        sed -i "/$usuario/d" /etc/security/time.conf
        echo -e "${VERDE}✅ Usuario $usuario eliminado completamente${NC}"
    else
        echo -e "${AMARILLO}⚠️ No existe el usuario${NC}"
    fi
}
