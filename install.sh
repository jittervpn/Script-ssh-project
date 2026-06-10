#!/bin/bash
# =============================================================================
# Nombre: JITTERX VPS MANAGER
# Descripción: Herramienta profesional para administración de servidores
# Estilo: Termux / La Casita MX / Chumogh
# Autor: jitterx
# Repositorio: https://github.com/jitterx
# Versión: 2.0
# Licencia: MIT
# =============================================================================

# ╔══════════════════════════════════════════════════════════╗
# ║            ESTILO VISUAL TERMUX - COLORES Y FUENTES      ║
# ╚══════════════════════════════════════════════════════════╝

# Colores exactos al estilo Termux
NEGRO='\033[1;30m'
ROJO_TERMUX='\033[1;31m'
VERDE_TERMUX='\033[1;32m'
AMARILLO_TERMUX='\033[1;33m'
AZUL_TERMUX='\033[1;34m'
MORADO_TERMUX='\033[1;35m'
CIAN_TERMUX='\033[1;36m'
BLANCO_TERMUX='\033[1;37m'
VERDE_OSCURO='\033[0;32m'
NC='\033[0m' # Reset de color

# Fuente estilo Termux (caracteres especiales)
ARRIBA="↑"
ABAJO="↓"
IZQUIERDA="←"
DERECHA="→"
ESTRELLA="★"
CUADRADO="■"
LINEA="═"
ESQUINA_SUP_DER="╗"
ESQUINA_SUP_IZQ="╔"
ESQUINA_INF_DER="╝"
ESQUINA_INF_IZQ="╚"
LINEA_VERT="║"

# ╔══════════════════════════════════════════════════════════╗
# ║                  VERIFICACIÓN DE PERMISOS                 ║
# ╚══════════════════════════════════════════════════════════╝

if [ "$(id -u)" != "0" ]; then
   echo -e "${ROJO_TERMUX}${ESTRELLA} ERROR: Este script debe ejecutarse como root ${ESTRELLA}${NC}"
   exit 1
fi

# ╔══════════════════════════════════════════════════════════╗
# ║                   BANNER PRINCIPAL JITTERX                ║
# ╚══════════════════════════════════════════════════════════╝

banner_jitterx() {
    clear
    echo -e "${VERDE_TERMUX}"
    echo -e "${ESQUINA_SUP_IZQ}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${ESQUINA_SUP_DER}"
    echo -e "${LINEA_VERT}        ${AMARILLO_TERMUX}▀▀█▀▀ █▀▀█ █▀▀▄ █▀▀▀ █▀▀█         ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${LINEA_VERT}        ${AMARILLO_TERMUX}  █   █  █ █  █ █ ▀█ █▄▄█         ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${LINEA_VERT}        ${AMARILLO_TERMUX}  █   ▀▀▀▀ ▀  ▀ ▀▀▀▀ ▀  ▀         ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${LINEA_VERT}                                 ${LINEA_VERT}"
    echo -e "${LINEA_VERT}      ${CIAN_TERMUX}ADMINISTRACIÓN DE SERVIDORES VPS      ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${LINEA_VERT}         ${MORADO_TERMUX}ESTILO TERMUX • GESTIÓN SSH           ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${ESQUINA_INF_IZQ}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${ESQUINA_INF_DER}"
    echo -e "${NC}"
    
    # Información del sistema estilo Termux
    echo -e "${AZUL_TERMUX}${CUADRADO} FECHA: ${BLANCO_TERMUX}$(date +"%d/%m/%Y %H:%M:%S")${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} SISTEMA: ${BLANCO_TERMUX}$(lsb_release -d | cut -f2)${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} IP PÚBLICA: ${BLANCO_TERMUX}$(curl -s ifconfig.me)${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} NÚCLEO: ${BLANCO_TERMUX}$(uname -r)${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} ALMACENAMIENTO: ${BLANCO_TERMUX}$(df -h / | awk 'NR==2 {print $4}') LIBRE${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} MEMORIA RAM: ${BLANCO_TERMUX}$(free -h | awk 'NR==2 {print $4}') LIBRE${NC}"
    echo -e "${VERDE_TERMUX}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${NC}"
    echo ""
}

# ╔══════════════════════════════════════════════════════════╗
# ║              ACTUALIZACIÓN Y HERRAMIENTAS                 ║
# ╚══════════════════════════════════════════════════════════╝

actualizar_sistema() {
    echo -e "${AMARILLO_TERMUX}${ESTRELLA} INICIANDO ACTUALIZACIÓN DEL SISTEMA ${ESTRELLA}${NC}"
    echo -e "${CIAN_TERMUX}${ABAJO} Actualizando lista de paquetes...${NC}"
    apt update -y &> /dev/null
    
    echo -e "${CIAN_TERMUX}${ABAJO} Instalando herramientas esenciales...${NC}"
    apt install -y curl wget nano vim htop net-tools unzip tar screen git ufw lsb-release &> /dev/null
    
    echo -e "${VERDE_TERMUX}${ESTRELLA} SISTEMA ACTUALIZADO CORRECTAMENTE ${ESTRELLA}${NC}"
    read -p -s "Presiona ENTER para continuar..."
}

# ╔══════════════════════════════════════════════════════════╗
# ║                GESTIÓN DE USUARIOS SSH                   ║
# ╚══════════════════════════════════════════════════════════╝

menu_usuarios() {
    while true; do
        banner_jitterx
        echo -e "${MORADO_TERMUX}${ESTRELLA} GESTIÓN DE USUARIOS SSH ${ESTRELLA}${NC}"
        echo -e "${BLANCO_TERMUX} 1. ${VERDE_TERMUX}Crear nuevo usuario${NC}"
        echo -e "${BLANCO_TERMUX} 2. ${ROJO_TERMUX}Eliminar usuario existente${NC}"
        echo -e "${BLANCO_TERMUX} 3. ${AZUL_TERMUX}Listar todos los usuarios${NC}"
        echo -e "${BLANCO_TERMUX} 4. ${AMARILLO_TERMUX}Cambiar contraseña${NC}"
        echo -e "${BLANCO_TERMUX} 5. ${CIAN_TERMUX}Ver vencimientos${NC}"
        echo -e "${BLANCO_TERMUX} 0. ${VERDE_OSCURO}Volver al menú principal${NC}"
        echo ""
        read -p "$(echo -e ${AZUL_TERMUX}${DERECHA} Selecciona opción: ${NC})" opc_u

        case $opc_u in
            1)
                echo -e "${AMARILLO_TERMUX}${ESTRELLA} CREACIÓN DE USUARIO ${ESTRELLA}${NC}"
                read -p "$(echo -e ${CIAN_TERMUX}Nombre de usuario: ${NC})" nombre_u
                read -s -p "$(echo -e ${CIAN_TERMUX}Contraseña: ${NC})" pass_u
                echo ""
                read -p "$(echo -e ${CIAN_TERMUX}Días de vencimiento (0 = sin límite): ${NC})" dias_u
                
                useradd -m -s /bin/bash "$nombre_u" &> /dev/null
                echo "$nombre_u:$pass_u" | chpasswd &> /dev/null
                
                if [ "$dias_u" -gt 0 ]; then
                    chage -E $(date -d "+$dias_u days" +%Y-%m-%d) "$nombre_u" &> /dev/null
                fi
                
                echo -e "${VERDE_TERMUX}${ESTRELLA} USUARIO $nombre_u CREADO EXITOSAMENTE ${ESTRELLA}${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            2)
                echo -e "${ROJO_TERMUX}${ESTRELLA} ELIMINACIÓN DE USUARIO ${ESTRELLA}${NC}"
                read -p "$(echo -e ${CIAN_TERMUX}Usuario a eliminar: ${NC})" del_u
                userdel -r "$del_u" &> /dev/null
                echo -e "${VERDE_TERMUX}${ESTRELLA} USUARIO $del_u ELIMINADO ${ESTRELLA}${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            3)
                echo -e "${AZUL_TERMUX}${ESTRELLA} LISTA DE USUARIOS ${ESTRELLA}${NC}"
                echo -e "${BLANCO_TERMUX}----------------------------------------${NC}"
                grep -E '/bin/bash|/bin/sh' /etc/passwd | cut -d: -f1
                echo -e "${BLANCO_TERMUX}----------------------------------------${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            4)
                echo -e "${AMARILLO_TERMUX}${ESTRELLA} CAMBIO DE CONTRASEÑA ${ESTRELLA}${NC}"
                read -p "$(echo -e ${CIAN_TERMUX}Usuario: ${NC})" mod_u
                read -s -p "$(echo -e ${CIAN_TERMUX}Nueva contraseña: ${NC})" nueva_p
                echo ""
                echo "$mod_u:$nueva_p" | chpasswd &> /dev/null
                echo -e "${VERDE_TERMUX}${ESTRELLA} CONTRASEÑA ACTUALIZADA ${ESTRELLA}${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            5)
                echo -e "${CIAN_TERMUX}${ESTRELLA} VENCIMIENTOS DE CUENTAS ${ESTRELLA}${NC}"
                for user in $(grep -E '/bin/bash|/bin/sh' /etc/passwd | cut -d: -f1); do
                    expir=$(chage -l "$user" | grep "Cuenta expira" | cut -d: -f2)
                    echo -e "${BLANCO_TERMUX}${CUADRADO} $user : ${AMARILLO_TERMUX}$expir${NC}"
                done
                read -p -s "ENTER para continuar..."
                ;;
            
            0) break ;;
            *) echo -e "${ROJO_TERMUX}${ESTRELLA} OPCIÓN INVÁLIDA ${ESTRELLA}${NC}"; sleep 1 ;;
        esac
    done
}

# ╔══════════════════════════════════════════════════════════╗
# ║               GESTIÓN DE PUERTOS Y FIREWALL               ║
# ╚══════════════════════════════════════════════════════════╝

menu_puertos() {
    while true; do
        banner_jitterx
        echo -e "${MORADO_TERMUX}${ESTRELLA} GESTIÓN DE PUERTOS Y SERVICIOS ${ESTRELLA}${NC}"
        echo -e "${BLANCO_TERMUX} 1. ${AZUL_TERMUX}Ver puertos abiertos${NC}"
        echo -e "${BLANCO_TERMUX} 2. ${VERDE_TERMUX}Abrir puerto en firewall${NC}"
        echo -e "${BLANCO_TERMUX} 3. ${ROJO_TERMUX}Cerrar puerto en firewall${NC}"
        echo -e "${BLANCO_TERMUX} 4. ${AMARILLO_TERMUX}Cambiar puerto SSH${NC}"
        echo -e "${BLANCO_TERMUX} 5. ${CIAN_TERMUX}Estado de servicios${NC}"
        echo -e "${BLANCO_TERMUX} 0. ${VERDE_OSCURO}Volver al menú${NC}"
        echo ""
        read -p "$(echo -e ${AZUL_TERMUX}${DERECHA} Opción: ${NC})" opc_p

        case $opc_p in
            1)
                echo -e "${AZUL_TERMUX}${ESTRELLA} PUERTOS EN USO ${ESTRELLA}${NC}"
                netstat -tulpn | grep LISTEN
                read -p -s "ENTER para continuar..."
                ;;
            
            2)
                read -p "$(echo -e ${CIAN_TERMUX}Puerto a abrir: ${NC})" p_abrir
                ufw allow "$p_abrir"/tcp &> /dev/null
                ufw reload &> /dev/null
                echo -e "${VERDE_TERMUX}${ESTRELLA} PUERTO $p_abrir ABIERTO ${ESTRELLA}${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            3)
                read -p "$(echo -e ${CIAN_TERMUX}Puerto a cerrar: ${NC})" p_cerrar
                ufw deny "$p_cerrar"/tcp &> /dev/null
                ufw reload &> /dev/null
                echo -e "${VERDE_TERMUX}${ESTRELLA} PUERTO $p_cerrar CERRADO ${ESTRELLA}${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            4)
                read -p "$(echo -e ${CIAN_TERMUX}Nuevo puerto SSH: ${NC})" p_ssh
                sed -i "s/^Port [0-9]*/Port $p_ssh/" /etc/ssh/sshd_config &> /dev/null
                systemctl restart ssh &> /dev/null
                ufw allow "$p_ssh"/tcp &> /dev/null
                echo -e "${VERDE_TERMUX}${ESTRELLA} PUERTO SSH CAMBIADO A $p_ssh ${ESTRELLA}${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            5)
                echo -e "${CIAN_TERMUX}${ESTRELLA} ESTADO DE SERVICIOS ${ESTRELLA}${NC}"
                systemctl status ssh --no-pager -l | grep -E "Active|Loaded"
                systemctl status dropbear --no-pager -l 2>/dev/null | grep -E "Active|Loaded" || echo -e "${AMARILLO_TERMUX}Dropbear: No instalado${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            0) break ;;
            *) echo -e "${ROJO_TERMUX}${ESTRELLA} OPCIÓN INVÁLIDA ${ESTRELLA}${NC}"; sleep 1 ;;
        esac
    done
}

# ╔══════════════════════════════════════════════════════════╗
# ║                   HERRAMIENTAS EXTRAS                     ║
# ╚══════════════════════════════════════════════════════════╝

menu_herramientas() {
    while true; do
        banner_jitterx
        echo -e "${MORADO_TERMUX}${ESTRELLA} HERRAMIENTAS Y SEGURIDAD ${ESTRELLA}${NC}"
        echo -e "${BLANCO_TERMUX} 1. ${VERDE_TERMUX}Instalar Dropbear${NC}"
        echo -e "${BLANCO_TERMUX} 2. ${VERDE_TERMUX}Instalar Fail2Ban${NC}"
        echo -e "${BLANCO_TERMUX} 3. ${AZUL_TERMUX}Monitor de recursos (htop)${NC}"
        echo -e "${BLANCO_TERMUX} 4. ${AMARILLO_TERMUX}Reiniciar servidor${NC}"
        echo -e "${BLANCO_TERMUX} 5. ${ROJO_TERMUX}Apagar servidor${NC}"
        echo -e "${BLANCO_TERMUX} 0. ${VERDE_OSCURO}Volver al menú${NC}"
        echo ""
        read -p "$(echo -e ${AZUL_TERMUX}${DERECHA} Opción: ${NC})" opc_h

        case $opc_h in
            1)
                echo -e "${AMARILLO_TERMUX}${ESTRELLA} INSTALANDO DROPBEAR ${ESTRELLA}${NC}"
                apt install -y dropbear &> /dev/null
                sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear &> /dev/null
                systemctl enable --now dropbear &> /dev/null
                echo -e "${VERDE_TERMUX}${ESTRELLA} DROPBEAR INSTALADO ${ESTRELLA}${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            2)
                echo -e "${AMARILLO_TERMUX}${ESTRELLA} INSTALANDO FAIL2BAN ${ESTRELLA}${NC}"
                apt install -y fail2ban &> /dev/null
                systemctl enable --now fail2ban &> /dev/null
                echo -e "${VERDE_TERMUX}${ESTRELLA} FAIL2BAN ACTIVO - PROTEGIENDO ACCESOS ${ESTRELLA}${NC}"
                read -p -s "ENTER para continuar..."
                ;;
            
            3) htop ;;
            
            4)
                read -p "$(echo -e ${ROJO_TERMUX}¿Seguro que deseas reiniciar? (s/n): ${NC})" conf_r
                if [[ "$conf_r" == "s" || "$conf_r" == "S" ]]; then
                    echo -e "${AMARILLO_TERMUX}${ESTRELLA} REINICIANDO SERVIDOR... ${ESTRELLA}${NC}"
                    reboot
                fi
                ;;
            
            5)
                read -p "$(echo -e ${ROJO_TERMUX}¿Seguro que deseas apagar? (s/n): ${NC})" conf_a
                if [[ "$conf_a" == "s" || "$conf_a" == "S" ]]; then
                    echo -e "${AMARILLO_TERMUX}${ESTRELLA} APAGANDO SERVIDOR... ${ESTRELLA}${NC}"
                    poweroff
                fi
                ;;
            
            0) break ;;
            *) echo -e "${ROJO_TERMUX}${ESTRELLA} OPCIÓN INVÁLIDA ${ESTRELLA}${NC}"; sleep 1 ;;
        esac
    done
}

# ╔══════════════════════════════════════════════════════════╗
# ║                   MENÚ PRINCIPAL                          ║
# ╚══════════════════════════════════════════════════════════╝

while true; do
    banner_jitterx
    echo -e "${VERDE_TERMUX}${ESTRELLA} MENÚ PRINCIPAL • JITTERX ${ESTRELLA}${NC}"
    echo -e "${BLANCO_TERMUX} 1. ${AZUL_TERMUX}Actualizar sistema${NC}"
    echo -e "${BLANCO_TERMUX} 2. ${MORADO_TERMUX}Gestión de usuarios SSH${NC}"
    echo -e "${BLANCO_TERMUX} 3. ${MORADO_TERMUX}Gestión de puertos y firewall${NC}"
    echo -e "${BLANCO_TERMUX} 4. ${MORADO_TERMUX}Herramientas y seguridad${NC}"
    echo -e "${BLANCO_TERMUX} 5. ${CIAN_TERMUX}Información completa del sistema${NC}"
    echo -e "${BLANCO_TERMUX} 0. ${ROJO_TERMUX}Salir del script${NC}"
    echo ""
    read -p "$(echo -e ${AZUL_TERMUX}${DERECHA} SELECCIONA OPCIÓN: ${NC})" main_opc

    case $main_opc in
        1) actualizar_sistema ;;
        2) menu_usuarios ;;
        3) menu_puertos ;;
        4) menu_herramientas ;;
        
        5)
            banner_jitterx
            echo -e "${CIAN_TERMUX}${ESTRELLA} INFORMACIÓN DETALLADA DEL SISTEMA ${ESTRELLA}${NC}"
            echo -e "${AMARILLO_TERMUX}• SISTEMA OPERATIVO: ${BLANCO_TERMUX}$(lsb_release -d | cut -f2)${NC}"
            echo -e "${AMARILLO_TERMUX}• ARQUITECTURA: ${BLANCO_TERMUX}$(uname -m)${NC}"
            echo -e "${AMARILLO_TERMUX}• DISCO:${NC}"
            df -h | grep -E "Filesystem|/$"
            echo -e "${AMARILLO_TERMUX}• MEMORIA:${NC}"
            free -h
            read -p -s "ENTER para continuar..."
            ;;
        
        0)
            echo -e "${VERDE_TERMUX}${ESTRELLA} SCRIPT FINALIZADO • CREADO POR JITTERX ${ESTRELLA}${NC}"
            exit 0
            ;;
        
        *)
            echo -e "${ROJO_TERMUX}${ESTRELLA} OPCIÓN NO VÁLIDA ${ESTRELLA}${NC}"
            sleep 1
            ;;
    esac
done
