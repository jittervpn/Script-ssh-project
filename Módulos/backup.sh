#!/bin/bash
mkdir -p /root/backups; tar -czf /root/backups/home.tar.gz /home 2>/dev/null; echo "Backup creado"; read -p "ENTER..."
