#!/bin/bash
# ================================================================
#   JITTER PANEL SSH - Deploy a GitHub
#   Actualiza la URL del servidor y sube todo al repo
#   Ejecutar DESPUÉS de install-admin.sh
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
      ██║██║   ██║      ██║   █████╗  ██████╔╝
 ██   ██║██║   ██║      ██║   ██╔══╝  ██╔══██╗
 ╚█████╔╝██║   ██║      ██║   ███████╗██║  ██║
  ╚════╝ ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝
LOGO
echo -e "${PINK}     █ DEPLOY GITHUB - JITTER PANEL v3.1 █${NC}"
echo -e "${VIOLET}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── Leer config instalada ─────────────────────────────────────
if [[ -f /opt/netgetk/config ]]; then
    source /opt/netgetk/config
    echo -e " ${GREEN}✓${NC} ${WHITE}Config cargada${NC}"
    echo -e "   ${BLUE}License Server:${NC} ${CYAN}$LICENSE_SERVER_URL${NC}"
else
    echo -e "${YELLOW}[!] Ejecuta install-admin.sh primero${NC}"
    echo -ne " ${BLUE}▸${NC} ${WHITE}O ingresa la URL de tu servidor: ${NC}"
    read LICENSE_SERVER_URL
fi

echo ""

# ── Verificar que existe el directorio del proyecto ───────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETUP_FILE="$SCRIPT_DIR/script/setup"

if [[ ! -f "$SETUP_FILE" ]]; then
    echo -e "${RED}[!] No encuentro script/setup${NC}"
    echo -e "    ${GRAY}Asegúrate de ejecutar desde la carpeta del proyecto${NC}"
    exit 1
fi

# ── Actualizar URL en script/setup ────────────────────────────
echo -e "${PINK}[1/4]${NC} ${WHITE}Actualizando URL del servidor en script/setup...${NC}"
sed -i "s|LICENSE_SERVER=\".*\"|LICENSE_SERVER=\"$LICENSE_SERVER_URL\"|" "$SETUP_FILE"
loading_bar 0.3 "URL actualizada"

# ── Verificar git ─────────────────────────────────────────────
if ! command -v git &>/dev/null; then
    echo -e "${PINK}[2/4]${NC} ${WHITE}Instalando git...${NC}"
    apt install -y git -q &> /dev/null &
    spinner $!
fi

# ── Configurar git si no está ─────────────────────────────────
if [[ -z "$(git config --global user.email)" ]]; then
    echo ""
    echo -e "${PINK}[2/4]${NC} ${WHITE}Configurar Git${NC}"
    echo -ne " ${BLUE}▸${NC} ${WHITE}Tu nombre [JITTER]: ${NC}"; read GIT_NAME
    echo -ne " ${BLUE}▸${NC} ${WHITE}Tu email: ${NC}"; read GIT_EMAIL
    git config --global user.name "${GIT_NAME:-JITTER}"
    git config --global user.email "${GIT_EMAIL:-admin@jitter.com}"
    echo -e " ${GREEN}✓${NC} Git configurado"
fi

# ── Verificar GitHub CLI ───────────────────────────────────────
echo ""
echo -e "${PINK}[3/4]${NC} ${WHITE}Verificando GitHub CLI...${NC}"
if ! command -v gh &>/dev/null; then
    echo -e " ${BLUE}▸${NC} ${WHITE}Instalando GitHub CLI...${NC}"
    (curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update -q && apt install -y gh) &> /dev/null &
    spinner $!
fi

# ── Login en GitHub ───────────────────────────────────────────
if ! gh auth status &>/dev/null; then
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE} Necesitas autenticarte en GitHub${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e " ${CYAN}Pasos:${NC}"
    echo -e "  ${GRAY}1.${NC} Ve a ${WHITE}https://github.com/settings/tokens/new${NC}"
    echo -e "  ${GRAY}2.${NC} Note: 'jitter-deploy'"
    echo -e "  ${GRAY}3.${NC} Expiration: No expiration"
    echo -e "  ${GRAY}4.${NC} Marca: ✅ repo"
    echo -e "  ${GRAY}5.${NC} Clic 'Generate token'"
    echo -e "  ${GRAY}6.${NC} Copia el token que empieza con ghp_..."
    echo ""
    echo -ne " ${BLUE}▸${NC} ${WHITE}Pega tu GitHub Token: ${NC}"
    read GH_TOKEN
    echo "$GH_TOKEN" | gh auth login --with-token &> /dev/null
fi

GH_USER=$(gh api user --jq '.login' 2>/dev/null)
echo -e " ${GREEN}✓${NC} ${WHITE}Conectado como:${NC} ${CYAN}$GH_USER${NC}"

# ── Subir a GitHub ────────────────────────────────────────────
echo ""
echo -e "${PINK}[4/4]${NC} ${WHITE}Subiendo a GitHub...${NC}"
cd "$SCRIPT_DIR"

# Crear .gitignore
cat > .gitignore << 'GI'
node_modules/
*.env
data/
*.log
.DS_Store
GI

# Inicializar repo si no existe
if [[ ! -d .git ]]; then
    git init &> /dev/null
    git add . &> /dev/null
    git commit -m "JITTER PANEL SSH v3.1 - Initial commit" &> /dev/null
    
    REPO_NAME="JITTER-Script"
    echo -e " ${BLUE}▸${NC} ${WHITE}Creando repositorio $GH_USER/$REPO_NAME...${NC}"
    gh repo create "$REPO_NAME" --public --source=. --push &> /dev/null &
    spinner $!
else
    git add . &> /dev/null
    git commit -m "Update - $(date '+%Y-%m-%d %H:%M')" &> /dev/null
    echo -e " ${BLUE}▸${NC} ${WHITE}Haciendo push...${NC}"
    git push &> /dev/null &
    spinner $!
fi

RAW_BASE="https://raw.githubusercontent.com/$GH_USER/JITTER-Script/main"
INSTALL_CMD="apt update -y && wget -q $RAW_BASE/script/setup && chmod +x setup && ./setup"

echo ""
echo -e "${VIOLET}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${VIOLET}║${NC}           ${WHITE}✓ SUBIDO A GITHUB EXITOSAMENTE${NC}                 ${VIOLET}║${NC}"
echo -e "${VIOLET}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}📦 Repo:${NC} ${CYAN}https://github.com/$GH_USER/JITTER-Script${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${VIOLET}║${NC}  ${WHITE}Comando de instalación para clientes:${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}║${NC}  ${CYAN}$INSTALL_CMD${NC}"
echo -e "${VIOLET}║${NC}"
echo -e "${VIOLET}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e " ${YELLOW}Ahora en Telegram escribe /genkey para crear tu primera licencia${NC}"
echo ""
