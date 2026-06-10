#!/bin/bash
# ================================================================
#   JITTER PANEL SSH - Actualizador de Repositorio GitHub
#   Sincroniza los archivos activos del VPS al repo git
#   y hace push a GitHub.
#
#   Uso: bash repo.sh
#   Ejecutar desde: ~/NETGETK-Script
# ================================================================

# COLORES JITTER THEME
PURPLE='\033[0;35m'; VIOLET='\033[1;35m'; PINK='\033[1;95m'
CYAN='\033[0;96m'; BLUE='\033[0;94m'; GREEN='\033[0;92m'
YELLOW='\033[1;93m'; RED='\033[0;91m'; WHITE='\033[1;97m'
GRAY='\033[0;90m'; NC='\033[0m'

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/etc/gtkvpn"

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
      ██║██║   ██║      ██║   █████╗  ██████╔╝
 ██   ██║██║   ██║      ██║   ██╔══╝  ██╔══██╗
 ╚█████╔╝██║   ██║      ██║   ███████╗██║  ██║
  ╚════╝ ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝
LOGO
echo -e "${PINK}     █ REPO UPDATER - JITTER PANEL v3.1 █${NC}"
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Verificar que estamos en el repo correcto
if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo -e "${RED}[!] No es un repositorio git. Ejecuta desde ~/NETGETK-Script${NC}"
    exit 1
fi

cd "$REPO_DIR"

# ── Paso 1: Copiar archivos activos al repo ───────────────────
echo -e "${PINK}[1/4]${NC} ${WHITE}Copiando archivos activos al repositorio...${NC}"
echo ""

FILES_COPIED=0

copy_file() {
    local SRC="$1"
    local DST="$2"
    if [[ -f "$SRC" ]]; then
        cp "$SRC" "$DST" && \
        echo -e "  ${GREEN}✓${NC} ${CYAN}$(basename $DST)${NC}" && \
        ((FILES_COPIED++))
    else
        echo -e "  ${YELLOW}~${NC} ${GRAY}$(basename $DST) (no existe)${NC}"
    fi
}

# Archivos del directorio activo -> repo
copy_file "$INSTALL_DIR/manager"              "$REPO_DIR/script/manager"
copy_file "$INSTALL_DIR/setup"                "$REPO_DIR/script/setup"
copy_file "$INSTALL_DIR/banner.sh"            "$REPO_DIR/script/banner.sh"
copy_file "$INSTALL_DIR/Server/vaydns.sh"     "$REPO_DIR/script/Server/vaydns.sh"
copy_file "$INSTALL_DIR/Server/hysteria.sh"   "$REPO_DIR/script/Server/hysteria.sh"
copy_file "$INSTALL_DIR/Server/ssh.sh"        "$REPO_DIR/script/Server/ssh.sh"
copy_file "$INSTALL_DIR/Server/ssl.sh"        "$REPO_DIR/script/Server/ssl.sh"
copy_file "$INSTALL_DIR/Server/udp.sh"        "$REPO_DIR/script/Server/udp.sh"
copy_file "$INSTALL_DIR/Server/slowdns.sh"    "$REPO_DIR/script/Server/slowdns.sh"
copy_file "$INSTALL_DIR/Server/socks5.sh"     "$REPO_DIR/script/Server/socks5.sh"
copy_file "$INSTALL_DIR/Server/xray.sh"       "$REPO_DIR/script/Server/xray.sh"
copy_file "$INSTALL_DIR/back/usuarios.sh"     "$REPO_DIR/script/back/usuarios.sh"
copy_file "$INSTALL_DIR/back/firewall.sh"     "$REPO_DIR/script/back/firewall.sh"
copy_file "$INSTALL_DIR/back/contador.sh"     "$REPO_DIR/script/back/contador.sh"
copy_file "$INSTALL_DIR/back/optimizador.sh"  "$REPO_DIR/script/back/optimizador.sh"
copy_file "$INSTALL_DIR/back/speedtest.sh"    "$REPO_DIR/script/back/speedtest.sh"

echo ""

# ── Paso 2: Verificar permisos de ejecucion ───────────────────
echo -e "${PINK}[2/4]${NC} ${WHITE}Verificando permisos...${NC}"
loading_bar 0.4 "Asignando permisos +x"
find "$REPO_DIR/script" -name "*.sh" -exec chmod +x {} \;
chmod +x "$REPO_DIR/script/manager" "$REPO_DIR/script/setup" 2>/dev/null

# ── Paso 3: Ver cambios antes de commit ───────────────────────
echo -e "${PINK}[3/4]${NC} ${WHITE}Cambios detectados:${NC}"
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
git status --short | while read line; do
    if [[ $line == M* ]]; then
        echo -e " ${YELLOW}M${NC} ${CYAN}${line:3}${NC}"
    elif [[ $line == A* ]]; then
        echo -e " ${GREEN}A${NC} ${CYAN}${line:3}${NC}"
    elif [[ $line == D* ]]; then
        echo -e " ${RED}D${NC} ${CYAN}${line:3}${NC}"
    else
        echo -e " ${GRAY}${line}${NC}"
    fi
done
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Si no hay cambios, salir
if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
    echo -e "${YELLOW}[!] No hay cambios nuevos para subir${NC}"
    exit 0
fi

# ── Paso 4: Commit y push ─────────────────────────────────────
echo -e "${PINK}[4/4]${NC} ${WHITE}Subiendo a GitHub...${NC}"
echo ""

# Mensaje de commit con fecha
COMMIT_MSG="update: sync VPS changes $(date '+%Y-%m-%d %H:%M')"
echo -ne " ${BLUE}▸${NC} ${WHITE}Mensaje de commit [Enter = automatico]: ${NC}"
read CUSTOM_MSG
[[ -n "$CUSTOM_MSG" ]] && COMMIT_MSG="$CUSTOM_MSG"

git add -A
git commit -m "$COMMIT_MSG" &> /dev/null

echo -e " ${BLUE}▸${NC} ${WHITE}Haciendo push a origin master...${NC}"
git push origin master &> /dev/null &
spinner $!

if [[ $? -eq 0 ]]; then
    echo ""
    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}           ${WHITE}✓ REPO ACTUALIZADO CORRECTAMENTE${NC}              ${VIOLET}║${NC}"
    echo -e "${VIOLET}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${VIOLET}║${NC}"
    echo -e "${VIOLET}║${NC}  ${WHITE}📦 Archivos subidos:${NC} ${CYAN}$FILES_COPIED${NC}"
    echo -e "${VIOLET}║${NC}  ${WHITE}📝 Commit:${NC} ${CYAN}$COMMIT_MSG${NC}"
    echo -e "${VIOLET}║${NC}  ${WHITE}🔗 Repo:${NC} ${CYAN}$(git remote get-url origin)${NC}"
    echo -e "${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}           ${WHITE}✗ ERROR AL HACER PUSH${NC}                         ${RED}║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${RED}║${NC}  ${WHITE}Verifica tu token de GitHub:${NC}"
    echo -e "${RED}║${NC}  ${CYAN}git remote set-url origin https://TOKEN@github.com/user/repo.git${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
fi
