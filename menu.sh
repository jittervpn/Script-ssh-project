#!/bin/bash
# Jitter SSH Manager Menu
# Compatible con Ubuntu 24

vermelho='\e[31m'; verde='\e[32m'; amarelo='\e[33m'; azul='\e[34m'; roxo='\e[35m'; reset='\e[0m'

[[ $EUID -ne 0 ]] && echo -e "${vermelho}Ejecutar como root: sudo menu${reset}" && exit 1

check_ws() {
    if ss -tulpn | grep -q ':80'; then
        echo -e "WebSocket: ${verde}ONLINE${reset} - Puerto 80"
    else
        echo -e "WebSocket: ${vermelho}OFFLINE${reset} - Puerto 80"
    fi
}

check_ssh() {
    if systemctl is-active --quiet sshd; then
        echo -e "SSH: ${verde}ONLINE${reset} - Puerto 22"
    else
        echo -e "SSH: ${vermelho}OFFLINE${reset} - Puerto 22"
    fi
}

crear_usuario() {
    clear
    echo -e "${azul}=== CREAR USUARIO SSH ===${reset}"
    read -p "Usuario: " usuario
    [[ -z $usuario ]] && echo "Usuario vacio" && sleep 2 && return
    read -p "Contraseña: " senha
    read -p "Dias para expirar: " dias
    read -p "Limite conexiones: " limite

    useradd -M -s /bin/false $usuario
    (echo $senha; echo $senha) | passwd $usuario > /dev/null 2>&1
    [[! -z $dias ]] && chage -E $(date -d "+$dias days" +%Y-%m-%d) $usuario
    [[! -z $limite ]] && echo "$usuario $limite" >> /root/usuarios.db

    echo -e "${verde}Usuario $usuario creado${reset}"
    [[! -z $dias ]] && echo "Expira en: $dias dias"
    [[! -z $limite ]] && echo "Limite: $limite conexiones"
    sleep 3
}

eliminar_usuario() {
    clear
    echo -e "${azul}=== ELIMINAR USUARIO ===${reset}"
    read -p "Usuario a eliminar: " usuario
    userdel -f $usuario > /dev/null 2>&1
    sed -i "/^$usuario /d" /root/usuarios.db
    pkill -u $usuario
    echo -e "${verde}Usuario $usuario eliminado${reset}"
    sleep 2
}

cambiar_banner() {
    clear
    echo -e "${azul}=== CAMBIAR BANNER SSH ===${reset}"
    echo "Pega tu banner. Ctrl+D para guardar:"
    cat > /etc/ssh/banner_jitter
    echo "Banner /etc/ssh/banner_jitter" >> /etc/ssh/sshd_config
    sed -i '/^Banner/d' /etc/ssh/sshd_config
    echo "Banner /etc/ssh/banner_jitter" >> /etc/ssh/sshd_config
    systemctl restart sshd
    echo -e "${verde}Banner actualizado${reset}"
    sleep 2
}

ver_conectados() {
    clear
    echo -e "${azul}=== USUARIOS CONECTADOS ===${reset}"
    data=( `ps aux | grep -i dropbear | awk '{print $1}'` )
    data2=( `ps aux | grep -i sshd | awk '{print $1}'` )
    echo -e "Usuario | Conexiones"
    echo "------------------------"
    for user in $(printf '%s\n' "${data[@]}" "${data2[@]}" | sort -u | grep -v root); do
        con=$(ps -u $user | grep sshd | wc -l)
        [[ $con -ne 0 ]] && echo -e "$user | $con"
    done
    echo ""
    read -p "Enter para volver..."
}

ver_usuarios() {
    clear
    echo -e "${azul}=== TODOS LOS USUARIOS ===${reset}"
    echo "Usuario | Expira | Limite"
    echo "--------------------------------"
    for user in $(awk -F: '$3 >= 1000 {print $1}' /etc/passwd | grep -v nobody); do
        exp=$(chage -l $user | grep "Account expires" | cut -d: -f2)
        lim=$(grep "^$user " /root/usuarios.db | cut -d' ' -f2)
        [[ -z $lim ]] && lim="∞"
        printf "%-12s|%-12s| %s\n" $user "$exp" $lim
    done
    echo ""
    read -p "Enter para volver..."
}

reiniciar_servicios() {
    clear
    echo -e "${amarelo}Reiniciando servicios...${reset}"
    systemctl restart sshd
    systemctl restart ws-http
    echo -e "${verde}SSH y WebSocket reiniciados${reset}"
    sleep 2
}

desinstalar() {
    clear
    read -p "¿Seguro que queres borrar todo? s/n: " resp
    [[ $resp!= "s" ]] && return
    systemctl stop ws-http
    systemctl disable ws-http
    rm -f /etc/systemd/system/ws-http.service
    rm -f /usr/bin/ws.py
    rm -f /usr/bin/menu
    systemctl daemon-reload
    echo -e "${verde}Desinstalado${reset}"
    exit 0
}

while true; do
    clear
    echo -e "${roxo}================================${reset}"
    echo -e "${roxo} JITTER SSH MANAGER${reset}"
    echo -e "${roxo}================================${reset}"
    check_ssh
    check_ws
    echo -e "${roxo}================================${reset}"
    echo -e "[1] ${verde}Crear Usuario SSH${reset}"
    echo -e "[2] ${vermelho}Eliminar Usuario${reset}"
    echo -e "[3] ${amarelo}Ver Usuarios Creados${reset}"
    echo -e "[4] ${azul}Usuarios Conectados${reset}"
    echo -e "[5] ${roxo}Cambiar Banner SSH${reset}"
    echo -e "[6] ${amarelo}Reiniciar Servicios${reset}"
    echo -e "[7] ${vermelho}Desinstalar Script${reset}"
    echo -e "[0] ${vermelho}Salir${reset}"
    echo -e "${roxo}================================${reset}"
    read -p "Opcion: " opcao

    case $opcao in
        1) crear_usuario ;;
        2) eliminar_usuario ;;
        3) ver_usuarios ;;
        4) ver_conectados ;;
        5) cambiar_banner ;;
        6) reiniciar_servicios ;;
        7) desinstalar ;;
        0) exit ;;
        *) echo -e "${vermelho}Opcion invalida${reset}"; sleep 1 ;;
    esac
done
