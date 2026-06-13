#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ui.sh"

require_root() {
  if [[ $EUID -ne 0 ]]; then
    error "Esta opción requiere permisos de administrador. Usa: sudo jitter-vpn"
    return 1
  fi
}

ssh_service() {
  systemctl list-unit-files ssh.service >/dev/null 2>&1 && printf 'ssh' || printf 'sshd'
}

service_state() {
  local service
  service="$(ssh_service)"
  systemctl is-active --quiet "$service" && printf "${GREEN}ACTIVO${RESET}" || printf "${RED}INACTIVO${RESET}"
}

system_summary() {
  local ip memory users uptime_text
  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  memory="$(free -m | awk '/Mem:/ {printf "%s/%s MB", $3, $2}')"
  users="$(awk -F: '$3 >= 1000 && $7 !~ /(nologin|false)$/ {count++} END {print count+0}' /etc/passwd)"
  uptime_text="$(uptime -p 2>/dev/null | sed 's/^up /activo /')"

  printf " ${GRAY}HOST${RESET}  ${WHITE}%-18s${RESET} ${GRAY}IP${RESET}    ${WHITE}%s${RESET}\n" "$(hostname)" "${ip:-sin detectar}"
  printf " ${GRAY}RAM${RESET}   ${WHITE}%-18s${RESET} ${GRAY}SSH${RESET}   %b\n" "$memory" "$(service_state)"
  printf " ${GRAY}USERS${RESET} ${WHITE}%-18s${RESET} ${GRAY}UPTIME${RESET} ${WHITE}%s${RESET}\n" "$users" "$uptime_text"
  line
}

valid_username() {
  [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,30}$ ]]
}

create_user() {
  require_root || return
  local username
  read -rp "Nombre del nuevo usuario: " username
  if ! valid_username "$username"; then
    error "Nombre no válido. Usa minúsculas, números, guion o guion bajo."
    return
  fi
  if id "$username" >/dev/null 2>&1; then
    error "El usuario ya existe."
    return
  fi
  useradd --create-home --shell /bin/bash "$username"
  info "Define una contraseña para $username:"
  passwd "$username"
  success "Usuario $username creado."
}

list_users() {
  printf "${BOLD}${WHITE}Usuarios con acceso de shell${RESET}\n\n"
  printf "${GRAY}%-20s %-10s %-24s${RESET}\n" "USUARIO" "ESTADO" "ÚLTIMO ACCESO"
  while IFS=: read -r username _ uid _ _ _ shell; do
    if (( uid >= 1000 )) && [[ ! "$shell" =~ (nologin|false)$ ]]; then
      local state last_login
      passwd -S "$username" 2>/dev/null | grep -q ' L ' && state="bloqueado" || state="activo"
      last_login="$(lastlog -u "$username" 2>/dev/null | awk 'NR==2 {$1=""; sub(/^ +/, ""); print}' | cut -c1-24)"
      printf "%-20s %-10s %-24s\n" "$username" "$state" "${last_login:-sin registro}"
    fi
  done </etc/passwd
}

toggle_user() {
  require_root || return
  local username action
  read -rp "Usuario: " username
  if ! id "$username" >/dev/null 2>&1 || [[ "$username" == "root" ]]; then
    error "Usuario no válido o protegido."
    return
  fi
  passwd -S "$username" | grep -q ' L ' && action="desbloquear" || action="bloquear"
  if confirm "¿Quieres $action a $username?"; then
    [[ "$action" == "bloquear" ]] && usermod -L "$username" || usermod -U "$username"
    success "Usuario actualizado."
  fi
}

delete_user() {
  require_root || return
  local username
  read -rp "Usuario a eliminar: " username
  if ! id "$username" >/dev/null 2>&1 || [[ "$username" == "root" ]]; then
    error "Usuario no válido o protegido."
    return
  fi
  if confirm "Se borrará $username y su carpeta personal. ¿Continuar?"; then
    userdel --remove "$username"
    success "Usuario eliminado."
  fi
}

manage_service() {
  require_root || return
  local service option
  service="$(ssh_service)"
  printf "1) Iniciar  2) Reiniciar  3) Detener  4) Activar al arrancar\n"
  read -rp "Acción: " option
  case "$option" in
    1) systemctl start "$service" ;;
    2) systemctl restart "$service" ;;
    3) confirm "¿Detener SSH? Tu sesión remota podría cerrarse." && systemctl stop "$service" ;;
    4) systemctl enable "$service" ;;
    *) error "Opción no válida."; return ;;
  esac
  success "Servicio SSH actualizado."
}

show_logs() {
  local service
  service="$(ssh_service)"
  journalctl -u "$service" --since "24 hours ago" --no-pager -n 40 2>/dev/null || \
    tail -n 40 /var/log/auth.log 2>/dev/null || error "No se encontraron registros."
}

main_menu() {
  while true; do
    header
    system_summary
    printf " ${CYAN}[1]${RESET} Crear usuario SSH       ${CYAN}[5]${RESET} Servicio OpenSSH\n"
    printf " ${CYAN}[2]${RESET} Listar usuarios         ${CYAN}[6]${RESET} Ver registro reciente\n"
    printf " ${CYAN}[3]${RESET} Bloquear / desbloquear  ${CYAN}[7]${RESET} Información del sistema\n"
    printf " ${CYAN}[4]${RESET} Eliminar usuario        ${ORANGE}[0]${RESET} Salir\n"
    line
    printf "${ORANGE}${BOLD} jitter@vpn ${RESET}${GRAY}›${RESET} "
    read -r option
    printf "\n"
    case "$option" in
      1) create_user; pause ;;
      2) list_users; pause ;;
      3) toggle_user; pause ;;
      4) delete_user; pause ;;
      5) manage_service; pause ;;
      6) show_logs; pause ;;
      7) system_summary; pause ;;
      0) printf "${CYAN}Hasta pronto.${RESET}\n"; exit 0 ;;
      *) error "Selecciona una opción del 0 al 7."; sleep 1 ;;
    esac
  done
}

trap 'printf "\n"; error "La operación se interrumpió en la línea $LINENO."' ERR
main_menu