#!/bin/bash
# ============================================
#   JITTER SSH MANAGER
# ============================================

# Colores
R="\033[1;31m"; V="\033[1;32m"; A="\033[1;33m"; AZ="\033[1;34m"; M="\033[1;35m"; C="\033[1;36m"; B="\033[1;37m"; N="\033[0m"

[ "$EUID" -ne 0 ] && { echo -e "${R}Ejecutá como root${N}"; exit 1; }

pausa(){ echo ""; read -p "Presioná ENTER para continuar..."; }

# -------- CREAR USUARIO SSH --------
crear_usuario(){
  clear
  echo -e "${A}===== CREAR USUARIO SSH =====${N}"
  read -p "Usuario: " user
  read -p "Contraseña: " pass
  read -p "Días de duración: " dias
  read -p "Límite de conexiones: " limite

  if id "$user" &>/dev/null; then
    echo -e "${R}El usuario ya existe${N}"; pausa; return
  fi

  exp=$(date -d "+${dias} days" +%Y-%m-%d)
  useradd -M -s /bin/false -e "$exp" "$user"
  echo "$user:$pass" | chpasswd

  mkdir -p /etc/JitterVPN
  echo "$user $limite" >> /etc/JitterVPN/usuarios.db

  IP=$(curl -4 -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
  echo ""
  echo -e "${V}✅ Usuario creado${N}"
  echo -e "${B}Usuario:${N} $user"
  echo -e "${B}Pass:${N} $pass"
  echo -e "${B}Expira:${N} $exp"
  echo -e "${B}Límite:${N} $limite"
  echo -e "${B}IP:${N} $IP"
  pausa
}

# -------- ELIMINAR USUARIO --------
eliminar_usuario(){
  clear
  echo -e "${A}===== ELIMINAR USUARIO =====${N}"
  read -p "Usuario a eliminar: " user
  if id "$user" &>/dev/null; then
    pkill -KILL -u "$user" 2>/dev/null
    userdel -r "$user" 2>/dev/null
    sed -i "/^$user /d" /etc/JitterVPN/usuarios.db 2>/dev/null
    echo -e "${V}✅ Usuario $user eliminado${N}"
  else
    echo -e "${R}No existe${N}"
  fi
  pausa
}

# -------- LISTAR USUARIOS --------
listar_usuarios(){
  clear
  echo -e "${A}===== USUARIOS SSH =====${N}"
  awk -F: '$3>=1000 && $1!="nobody"{print $1" -> Expira: "}' /etc/passwd | while read line; do
    u=$(echo "$line" | awk '{print $1}')
    exp=$(chage -l "$u" 2>/dev/null | grep "Account expires" | cut -d: -f2)
    echo -e "${B}$u${N} | Expira:$exp"
  done
  pausa
}

# -------- INSTALAR DROPBEAR --------
instalar_dropbear(){
  clear
  echo -e "${A}===== INSTALAR DROPBEAR =====${N}"
  read -p "Puerto Dropbear (ej 444): " p1
  read -p "Puerto Dropbear extra (ej 80): " p2
  apt-get update -y
  apt-get install -y dropbear
  sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
  sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$p1/" /etc/default/dropbear
  sed -i "s/DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS=\"-p $p2\"/" /etc/default/dropbear
  grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
  grep -q "/usr/sbin/nologin" /etc/shells || echo "/usr/sbin/nologin" >> /etc/shells
  systemctl restart dropbear
  systemctl enable dropbear
  echo -e "${V}✅ Dropbear instalado en puertos $p1 y $p2${N}"
  pausa
}

# -------- INSTALAR PROXY PYTHON (WEBSOCKET) --------
instalar_proxy_python(){
  clear
  echo -e "${A}===== INSTALAR PROXY PYTHON =====${N}"
  read -p "Puerto del proxy (ej 8080): " pport
  apt-get install -y python3

  cat > /usr/local/bin/jitter-proxy.py <<'PYEOF'
#!/usr/bin/env python3
import socket, threading, sys, select
LISTENING_ADDR='0.0.0.0'
try: LISTENING_PORT=int(sys.argv[1])
except: LISTENING_PORT=8080
PASS=''
BUFLEN=8196*8
TIMEOUT=60
DEFAULT_HOST='127.0.0.1:22'
RESPONSE='HTTP/1.1 101 <b>JitterVPN</b>\r\n\r\n'

class Server(threading.Thread):
    def __init__(self,host,port):
        threading.Thread.__init__(self)
        self.running=False
        self.host=host; self.port=port
        self.threads=[]
        self.threadsLock=threading.Lock()
        self.logLock=threading.Lock()
    def run(self):
        self.soc=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        self.soc.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
        self.soc.settimeout(2)
        self.soc.bind((self.host,self.port))
        self.soc.listen(0)
        self.running=True
        while self.running:
            try:
                c,addr=self.soc.accept(); c.setblocking(1)
            except socket.timeout: continue
            conn=ConnectionHandler(c,self,addr); conn.start()
            self.addConn(conn)
        self.soc.close()
    def addConn(self,conn):
        with self.threadsLock:
            if self.running: self.threads.append(conn)
    def removeConn(self,conn):
        with self.threadsLock: self.threads.remove(conn)

class ConnectionHandler(threading.Thread):
    def __init__(self,sClient,server,addr):
        threading.Thread.__init__(self)
        self.client=sClient; self.clientClosed=False
        self.targetClosed=True; self.server=server
        self.clientBuffer=''
    def close(self):
        try:
            if not self.clientClosed: self.client.shutdown(socket.SHUT_RDWR); self.client.close()
        except: pass
        self.clientClosed=True
        try:
            if not self.targetClosed: self.target.shutdown(socket.SHUT_RDWR); self.target.close()
        except: pass
        self.targetClosed=True
    def run(self):
        try:
            self.clientBuffer=self.client.recv(BUFLEN).decode(errors='ignore')
            hostPort=self.findHeader(self.clientBuffer,'X-Real-Host')
            if hostPort=='': hostPort=DEFAULT_HOST
            split=self.findHeader(self.clientBuffer,'X-Split')
            if split!='': self.client.recv(BUFLEN)
            if hostPort!='':
                passwd=self.findHeader(self.clientBuffer,'X-Pass')
                if len(PASS)!=0 and passwd==PASS: self.method_CONNECT(hostPort)
                elif len(PASS)!=0 and passwd!=PASS: self.client.send(b'HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith('localhost'): self.method_CONNECT(hostPort)
                else: self.client.send(b'HTTP/1.1 403 Forbidden!\r\n\r\n')
            else: self.client.send(b'HTTP/1.1 400 NoXRH!\r\n\r\n')
        except Exception: pass
        finally: self.close(); self.server.removeConn(self)
    def findHeader(self,head,header):
        aux=head.find(header+': ')
        if aux==-1: return ''
        aux=head.find(':',aux); head=head[aux+2:]
        aux=head.find('\r\n')
        if aux==-1: return ''
        return head[:aux]
    def connect_target(self,host):
        i=host.find(':')
        if i!=-1: port=int(host[i+1:]); host=host[:i]
        else: port=22
        (soc_family,_,_,_,address)=socket.getaddrinfo(host,port)[0]
        self.target=socket.socket(soc_family,socket.SOCK_STREAM); self.targetClosed=False
        self.target.connect(address)
    def method_CONNECT(self,path):
        self.connect_target(path)
        self.client.sendall(RESPONSE.encode())
        self.clientBuffer=''; self.doCONNECT()
    def doCONNECT(self):
        socs=[self.client,self.target]; count=0; error=False
        while True:
            count+=1
            (recv,_,err)=select.select(socs,[],socs,3)
            if err: error=True
            if recv:
                for in_ in recv:
                    try:
                        data=in_.recv(BUFLEN)
                        if data:
                            if in_ is self.target: self.client.send(data)
                            else:
                                while data: byte=self.target.send(data); data=data[byte:]
                            count=0
                        else: break
                    except: error=True; break
            if count==TIMEOUT: error=True
            if error: break

def main():
    print(f"Proxy en {LISTENING_ADDR}:{LISTENING_PORT}")
    server=Server(LISTENING_ADDR,LISTENING_PORT); server.start()
    while True:
        try: import time; time.sleep(2)
        except KeyboardInterrupt: server.running=False; break

if __name__=='__main__': main()
PYEOF

  chmod +x /usr/local/bin/jitter-proxy.py

  cat > /etc/systemd/system/jitter-proxy.service <<EOF
[Unit]
Description=Jitter Proxy Python
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/jitter-proxy.py $pport
Restart=always
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable jitter-proxy
  systemctl restart jitter-proxy
  echo -e "${V}✅ Proxy Python corriendo en puerto $pport${N}"
  pausa
}

# -------- ESTADO SERVICIOS --------
estado(){
  clear
  echo -e "${A}===== ESTADO DE SERVICIOS =====${N}"
  for s in ssh dropbear jitter-proxy; do
    if systemctl is-active --quiet $s; then
      echo -e "$s: ${V}ACTIVO${N}"
    else
      echo -e "$s: ${R}INACTIVO${N}"
    fi
  done
  pausa
}

# -------- MENÚ PRINCIPAL --------
while true; do
  clear
  IP=$(hostname -I | awk '{print $1}')
  echo -e "${A}==================================${N}"
  echo -e "${A}       JITTER SSH MANAGER${N}"
  echo -e "${A}==================================${N}"
  echo -e "${B} IP:${N} $IP"
  echo -e "${A}----------------------------------${N}"
  echo -e " ${V}1)${N} Crear usuario SSH"
  echo -e " ${V}2)${N} Eliminar usuario"
  echo -e " ${V}3)${N} Listar usuarios"
  echo -e "${A}----------------------------------${N}"
  echo -e " ${C}4)${N} Instalar Dropbear"
  echo -e " ${C}5)${N} Instalar Proxy Python (WebSocket)"
  echo -e " ${C}6)${N} Estado de servicios"
  echo -e "${A}----------------------------------${N}"
  echo -e " ${R}0)${N} Salir"
  echo -e "${A}==================================${N}"
  read -p "Elegí una opción: " op
  case $op in
    1) crear_usuario ;;
    2) eliminar_usuario ;;
    3) listar_usuarios ;;
    4) instalar_dropbear ;;
    5) instalar_proxy_python ;;
    6) estado ;;
    0) clear; exit 0 ;;
    *) echo -e "${R}Opción inválida${N}"; sleep 1 ;;
  esac
done
