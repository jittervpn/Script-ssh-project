#!/bin/bash
while true; do
clear
IP=$(hostname -I | awk '{print $1}')
echo "==== JITTER VPS MANAGER ===="
echo "IP: $IP"
echo
bash /opt/jitter-manager/menu.sh
done
