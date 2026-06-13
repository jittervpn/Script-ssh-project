#!/usr/bin/env bash

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[38;5;51m'
BLUE='\033[38;5;39m'
ORANGE='\033[38;5;214m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;245m'

line() {
  printf "${BLUE}%*s${RESET}\n" "${COLUMNS:-72}" '' | tr ' ' '─'
}

pause() {
  printf "\n${GRAY}Pulsa Enter para continuar...${RESET}"
  read -r
}

success() { printf "${GREEN}✓ %s${RESET}\n" "$1"; }
error() { printf "${RED}✗ %s${RESET}\n" "$1" >&2; }
info() { printf "${CYAN}• %s${RESET}\n" "$1"; }

confirm() {
  local answer
  printf "${ORANGE}%s [s/N]: ${RESET}" "$1"
  read -r answer
  [[ "$answer" =~ ^[sS]$ ]]
}

header() {
  clear
  printf "${CYAN}${BOLD}"
  cat <<'EOF'
       ╭─────────────────────────────────────────╮
       │      ██╗██╗████████╗████████╗███████╗   │
       │       ██║██║╚══██╔══╝╚══██╔══╝██╔════╝   │
       │       ██║██║   ██║      ██║   █████╗     │
       │  ██   ██║██║   ██║      ██║   ██╔══╝     │
       │  ╚█████╔╝██║   ██║      ██║   ███████╗   │
       │   ╚════╝ ╚═╝   ╚═╝      ╚═╝   ╚══════╝   │
       ╰────────────── JITTER VPN ───────────────╯
EOF
  printf "${RESET}"
  printf "${DIM}${WHITE}             Consola segura de OpenSSH${RESET}\n"
  line
}