#!/bin/bash
# ================================================================
#   JITTER PANEL SSH - Instalador del Sistema de Admin
#   Instala en TU VPS: servidor de licencias + bot de Telegram
#   Ejecutar como root en tu VPS principal
# ================================================================

# COLORES JITTER THEME
PURPLE='\033[0;35m'; VIOLET='\033[1;35m'; PINK='\033[1;95m'
CYAN='\033[0;96m'; BLUE='\033[0;94m'; GREEN='\033[0;92m'
YELLOW='\033[1;93m'; RED='\033[0;91m'; WHITE='\033[1;97m'
GRAY='\033[0;90m'; NC='\033[0m'

# ── FUNCIONES DE ANIMACIÓN ────────────────────────────────────
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
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
      ██║██║   ██║      ██║   █████╗  ██████╔╝
 ██   ██║██║   ██║      ██║   ██╔══╝  ██╔══██╗
 ╚█████╔╝██║   ██║      ██║   ███████╗██║  ██║
  ╚════╝ ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝
LOGO
echo -e "${PINK}     █ PANEL SSH MANAGER - INSTALADOR v3.1 █${NC}"
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

[[ $EUID -ne 0 ]] && echo -e "${RED}[!] Ejecutar como root${NC}" && exit 1

# ── Obtener IP del VPS admin ───────────────────────────────────
loading_bar 0.5 "Detectando IP del VPS"
MY_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
echo -e " ${BLUE}▸${NC} ${WHITE}IP Detectada:${NC} ${CYAN}$MY_IP${NC}"
echo ""

# ── Solicitar datos de configuración ──────────────────────────
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE} Configuración Inicial del Jitter Panel SSH${NC}"
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. Token del bot de Telegram
echo -e "${PINK}[1/4]${NC} ${WHITE}TOKEN del Bot de Telegram${NC}"
echo -e "      ${GRAY}→ Ve a Telegram, busca @BotFather${NC}"
echo -e "      ${GRAY}→ Escribe /newbot, pon un nombre, obtendrás el token${NC}"
echo -e "      ${GRAY}→ Formato: 1234567890:ABCdefGHIjklMNO...${NC}"
echo ""
echo -ne " ${BLUE}▸${NC} ${WHITE}Pega tu BOT TOKEN: ${NC}"
read BOT_TOKEN
if [[ -z "$BOT_TOKEN" ]]; then
    echo -e "${RED}[!] Token requerido${NC}"; exit 1
fi

echo ""

# 2. Telegram ID del admin
echo -e "${PINK}[2/4]${NC} ${WHITE}Tu TELEGRAM ID (número)${NC}"
echo -e "      ${GRAY}→ Ve a Telegram, busca @userinfobot${NC}"
echo -e "      ${GRAY}→ Escríbele /start${NC}"
echo -e "      ${GRAY}→ Te dirá tu ID: ej. 123456789${NC}"
echo ""
echo -ne " ${BLUE}▸${NC} ${WHITE}Tu Telegram ID: ${NC}"
read ADMIN_ID
if [[ -z "$ADMIN_ID" ]]; then
    echo -e "${RED}[!] ID requerido${NC}"; exit 1
fi

echo ""

# 3. Token secreto de admin (lo inventa el usuario)
echo -e "${PINK}[3/4]${NC} ${WHITE}Token secreto de administración${NC}"
echo -e "      ${GRAY}→ Inventa una contraseña segura para proteger el servidor${NC}"
echo -e "      ${GRAY}→ Ej: MiClaveSecreta2024 (guárdala, no la pierdas)${NC}"
echo ""
echo -ne " ${BLUE}▸${NC} ${WHITE}Token secreto (o Enter para generar uno): ${NC}"
read ADMIN_TOKEN
if [[ -z "$ADMIN_TOKEN" ]]; then
    ADMIN_TOKEN=$(openssl rand -hex 16)
    echo -e " ${GREEN}▸ Token generado: ${CYAN}$ADMIN_TOKEN${NC}"
    echo -e " ${YELLOW}⚠  Guárdalo en un lugar seguro${NC}"
fi

echo ""

# 4. Puerto del servidor de licencias
echo -e "${PINK}[4/4]${NC} ${WHITE}Puerto del servidor de licencias${NC}"
echo -e "      ${GRAY}→ Por defecto: 3000 (puedes cambiarlo)${NC}"
echo ""
echo -ne " ${BLUE}▸${NC} ${WHITE}Puerto (Enter = 3000): ${NC}"
read LIC_PORT
[[ -z "$LIC_PORT" ]] && LIC_PORT=3000

echo ""
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE} Resumen de Configuración:${NC}"
echo -e "  ${BLUE}Bot Token:${NC}    ${CYAN}${BOT_TOKEN:0:20}...${NC}"
echo -e "  ${BLUE}Admin ID:${NC}     ${CYAN}$ADMIN_ID${NC}"
echo -e "  ${BLUE}Admin Token:${NC}  ${CYAN}$ADMIN_TOKEN${NC}"
echo -e "  ${BLUE}Puerto:${NC}       ${CYAN}$LIC_PORT${NC}"
echo -e "  ${BLUE}URL servidor:${NC} ${CYAN}http://$MY_IP:$LIC_PORT${NC}"
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -ne "${YELLOW}¿Continuar con esta configuración? (s/n): ${NC}"
read CONFIRM
[[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]] && echo "Cancelado." && exit 0

echo ""

# ── Instalar dependencias ──────────────────────────────────────
echo -e "${PINK}[1/4]${NC} ${WHITE}Instalando dependencias...${NC}"
(apt update -y -qq && apt install -y -qq curl wget git ufw bc) &> /dev/null &
spinner $!

# Node.js 18
if! command -v node &>/dev/null; then
    echo -e "  ${BLUE}▸${NC} Instalando Node.js 18..."
    (curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt install -y nodejs) &> /dev/null &
    spinner $!
fi
echo -e "  ${GREEN}✓${NC} Node.js $(node -v)"

# PM2
if! command -v pm2 &>/dev/null; then
    echo -e "  ${BLUE}▸${NC} Instalando PM2..."
    npm install -g pm2 -q &> /dev/null &
    spinner $!
fi
echo -e "  ${GREEN}✓${NC} PM2 instalado"

# ── Crear directorio del sistema ───────────────────────────────
echo -e "${PINK}[2/4]${NC} ${WHITE}Creando estructura...${NC}"
loading_bar 0.3 "Preparando directorios"
mkdir -p /opt/netgetk/{license-server/data,bot}

# ── Descargar archivos ─────────────────────────────────────────
REPO="https://raw.githubusercontent.com/NETGETK/NETGETK-Script/main"

echo -e "  ${BLUE}▸${NC} Descargando license-server..."
(wget -q -O /opt/netgetk/license-server/server.js "$REPO/license-server/server.js" && \
 wget -q -O /opt/netgetk/license-server/package.json "$REPO/license-server/package.json") &> /dev/null &
spinner $!

echo -e "  ${BLUE}▸${NC} Descargando bot..."
(wget -q -O /opt/netgetk/bot/bot.js "$REPO/bot/bot.js" && \
 wget -q -O /opt/netgetk/bot/package.json "$REPO/bot/package.json") &> /dev/null &
spinner $!

# Si el repo no existe aún, crear los archivos localmente
if [[! -s /opt/netgetk/license-server/server.js ]]; then
    echo -e "  ${YELLOW}▸${NC} Repo no disponible, usando archivos locales..."
    [[ -f /tmp/NETGETK/license-server/server.js ]] && \
        cp -r /tmp/NETGETK/license-server/* /opt/netgetk/license-server/
    [[ -f /tmp/NETGETK/bot/bot.js ]] && \
        cp -r /tmp/NETGETK/bot/* /opt/netgetk/bot/
fi

# ── Guardar configuración en .env ─────────────────────────────
cat > /opt/netgetk/license-server/.env << ENV
PORT=$LIC_PORT
ADMIN_TOKEN=$ADMIN_TOKEN
ENV

cat > /opt/netgetk/bot/.env << ENV
BOT_TOKEN=$BOT_TOKEN
ADMIN_IDS=$ADMIN_ID
LICENSE_SERVER=http://127.0.0.1:$LIC_PORT
ADMIN_TOKEN=$ADMIN_TOKEN
ENV

# Guardar config general
cat > /opt/netgetk/config << CFG
MY_IP=$MY_IP
LIC_PORT=$LIC_PORT
ADMIN_TOKEN=$ADMIN_TOKEN
ADMIN_ID=$ADMIN_ID
LICENSE_SERVER_URL=http://$MY_IP:$LIC_PORT
INSTALLED=$(date +%Y-%m-%d)
CFG

chmod 600 /opt/netgetk/config /opt/netgetk/license-server/.env /opt/netgetk/bot/.env

# ── Instalar dependencias npm ──────────────────────────────────
echo -e "${PINK}[3/4]${NC} ${WHITE}Instalando paquetes npm...${NC}"
(cd /opt/netgetk/license-server && npm install --silent) &> /dev/null &
spinner $!
echo -e "  ${GREEN}✓${NC} License server listo"
(cd /opt/netgetk/bot && npm install --silent) &> /dev/null &
spinner $!
cd /etc/gtkvpn/panel && npm install --silent 2>/dev/null
echo -e "  ${GREEN}✓${NC} Bot listo"

# ── Iniciar con PM2 ───────────────────────────────────────────
echo -e "${PINK}[4/4]${NC} ${WHITE}Iniciando servicios...${NC}"

# License Server
pm2 delete netgetk-license 2>/dev/null
cd /opt/netgetk/license-server
pm2 start server.js --name netgetk-license \
    --env production \
    --node-args "--env-file .env" 2>/dev/null || \
pm2 start server.js --name netgetk-license 2>/dev/null

sleep 2

# Verificar que inició
if pm2 list | grep -q "netgetk-license.*online"; then
    echo -e "  ${GREEN}✓${NC} License Server corriendo en :$LIC_PORT"
else
    PORT=$LIC_PORT ADMIN_TOKEN=$ADMIN_TOKEN pm2 start server.js \
        --name netgetk-license 2>/dev/null
    sleep 2
fi

# Bot de Telegram
pm2 delete netgetk-bot 2>/dev/null
cd /opt/netgetk/bot
BOT_TOKEN=$BOT_TOKEN ADMIN_IDS=$ADMIN_ID \
LICENSE_SERVER="http://127.0.0.1:$LIC_PORT" \
ADMIN_TOKEN=$ADMIN_TOKEN \
pm2 start bot.js --name netgetk-bot 2>/dev/null

sleep 3

pm2 save 2>/dev/null
pm2 startup 2>/dev/null | tail -1 | bash 2>/dev/null

# ── Abrir puerto en UFW ────────────────────────────────────────
loading_bar 0.4 "Configurando firewall"
ufw allow $LIC_PORT/tcp 2>/dev/null
ufw allow 22/tcp 2>/dev/null
ufw --force enable 2>/dev/null

# ── Guardar comando de instalación para clientes ───────────────
LICENSE_URL="http://$MY_IP:$LIC_PORT"

echo ""
echo -e "${VIOLET}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${VIOLET}║${NC}           ${WHITE}✓ JITTER PANEL SSH INSTALADO${NC}                   ${VIOLET}║${NC}"
echo -e "${VIOLET}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}📡 License Server:${NC} ${CYAN}http://$MY_IP:$LIC_PORT${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}🤖 Bot Telegram:${NC}   ${GREEN}Activo${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${VIOLET}║${NC}  ${YELLOW}⚠  IMPORTANTE - Guarda esto:${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}║${NC}  ${BLUE}Admin Token:${NC} ${CYAN}$ADMIN_TOKEN${NC}"
echo -e "${VIOLET}║${NC}  ${BLUE}License URL:${NC} ${CYAN}http://$MY_IP:$LIC_PORT${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}📝 Antes de subir a GitHub, edita script/setup:${NC}"
echo -e "${VIOLET}║${NC}  ${CYAN}LICENSE_SERVER=\"http://$MY_IP:$LIC_PORT\"${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}🤖 Prueba el bot en Telegram - escribe /stats${NC}"
echo -e "${VIOLET}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Crear comando 'jitter' ────────────────────────────────────
cat > /usr/local/bin/jitter << 'CMD'
#!/bin/bash
PURPLE='\033[0;35m'; CYAN='\033[0;96m'; WHITE='\033[1;97m'; NC='\033[0m'
echo ""
echo -e "${PURPLE}█ JITTER PANEL SSH █${NC}"
echo ""
echo "  pm2 status              → ver servicios"
echo "  pm2 logs netgetk-bot    → logs del bot"
echo "  pm2 logs netgetk-license → logs del servidor"
echo "  pm2 restart netgetk-bot → reiniciar bot"
echo ""
source /opt/netgetk/config 2>/dev/null
echo -e "  ${CYAN}License Server:${NC} http://$MY_IP:$LIC_PORT"
echo ""
pm2 list --no-color | grep netgetk
echo ""
CMD
chmod +x /usr/local/bin/jitter

echo -e " ${CYAN}Usa el comando${NC} ${WHITE}jitter${NC} ${CYAN}para ver el estado del sistema${NC}"
echo ""
