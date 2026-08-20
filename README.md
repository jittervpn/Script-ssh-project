# JitterX Panel Cloud

Panel para que cualquiera reserve un subdominio de **tu** dominio de Cloudflare, lo apunte a donde quiera y lo gestione durante 7 días.

```
mi-proyecto.tudominio.com.   300 IN   A   203.0.113.42   ; caduca en 6d 21h
```

---

## Qué hay en el ZIP

| Carpeta | Qué es | Dónde va |
|---|---|---|
| `index.html`, `dashboard.html`, `admin.html`, `assets/` | El panel que ve la gente | GitHub Pages |
| `worker/` | La API que guarda tu token y escribe en Cloudflare | Cloudflare Workers |

**El token de Cloudflare nunca va en la web.** GitHub Pages es público: si lo pones ahí, cualquiera podría borrar toda tu zona DNS. Por eso existe el Worker.

---

## Parte 1 — Publicar el panel (5 minutos)

Esto ya funciona solo, en **modo demostración**: guarda los datos en el navegador de cada visitante y no toca DNS de verdad. Sirve para ver el panel y enseñarlo.

1. Crea un repositorio en GitHub, por ejemplo `jitterx-panel`.
2. Sube el contenido del ZIP. Los HTML deben quedar en la raíz del repo, no dentro de una subcarpeta.
3. En el repo: **Settings → Pages → Source: Deploy from a branch → main / (root) → Save**.
4. En un minuto tendrás `https://TU-USUARIO.github.io/jitterx-panel/`.

Cuenta de prueba del modo demostración:

```
admin@tudominio.com  /  jitterx2024
```

Se cambian en `assets/js/config.js`.

---

## Parte 2 — Conectarlo a Cloudflare de verdad

### 2.1 Consigue los tres datos

**Zone ID**: Cloudflare → tu dominio → en la portada, columna derecha, *Zone ID*.

**Token de API**: Cloudflare → *My Profile* → *API Tokens* → *Create Token* → plantilla **Edit zone DNS**.

- Permissions: `Zone` · `DNS` · `Edit`
- Zone Resources: `Include` · `Specific zone` · **tu dominio**

Copia el token. Solo se muestra una vez.

**Secreto de sesión**: cualquier cadena larga y aleatoria.

```bash
openssl rand -hex 32
```

### 2.2 Despliega el Worker

```bash
cd worker
npm install -g wrangler
wrangler login

# Crear el almacén
wrangler kv namespace create DB
```

Pega el `id` que te devuelve en `wrangler.toml`, en `[[kv_namespaces]]`.

Edita también `[vars]`:

```toml
ROOT_DOMAIN = "tudominio.com"
ALLOWED_ORIGIN = "https://TU-USUARIO.github.io"
ADMIN_EMAILS = "tu@correo.com"
```

Guarda los secretos (te los pide por teclado, no quedan en ningún archivo):

```bash
wrangler secret put CF_API_TOKEN
wrangler secret put CF_ZONE_ID
wrangler secret put SESSION_SECRET
```

Y despliega:

```bash
wrangler deploy
```

Te dará una URL tipo `https://jitterx-api.tu-cuenta.workers.dev`.

### 2.3 Enchufa el panel al Worker

Abre `assets/js/config.js` y rellena:

```js
rootDomain: "tudominio.com",
apiBase: "https://jitterx-api.tu-cuenta.workers.dev",
```

Sube el cambio a GitHub. El panel deja el modo demostración y empieza a escribir registros reales.

El primer correo que aparezca en `ADMIN_EMAILS` entrará como administración al registrarse.

---

## Lo que puede hacer el usuario

- Crear subdominios con registros **A, AAAA, CNAME o TXT**
- Activar el **proxy de Cloudflare** (HTTPS gratis, IP de origen oculta)
- Ver la **cuenta atrás** de cada subdominio con su anillo de caducidad
- **Renovar** en un clic cuando queden 3 días o menos
- **Editar** a dónde apunta el registro cuantas veces quiera
- **Liberar** un subdominio antes de tiempo
- Comprobar **disponibilidad** del nombre mientras escribe
- Añadir una **nota privada** a cada subdominio
- Buscar y filtrar por estado
- Ver su **historial de actividad**
- Cambiar la contraseña
- Cambiar entre **tema oscuro y claro** y entre **español e inglés**
- Aviso automático si algo caduca en menos de 24 horas

## Lo que puedes hacer tú (administración)

- Panel con usuarios, registros activos y ocupación de cuota
- Gráfico de **caducidades de los próximos 7 días**
- Suspender y reactivar cuentas
- Borrar cualquier registro
- Auditoría de todos los movimientos
- **Exportar a CSV** todos los registros

---

## Ajustes rápidos — `assets/js/config.js`

```js
trialDays: 7,                // días que dura cada subdominio
maxSubdomainsPerUser: 3,     // cuota por cuenta
renewalWindowDays: 3,        // cuándo se activa el botón de renovar
maxRenewals: 4,              // renovaciones por subdominio (0 = sin límite)
recordTypes: ["A","AAAA","CNAME","TXT"],
blockedLabels: [ ... ]       // nombres que nadie puede coger
```

Cambia lo mismo en `worker/wrangler.toml` para que el servidor aplique las mismas reglas. **El servidor manda**: si alguien manipula el navegador, el Worker sigue validando.

---

## Seguridad incluida

- Contraseñas con PBKDF2, 150 000 iteraciones y sal por usuario
- Sesiones firmadas con HMAC-SHA256, caducan a los 7 días
- Límite de intentos: 12 accesos / 15 min y 5 registros / hora por IP
- CORS restringido a tu dominio con `ALLOWED_ORIGIN`
- Lista de nombres reservados (`www`, `mail`, `api`, `admin`, `dkim`…) para que nadie secuestre tu correo o tus servicios
- Validación de todos los registros en el servidor, no solo en el navegador
- El cron borra de la zona lo caducado cada hora

---

## Personalizar la marca

Nombre, correo de soporte y dominio están en `assets/js/config.js`.
Los colores están arriba del todo en `assets/css/styles.css`, en `:root`.

## Preguntas frecuentes

**¿Necesito servidor propio?** No. GitHub Pages y Cloudflare Workers tienen plan gratuito de sobra para esto.

**¿Puedo usar otro hosting?** Sí, es HTML estático: Netlify, Vercel, Cloudflare Pages, lo que quieras.

**¿Y si no quiero registro abierto?** Borra el formulario de crear cuenta en `index.html` y registra tú las cuentas.

**Un subdominio no resuelve.** Dale hasta 5 minutos y prueba en ventana privada. Si el proxy está activo, el registro apunta a Cloudflare, no a tu IP: es normal.
