#!/bin/bash

while true; do
  clear
  echo "================================="
  echo "     JITTER SSH MANAGER"
  echo "================================="
  echo "1) Opción de prueba"
  echo "0) Salir"
  echo "================================="
  read -p "Elegí una opción: " opcion

  case "$opcion" in
    1)
      echo "Funciona el menú"
      read -p "Presioná Enter para continuar..."
      ;;
    0)
      exit 0
      ;;
    *)
      echo "Opción inválida"
      read -p "Presioná Enter para continuar..."
      ;;
  esac
done
