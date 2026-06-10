#!/bin/bash
# ================================================================
#   JITTER PANEL SSH - Bot de Telegram Setup
#   Configura las variables y ejecuta el bot con PM2
# ================================================================

# COLORES JITTER THEME
PURPLE='\033[0;35m'; VIOLET='\033[1;35m'; PINK='\033[1;95m'
CYAN='\033[0;96m'; BLUE='\033[0;94m'; GREEN='\033[0;92m'
YELLOW='\033[1;93m'; RED='\033[0;91m'; WHITE='\033[1;97m'
GRAY='\033[0;90m'; NC='\033[0m'

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

clear
echo -e "${VIOLET}"
cat << 'LOGO'
      ██╗██╗████████╗████████╗███████╗██████╗
      ██║██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗
      ██║██║ ██║ ██║ █████╗ ██████╔╝
 ██ ██║██║ ██║ ██║ ██╔══╝ ██╔══██╗
 ╚█████╔╝██║ ██║ ██║ ███████╗██║ ██║
  ╚════╝ ╚═╝ ╚══════╝╚═╝ ╚═╝
LOGO
echo -e "${PINK} █ BOT TELEGRAM - SETUP v3.1 █${NC}"
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar que existe .env o pedirlos
if [[! -f .env ]]; then
    echo -e "${WHITE} Configuración Inicial del Bot${NC}"
    echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${PINK}[1/4]${NC} ${WHITE}BOT_TOKEN de Telegram${NC}"
    echo -e "      ${GRAY}→ Ve a Telegram, busca @BotFather${NC}"
    echo -e "      ${GRAY}→ Escribe /newbot, obtendrás el token${NC}"
    echo -e "      ${GRAY}→ Formato: 1234567890:ABCdefGHIjklMNO...${NC}"
    echo ""
    echo -ne " ${BLUE}▸${NC} ${WHITE}BOT_TOKEN: ${NC}"
    read BOT_TOKEN
    [[ -z "$BOT_TOKEN" ]] && echo -e "${RED}[!] Token requerido${NC}" && exit 1

    echo ""
    echo -e "${PINK}[2/4]${NC} ${WHITE}Tu TELEGRAM ID${NC}"
    echo -e "      ${GRAY}→ Ve a Telegram, busca @userinfobot${NC}"
    echo -e "      ${GRAY}→ Escríbele /start para obtener tu ID${NC}"
    echo ""
    echo -ne " ${BLUE}▸${NC} ${WHITE}Tu Telegram ID: ${NC}"
    read ADMIN_IDS
    [[ -z "$ADMIN_IDS" ]] && echo -e "${RED}[!] ID requerido${NC}" && exit 1

    echo ""
    echo -e "${PINK}[3/4]${NC} ${WHITE}URL del License Server${NC}"
    echo -e "      ${GRAY}→ Ej: https://app.railway.app o http://IP:3000${NC}"
    echo ""
    echo -ne " ${BLUE}▸${NC} ${WHITE}License Server URL: ${NC}"
    read LICENSE_SERVER
    [[ -z "$LICENSE_SERVER" ]] && echo -e "${RED}[!] URL requerida${NC}" && exit 1

    echo ""
    echo -e "${PINK}[4/4]${NC} ${WHITE}ADMIN_TOKEN${NC}"
    echo -e "      ${GRAY}→ Debe ser el mismo que usaste en el servidor${NC}"
    echo ""
    echo -ne " ${BLUE}▸${NC} ${WHITE}ADMIN_TOKEN: ${NC}"
    read ADMIN_TOKEN
    [[ -z "$ADMIN_TOKEN" ]] && echo -e "${RED}[!] Token requerido${NC}" && exit 1

    cat > .env << ENV
BOT_TOKEN=$BOT_TOKEN
ADMIN_IDS=$ADMIN_IDS
LICENSE_SERVER=$LICENSE_SERVER
ADMIN_TOKEN=$ADMIN_TOKEN
ENV

    echo ""
    loading_bar 0.5 "Guardando configuración"
else
    echo -e " ${GREEN}✓${NC} ${WHITE}Archivo .env encontrado${NC}"
    echo ""
fi

# Cargar .env
export $(cat .env | xargs)

# Instalar dependencias si hace falta
if [[! -d node_modules ]]; then
    echo -e "${PINK}[1/2]${NC} ${WHITE}Instalando dependencias npm...${NC}"
    npm install --silent &> /dev/null &
    spinner $!
    echo -e " ${GREEN}✓${NC} Dependencias instaladas"
fi

# Iniciar con PM2
echo -e "${PINK}[2/2]${NC} ${WHITE}Iniciando bot con PM2...${NC}"
pm2 delete netgetk-bot 2>/dev/null
pm2 start bot.js --name netgetk-bot \
    --env production \
    -e /tmp/netgetk-bot-err.log \
    -o /tmp/netgetk-bot-out.log &> /dev/null &
spinner $!

pm2 save 2>/dev/null
pm2 startup 2>/dev/null | tail -1 | bash 2>/dev/null

echo ""
echo -e "${VIOLET}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${VIOLET}║${NC}           ${WHITE}✓ JITTER BOT INICIADO${NC}                        ${VIOLET}║${NC}"
echo -e "${VIOLET}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}🤖 Bot Telegram:${NC}   ${GREEN}Activo${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}📡 License Server:${NC} ${CYAN}$LICENSE_SERVER${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}👤 Admin ID:${NC}       ${CYAN}$ADMIN_IDS${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}📝 Comandos útiles:${NC}"
echo -e "${VIOLET}║${NC}  ${CYAN}pm2 logs netgetk-bot${NC}  → ver logs en vivo"
echo -e "${VIOLET}║${NC}  ${CYAN}pm2 restart netgetk-bot${NC} → reiniciar bot"
echo -e "${VIOLET}║${NC}  ${CYAN}pm2 stop netgetk-bot${NC}    → detener bot"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}🤖 Prueba el bot en Telegram - escribe /stats${NC}"
echo -e "${VIOLET}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
