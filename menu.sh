#!/bin/bash
# ================================================================
# JITTER PANEL SSH - Menu de Administración v3.1
# Ejecutar: sudo menu
# ================================================================

# COLORES JITTER THEME
PURPLE='\033[0;35m'; VIOLET='\033[1;35m'; PINK='\033[1;95m'
CYAN='\033[0;96m'; BLUE='\033[0;94m'; GREEN='\033[0;92m'
YELLOW='\033[1;93m'; RED='\033[0;91m'; WHITE='\033[1;97m'
GRAY='\033[0;90m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${RED}[!] Ejecutar como root: sudo menu${NC}" && exit 1
source /opt/netgetk/config 2>/dev/null

# ── FUNCIONES DE ANIMACIÓN ────────────────────────────────────
spinner() {
    local pid=$1
    local delay=0.08
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC} " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf " \b\b\b\b"
}

loading_bar() {
    local duration=$1
    local msg=$2
    echo -ne "${BLUE}▸${NC} ${WHITE}$msg${NC} "
    for i in $(seq 1 20); do
        echo -ne "${VIOLET}█${NC}"
        sleep $(bc -l <<< "$duration/20")
    done
    echo -e " ${GREEN}✓${NC}"
}

banner() {
    clear
    echo -e "${VIOLET}"
    cat << 'LOGO'
      ██╗██╗████████╗████████╗███████╗██████╗
      ██║██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗
      ██║██║ ██║ ██║ █████╗ ██████╔╝
 ██ ██║██║ ██║ ██║ ██╔══╝ ██╔══██╗
 ╚█████╔╝██║ ██║ ██║ ███████╗██║ ██║
  ╚════╝ ╚═╝ ╚═╝ ╚═╝ ╚══════╝╚═╝ ╚═╝
LOGO
    echo -e "${PINK} █ PANEL SSH MANAGER v3.1 █${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

status_check() {
    # SSH
    if systemctl is-active --quiet ssh; then
        SSH_STATUS="${GREEN}● ONLINE${NC}"
    else
        SSH_STATUS="${RED}● OFFLINE${NC}"
    fi

    # WebSocket
    if pm2 list | grep -q "netgetk-license.*online"; then
        WS_STATUS="${GREEN}● ONLINE${NC}"
    else
        WS_STATUS="${RED}● OFFLINE${NC}"
    fi

    # Dropbear
    if systemctl is-active --quiet dropbear; then
        DB_STATUS="${GREEN}● ONLINE${NC}"
    else
        DB_STATUS="${RED}● OFFLINE${NC}"
    fi

    # BadVPN
    if systemctl is-active --quiet badvpn; then
        UDP_STATUS="${GREEN}● ONLINE${NC}"
    else
        UDP_STATUS="${RED}● OFFLINE${NC}"
    fi
}

crear_usuario() {
    banner
    echo -e "${WHITE} [1] CREAR USUARIO SSH${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -ne " ${BLUE}▸${NC} ${WHITE}Usuario: ${NC}"
    read usuario
    [[ -z $usuario ]] && echo -e "${RED}[!] Usuario vacio${NC}" && sleep 1 && return

    echo -ne " ${BLUE}▸${NC} ${WHITE}Contraseña: ${NC}"
    read -s senha
    echo ""
    [[ -z $senha ]] && echo -e "${RED}[!] Contraseña vacia${NC}" && sleep 1 && return

    echo -ne " ${BLUE}▸${NC} ${WHITE}Dias para expirar [0 = nunca]: ${NC}"
    read dias
    [[ -z $dias ]] && dias=0

    echo -ne " ${BLUE}▸${NC} ${WHITE}Limite conexiones [0 = ilimitado]: ${NC}"
    read limite
    [[ -z $limite ]] && limite=0

    echo ""
    loading_bar 0.4 "Creando usuario"

    useradd -M -s /bin/false $usuario 2>/dev/null
    (echo $senha; echo $senha) | passwd $usuario > /dev/null 2>&1

    [[ $dias -ne 0 ]] && chage -E $(date -d "+$dias days" +%Y-%m-%d) $usuario
    [[ $limite -ne 0 ]] && echo "$usuario $limite" >> /root/usuarios.db

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC} ${WHITE}✓ Usuario creado correctamente${NC} ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
    echo -e " ${BLUE}Usuario:${NC} ${CYAN}$usuario${NC}"
    echo -e " ${BLUE}Clave:${NC} ${CYAN}$senha${NC}"
    [[ $dias -ne 0 ]] && echo -e " ${BLUE}Expira:${NC} ${CYAN}$dias dias${NC}"
    [[ $limite -ne 0 ]] && echo -e " ${BLUE}Limite:${NC} ${CYAN}$limite conexiones${NC}"
    echo ""
    read -p "$(echo -e ${GRAY}Enter para volver...${NC})"
}

eliminar_usuario() {
    banner
    echo -e "${WHITE} [2] ELIMINAR USUARIO${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -ne " ${BLUE}▸${NC} ${WHITE}Usuario a eliminar: ${NC}"
    read usuario
    [[ -z $usuario ]] && return

    loading_bar 0.3 "Eliminando usuario"
    pkill -u $usuario 2>/dev/null
    userdel -f $usuario 2>/dev/null
    sed -i "/^$usuario /d" /root/usuarios.db 2>/dev/null

    echo ""
    echo -e " ${GREEN}✓ Usuario $usuario eliminado${NC}"
    sleep 1
}

ver_usuarios() {
    banner
    echo -e "${WHITE} [3] USUARIOS REGISTRADOS${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    printf "${BLUE}%-15s %-12s %-10s${NC}\n" "USUARIO" "EXPIRA" "LIMITE"
    echo -e "${GRAY}─────────────────────────────────────────────────${NC}"

    for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd | grep -v nobody); do
        exp=$(chage -l $user 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        [[ "$exp" == "never" ]] && exp="Nunca"
        lim=$(grep "^$user " /root/usuarios.db 2>/dev/null | cut -d' ' -f2)
        [[ -z $lim ]] && lim="∞"
        printf "${CYAN}%-15s${NC} ${WHITE}%-12s${NC} ${YELLOW}%-10s${NC}\n" $user "$exp" $lim
    done

    echo ""
    read -p "$(echo -e ${GRAY}Enter para volver...${NC})"
}

ver_conectados() {
    banner
    echo -e "${WHITE} [4] USUARIOS CONECTADOS${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    printf "${BLUE}%-15s %-10s${NC}\n" "USUARIO" "CONEXIONES"
    echo -e "${GRAY}─────────────────────────────────${NC}"

    data=( $(ps aux | grep -i sshd | grep -v grep | awk '{print $1}' | sort -u) )
    for user in "${data[@]}"; do
        [[ "$user" == "root" ]] && continue
        con=$(ps -u $user | grep -c sshd)
        [[ $con -ne 0 ]] && printf "${CYAN}%-15s${NC} ${GREEN}%-10s${NC}\n" $user $con
    done

    echo ""
    read -p "$(echo -e ${GRAY}Enter para volver...${NC})"
}

cambiar_banner() {
    banner
    echo -e "${WHITE} [5] CAMBIAR BANNER SSH${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GRAY}Pega tu banner. Ctrl+D para guardar:${NC}"
    echo ""
    cat > /etc/ssh/banner_jitter
    sed -i '/^Banner/d' /etc/ssh/sshd_config
    echo "Banner /etc/ssh/banner_jitter" >> /etc/ssh/sshd_config
    systemctl restart ssh &
    spinner $!
    echo -e " ${GREEN}✓ Banner actualizado${NC}"
    sleep 1
}

reiniciar_servicios() {
    banner
    echo -e "${WHITE} [6] REINICIAR SERVICIOS${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    loading_bar 0.5 "Reiniciando SSH"
    systemctl restart ssh &
    spinner $!
    loading_bar 0.5 "Reiniciando WebSocket"
    pm2 restart netgetk-license &>/dev/null &
    spinner $!
    loading_bar 0.3 "Reiniciando Dropbear"
    systemctl restart dropbear &
    spinner $!
    loading_bar 0.3 "Reiniciando BadVPN"
    systemctl restart badvpn &
    spinner $!
    echo ""
    echo -e " ${GREEN}✓ Todos los servicios reiniciados${NC}"
    sleep 1
}

info_sistema() {
    banner
    echo -e "${WHITE} [7] INFORMACION DEL SISTEMA${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e " ${BLUE}IP VPS:${NC} ${CYAN}$MY_IP${NC}"
    echo -e " ${BLUE}Sistema:${NC} ${CYAN}$(lsb_release -d | cut -f2)${NC}"
    echo -e " ${BLUE}Kernel:${NC} ${CYAN}$(uname -r)${NC}"
    echo -e " ${BLUE}CPU:${NC} ${CYAN}$(grep -c processor /proc/cpuinfo) cores${NC}"
    echo -e " ${BLUE}RAM:${NC} ${CYAN}$(free -h | awk '/Mem:/ {print $3 "/" $2}')${NC}"
    echo -e " ${BLUE}Uptime:${NC} ${CYAN}$(uptime -p)${NC}"
    echo -e " ${BLUE}License URL:${NC} ${CYAN}http://$MY_IP:$LIC_PORT${NC}"
    echo ""
    read -p "$(echo -e ${GRAY}Enter para volver...${NC})"
}

desinstalar() {
    banner
    echo -e "${RED} [8] DESINSTALAR JITTER PANEL${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -ne " ${YELLOW}⚠ ¿Seguro que quieres borrar todo? (s/n): ${NC}"
    read resp
    [[ $resp!= "s" && $resp!= "S" ]] && return

    loading_bar 1 "Desinstalando servicios"
    pm2 delete netgetk-license netgetk-bot &>/dev/null
    systemctl stop ws-http badvpn 2>/dev/null
    systemctl disable ws-http badvpn 2>/dev/null
    rm -rf /opt/netgetk /usr/local/bin/jitter /usr/bin/menu
    rm -f /etc/systemd/system/ws-http.service /etc/systemd/system/badvpn.service
    systemctl daemon-reload

    echo ""
    echo -e " ${GREEN}✓ Jitter Panel SSH desinstalado${NC}"
    sleep 2
    exit 0
}

# ── MENU PRINCIPAL ────────────────────────────────────────────
while true; do
    banner
    status_check

    echo -e "${WHITE} ESTADO DE SERVICIOS${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${WHITE}SSH:${NC} $SSH_STATUS ${GRAY}| Puerto 22${NC}"
    echo -e " ${WHITE}WebSocket:${NC} $WS_STATUS ${GRAY}| Puerto 80${NC}"
    echo -e " ${WHITE}Dropbear:${NC} $DB_STATUS ${GRAY}| Puerto 444${NC}"
    echo -e " ${WHITE}BadVPN:${NC} $UDP_STATUS ${GRAY}| Puerto 7300${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE} GESTION DE USUARIOS${NC}"
    echo -e " ${PINK}[1]${NC} ${WHITE}Crear Usuario SSH${NC}"
    echo -e " ${PINK}[2]${NC} ${WHITE}Eliminar Usuario${NC}"
    echo -e " ${PINK}[3]${NC} ${WHITE}Ver Usuarios Creados${NC}"
    echo -e " ${PINK}[4]${NC} ${WHITE}Usuarios Conectados${NC}"
    echo ""
    echo -e "${WHITE} CONFIGURACION${NC}"
    echo -e " ${PINK}[5]${NC} ${WHITE}Cambiar Banner SSH${NC}"
    echo -e " ${PINK}[6]${NC} ${WHITE}Reiniciar Servicios${NC}"
    echo -e " ${PINK}[7]${NC} ${WHITE}Info del Sistema${NC}"
    echo -e " ${PINK}[8]${NC} ${RED}Desinstalar Script${NC}"
    echo -e " ${PINK}[0]${NC} ${GRAY}Salir${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -ne " ${BLUE}▸${NC} ${WHITE}Opcion: ${NC}"

    read opcao
    case $opcao in
        1) crear_usuario ;;
        2) eliminar_usuario ;;
        3) ver_usuarios ;;
        4) ver_conectados ;;
        5) cambiar_banner ;;
        6) reiniciar_servicios ;;
        7) info_sistema ;;
        8) desinstalar ;;
        0) clear; echo -e "${GREEN}Hasta luego!${NC}"; exit ;;
        *) echo -e " ${RED}[!] Opcion invalida${NC}"; sleep 1 ;;
    esac
done
