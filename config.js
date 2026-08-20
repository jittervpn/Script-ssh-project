/* ============================================================
   JitterX Panel Cloud — CONFIGURACIÓN
   Este es el único archivo que necesitas tocar para poner
   el panel en marcha. Todo lo demás funciona solo.
   ============================================================ */

window.JITTERX = {

  /* --- Marca ------------------------------------------------ */
  brandName: "JitterX Panel Cloud",
  brandShort: "JitterX",
  supportEmail: "soporte@tudominio.com",

  /* --- Tu dominio de Cloudflare ----------------------------- */
  // Sin punto delante. El usuario pedirá "algo.tudominio.com".
  rootDomain: "tudominio.com",

  /* --- Backend ---------------------------------------------- */
  // URL del Worker de Cloudflare, SIN barra final. Ejemplo:
  //   "https://jitterx-api.tu-cuenta.workers.dev"
  // Mientras esté vacío, el panel funciona en MODO DEMOSTRACIÓN:
  // guarda todo en el navegador y no toca DNS de verdad.
  apiBase: "",

  /* --- Reglas del servicio ---------------------------------- */
  trialDays: 7,              // duración de cada subdominio
  maxSubdomainsPerUser: 3,   // cuota por cuenta
  renewalWindowDays: 3,      // se puede renovar cuando queden <= X días
  maxRenewals: 4,            // renovaciones por subdominio (0 = sin límite)
  minLabelLength: 3,
  maxLabelLength: 24,

  // Tipos de registro que puede elegir el usuario
  recordTypes: ["A", "AAAA", "CNAME", "TXT"],

  // Etiquetas que nadie puede reservar
  blockedLabels: [
    "www", "mail", "smtp", "imap", "pop", "ftp", "ns", "ns1", "ns2",
    "admin", "root", "api", "cdn", "dev", "test", "staging", "panel",
    "cpanel", "webmail", "vpn", "git", "blog", "shop", "app", "dash",
    "cloudflare", "jitterx", "support", "billing", "login", "secure",
    "autodiscover", "autoconfig", "mx", "dkim", "dmarc", "spf"
  ],

  /* --- Interfaz --------------------------------------------- */
  defaultTheme: "dark",      // "dark" | "light"
  defaultLang: "es",         // "es" | "en"

  // Cuenta de administración del modo demostración
  // (en producción manda ADMIN_EMAILS del Worker)
  demoAdminEmail: "admin@tudominio.com",
  demoAdminPassword: "jitterx2024"
};
