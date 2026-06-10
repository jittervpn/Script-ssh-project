#!/bin/bash
# =============================================================================
# Nombre: menu.sh
# Propósito: Menú principal y submenús - JITTERX VPS MANAGER
# Estilo: Termux / La Casita MX / Chumogh
# Autor: jitterx
# Versión: 2.0
# =============================================================================

# ╔══════════════════════════════════════════════════════════╗
# ║            CONFIGURACIÓN DE COLORES Y SÍMBOLOS            ║
# ╚══════════════════════════════════════════════════════════╝

# Colores estilo Termux
NEGRO='\033[1;30m'
ROJO_TERMUX='\033[1;31m'
VERDE_TERMUX='\033[1;32m'
AMARILLO_TERMUX='\033[1;33m'
AZUL_TERMUX='\033[1;34m'
MORADO_TERMUX='\033[1;35m'
CIAN_TERMUX='\033[1;36m'
BLANCO_TERMUX='\033[1;37m'
VERDE_OSCURO='\033[0;32m'
NC='\033[0m'

# Símbolos y bordes
ESTRELLA="★"
CUADRADO="■"
FLECHA_DER="→"
LINEA="═"
ESQ_SUP_IZQ="╔"
ESQ_SUP_DER="╗"
ESQ_INF_IZQ="╚"
ESQ_INF_DER="╝"
LINEA_VERT="║"

# ╔══════════════════════════════════════════════════════════╗
# ║                   BANNER PRINCIPAL JITTERX                ║
# ╚══════════════════════════════════════════════════════════╝

mostrar_banner() {
    clear
    echo -e "${VERDE_TERMUX}"
    echo -e "${ESQ_SUP_IZQ}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${ESQ_SUP_DER}"
    echo -e "${LINEA_VERT}        ${AMARILLO_TERMUX}▀▀█▀▀ █▀▀█ █▀▀▄ █▀▀▀ █▀▀█         ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${LINEA_VERT}        ${AMARILLO_TERMUX}  █   █  █ █  █ █ ▀█ █▄▄█         ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${LINEA_VERT}        ${AMARILLO_TERMUX}  █   ▀▀▀▀ ▀  ▀ ▀▀▀▀ ▀  ▀         ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${LINEA_VERT}                                 ${LINEA_VERT}"
    echo -e "${LINEA_VERT}      ${CIAN_TERMUX}ADMINISTRACIÓN DE SERVIDORES VPS      ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${LINEA_VERT}         ${MORADO_TERMUX}ESTILO TERMUX • GESTIÓN SSH           ${VERDE_TERMUX}${LINEA_VERT}"
    echo -e "${ESQ_INF_IZQ}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${ESQ_INF_DER}"
    echo -e "${NC}"

    # Datos del sistema
    echo -e "${AZUL_TERMUX}${CUADRADO} FECHA: ${BLANCO_TERMUX}$(date +"%d/%m/%Y %H:%M:%S")${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} SISTEMA: ${BLANCO_TERMUX}$(lsb_release -d | cut -f2)${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} IP PÚBLICA: ${BLANCO_TERMUX}$(curl -s ifconfig.me)${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} NÚCLEO: ${BLANCO_TERMUX}$(uname -r)${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} DISCO LIBRE: ${BLANCO_TERMUX}$(df -h / | awk 'NR==2 {print $4}')${NC}"
    echo -e "${AZUL_TERMUX}${CUADRADO} RAM LIBRE: ${BLANCO_TERMUX}$(free -h | awk 'NR==2 {print $4}')${NC}"
    echo -e "${VERDE_TERMUX}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${LINEA}${NC}"
    echo ""
}

# ╔══════════════════════════════════════════════════════════╗
# ║                   MENÚ PRINCIPAL                          ║
# ╚══════════════════════════════════════════════════════════╝

menu_principal() {
    while true; do
        mostrar_banner
        echo -e "${VERDE_TERMUX}${ESTRELLA} MENÚ PRINCIPAL • CREADO POR JITTERX ${ESTRELLA}${NC}"
        echo -e "${BLANCO_TERMUX} 1. ${AZUL_TERMUX}Actualizar sistema e instalar herramientas${NC}"
        echo -e "${BLANCO_TERMUX} 2. ${MORADO_TERMUX}Gestión completa de usuarios SSH${NC}"
        echo -e "${BLANCO_TERMUX} 3. ${MORADO_TERMUX}Gestión de puertos, firewall y servicios${NC}"
        echo -e "${BLANCO_TERMUX} 4. ${MORADO_TERMUX}Herramientas extras y seguridad${NC}"
        echo -e "${BLANCO_TERMUX} 5. ${CIAN_TERMUX}Información detallada del servidor${NC}"
        echo -e "${BLANCO_TERMUX} 0. ${ROJO_TERMUX}Salir del script${NC}"
        echo ""
        read -p "$(echo -e ${AZUL_TERMUX}${FLECHA_DER} SELECCIONA UNA OPCIÓN: ${NC})" opcion

        case $opcion in
            1) actualizar_sistema ;;   # Función definida en el script principal
            2) menu_usuarios ;;        # Llama al submenú de usuarios
            3) menu_puertos ;;         # Llama al submenú de puertos
            4) menu_herramientas ;;    # Llama al submenú de herramientas
            5) mostrar_info_sistema ;; # Muestra datos completos
            0)
                echo -e "${VERDE_TERMUX}${ESTRELLA} SCRIPT FINALIZADO • GRACIAS POR USAR JITTERX ${ESTRELLA}${NC}"
                exit 0
                ;;
            *)
                echo -e "${ROJO_TERMUX}${ESTRELLA} OPCIÓN NO VÁLIDA, INTENTA DE NUEVO ${ESTRELLA}${NC}"
                sleep 1
                ;;
        esac
    done
}

# ╔══════════════════════════════════════════════════════════╗
# ║                SUBMENÚ: GESTIÓN DE USUARIOS               ║
# ╚══════════════════════════════════════════════════════════╝

menu_usuarios() {
    while true; do
        mostrar_banner
        echo -e "${MORADO_TERMUX}${ESTRELLA} GESTIÓN DE USUARIOS SSH ${ESTRELLA}${NC}"
        echo -e "${BLANCO_TERMUX} 1. ${VERDE_TERMUX}Crear nuevo usuario (con vencimiento)${NC}"
        echo -e "${BLANCO_TERMUX} 2. ${ROJO_TERMUX}Eliminar usuario existente${NC}"
        echo -e "${BLANCO_TERMUX} 3. ${AZUL_TERMUX}Listar todos los usuarios activos${NC}"
        echo -e "${BLANCO_TERMUX} 4. ${AMARILLO_TERMUX}Cambiar contraseña de usuario${NC}"
        echo -e "${BLANCO_TERMUX} 5. ${CIAN_TERMUX}Ver fecha de vencimiento de cuentas${NC}"
        echo -e "${BLANCO_TERMUX} 0. ${VERDE_OSCURO}Volver al menú principal${NC}"
        echo ""
        read -p "$(echo -e ${AZUL_TERMUX}${FLECHA_DER} SELECCIONA OPCIÓN: ${NC})" opc_u

        case $opc_u in
            1) crear_usuario ;;
            2) eliminar_usuario ;;
            3) listar_usuarios ;;
            4) cambiar_pass_usuario ;;
            5) ver_vencimientos ;;
            0) break ;;
            *) echo -e "${ROJO_TERMUX}${ESTRELLA} OPCIÓN INVÁLIDA ${ESTRELLA}${NC}"; sleep 1 ;;
        esac
    done
}

# ╔══════════════════════════════════════════════════════════╗
# ║             SUBMENÚ: PUERTOS Y FIREWALL                   ║
# ╚══════════════════════════════════════════════════════════╝

menu_puertos() {
    while true; do
        mostrar_banner
        echo -e "${MORADO_TERMUX}${ESTRELLA} GESTIÓN DE PUERTOS Y SERVICIOS ${ESTRELLA}${NC}"
        echo -e "${BLANCO_TERMUX} 1. ${AZUL_TERMUX}Ver puertos abiertos y en uso${NC}"
        echo -e "${BLANCO_TERMUX} 2. ${VERDE_TERMUX}Abrir puerto en el firewall (UFW)${NC}"
        echo -e "${BLANCO_TERMUX} 3. ${ROJO_TERMUX}Cerrar puerto en el firewall${NC}"
        echo -e "${BLANCO_TERMUX} 4. ${AMARILLO_TERMUX}Cambiar puerto de acceso SSH${NC}"
        echo -e "${BLANCO_TERMUX} 5. ${CIAN_TERMUX}Ver estado de servicios (SSH, Dropbear)${NC}"
        echo -e "${BLANCO_TERMUX} 0. ${VERDE_OSCURO}Volver al menú principal${NC}"
        echo ""
        read -p "$(echo -e ${AZUL_TERMUX}${FLECHA_DER} SELECCIONA OPCIÓN: ${NC})" opc_p

        case $opc_p in
            1) ver_puertos_abiertos ;;
            2) abrir_puerto ;;
            3) cerrar_puerto ;;
            4) cambiar_puerto_ssh ;;
            5) estado_servicios ;;
            0) break ;;
            *) echo -e "${ROJO_TERMUX}${ESTRELLA} OPCIÓN INVÁLIDA ${ESTRELLA}${NC}"; sleep 1 ;;
        esac
    done
}

# ╔══════════════════════════════════════════════════════════╗
# ║             SUBMENÚ: HERRAMIENTAS EXTRAS                  ║
# ╚══════════════════════════════════════════════════════════╝

menu_herramientas() {
    while true; do
        mostrar_banner
        echo -e "${MORADO_TERMUX}${ESTRELLA} HERRAMIENTAS Y SEGURIDAD ${ESTRELLA}${NC}"
        echo -e "${BLANCO_TERMUX} 1. ${VERDE_TERMUX}Instalar Dropbear (SSH ligero)${NC}"
        echo -e "${BLANCO_TERMUX} 2. ${VERDE_TERMUX}Instalar Fail2Ban (Protección de ataques)${NC}"
        echo -e "${BLANCO_TERMUX} 3. ${AZUL_TERMUX}Monitor de recursos en tiempo real${NC}"
        echo -e "${BLANCO_TERMUX} 4. ${AMARILLO_TERMUX}Reiniciar servidor VPS${NC}"
        echo -e "${BLANCO_TERMUX} 5. ${ROJO_TERMUX}Apagar servidor VPS${NC}"
        echo -e "${BLANCO_TERMUX} 0. ${VERDE_OSCURO}Volver al menú principal${NC}"
        echo ""
        read -p "$(echo -e ${AZUL_TERMUX}${FLECHA_DER} SELECCIONA OPCIÓN: ${NC})" opc_h

        case $opc_h in
            1) instalar_dropbear ;;
            2) instalar_fail2ban ;;
            3) htop ;;
            4) reiniciar_servidor ;;
            5) apagar_servidor ;;
            0) break ;;
            *) echo -e "${ROJO_TERMUX}${ESTRELLA} OPCIÓN INVÁLIDA ${ESTRELLA}${NC}"; sleep 1 ;;
        esac
    done
}

# ╔══════════════════════════════════════════════════════════╗
# ║             FUNCIÓN: INFORMACIÓN DEL SISTEMA              ║
# ╚══════════════════════════════════════════════════════════╝

mostrar_info_sistema() {
    mostrar_banner
    echo -e "${CIAN_TERMUX}${ESTRELLA} INFORMACIÓN DETALLADA DEL SERVIDOR ${ESTRELLA}${NC}"
    echo -e "${AMARILLO_TERMUX}• SISTEMA OPERATIVO: ${BLANCO_TERMUX}$(lsb_release -d | cut -f2)${NC}"
    echo -e "${AMARILLO_TERMUX}• ARQUITECTURA: ${BLANCO_TERMUX}$(uname -m)${NC}"
    echo -e "${AMARILLO_TERMUX}• VERSIÓN DEL KERNEL: ${BLANCO_TERMUX}$(uname -r)${NC}"
    echo -e "${AMARILLO_TERMUX}• ESPACIO EN DISCO:${NC}"
    df -h | grep -E "Filesystem|/$"
    echo -e "${AMARILLO_TERMUX}• MEMORIA RAM:${NC}"
    free -h
    echo -e "${AMARILLO_TERMUX}• INTERFACES DE RED:${NC}"
    ip addr show | grep inet | awk '{print $2}'
    echo ""
    read -p -s "Presiona ENTER para volver..."
}
