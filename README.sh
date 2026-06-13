# Jitter VPN

Consola Bash para administrar de forma sencilla un servidor **OpenSSH** en Ubuntu, Debian, Fedora, Rocky Linux o AlmaLinux. El nombre es de marca: esta versión administra SSH y no crea una VPN ni modifica el cortafuegos.

## Funciones

- Panel de estado del servidor, IP, memoria y tiempo activo.
- Crear, listar, bloquear, desbloquear y eliminar usuarios de shell.
- Iniciar, reiniciar, detener y activar OpenSSH al arrancar.
- Consultar los últimos eventos del servicio SSH.
- Validación de nombres, confirmación para operaciones destructivas y protección de `root`.

## Archivos

```text
jitter-vpn/
├── jitter-vpn.sh
├── install.sh
├── lib/
│   └── ui.sh
└── README.md
```

## Instalación

```bash
git clone https://github.com/jittervpn/jitter-vpn.git
cd jitter-vpn
chmod +x install.sh jitter-vpn.sh
sudo ./install.sh
```

Después ejecuta:

```bash
sudo jitter-vpn
```

También puedes probarlo sin instalarlo:

```bash
sudo ./jitter-vpn.sh
```

## Seguridad

- Revisa el código antes de ejecutarlo como `root`.
- Mantén OpenSSH y el sistema actualizados.
- Para servidores públicos, usa llaves SSH y desactiva contraseñas solo después de comprobar que el acceso por llave funciona.
- No cierres o detengas SSH mientras dependas de la misma sesión remota.

## Licencia

Puedes usar y modificar este proyecto. Añade la licencia que prefieras antes de publicarlo.