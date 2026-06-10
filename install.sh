```bash
#!/bin/bash

# Colores
CIAN='\033[1;36m'
VERDE='\033[1;32m'
ROJO='\033[1;31m'
NC='\033[0m'

# Verificar root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${ROJO}❌ Ejecuta este script como root${NC}"
    exit 1
fi

echo -e "${CIAN}🔄 Actualizando sistema...${NC}"
apt update -y
apt upgrade -y

echo -e "${CIAN}📦 Instalando dependencias...${NC}"
apt install -y openssh-server net-tools curl wget iptables ufw libpam-time-guard git

echo -e "${CIAN}📂 Descargando archivos...${NC}"
mkdir -p /opt/ssh-admin
cd /opt/ssh-admin || exit 1

# Descargar archivos del repositorio
curl -fsSL -o ssh-admin.sh https://raw.githubusercontent.com/TU_USUARIO/Script-ssh-project/main/ssh-admin.sh
curl -fsSL -o funciones.sh https://raw.githubusercontent.com/TU_USUARIO/Script-ssh-project/main/funciones.sh

chmod +x *.sh

echo -e "${VERDE}✅ Instalación finalizada${NC}"
echo -e "${CIAN}▶️ Ejecuta con: sudo /opt/ssh-admin/ssh-admin.sh${NC}"

# Ejecutar automáticamente
exec /opt/ssh-admin/ssh-admin.sh
