#!/bin/bash
awk -F: '$3>=1000{print $1}' /etc/passwd; read -p "ENTER..."
