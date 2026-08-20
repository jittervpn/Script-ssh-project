/* ============================================================
   JitterX Panel Cloud — núcleo compartido
   Utilidades, idioma, tema, avisos, modales e iconos.
   ============================================================ */

const CFG = window.JITTERX;
const DAY = 86400000;

/* ---------- Atajos DOM ---------- */
const $  = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

function el(tag, attrs = {}, ...kids) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (v === null || v === undefined || v === false) continue;
    if (k === "class") node.className = v;
    else if (k === "html") node.innerHTML = v;
    else if (k.startsWith("on") && typeof v === "function") node.addEventListener(k.slice(2), v);
    else node.setAttribute(k, v);
  }
  kids.flat().forEach(k => node.append(k && k.nodeType ? k : document.createTextNode(String(k))));
  return node;
}

const escapeHtml = s => String(s).replace(/[&<>"']/g, c =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

/* ---------- Idioma ---------- */
const STRINGS = {
  es: {
    expiresIn: "caduca en", days: "d", hours: "h", minutes: "m",
    copied: "Copiado", renewals: "renovaciones"
  },
  en: {
    expiresIn: "expires in", days: "d", hours: "h", minutes: "m",
    copied: "Copied", renewals: "renewals"
  }
};

let LANG = localStorage.getItem("jx.lang") || CFG.defaultLang || "es";
const t = key => (STRINGS[LANG] && STRINGS[LANG][key]) || STRINGS.es[key] || key;

function setLang(lang) {
  LANG = lang;
  localStorage.setItem("jx.lang", lang);
  document.documentElement.lang = lang;
}

/* ---------- Tema ---------- */
function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  localStorage.setItem("jx.theme", theme);
  const btn = $("#themeToggle");
  if (btn) btn.innerHTML = theme === "dark" ? ICONS.sun : ICONS.moon;
}
function toggleTheme() {
  applyTheme(document.documentElement.dataset.theme === "dark" ? "light" : "dark");
}

/* ---------- Tiempo ---------- */
function msLeft(expiresAt) { return new Date(expiresAt).getTime() - Date.now(); }

function countdown(expiresAt) {
  let ms = msLeft(expiresAt);
  if (ms <= 0) return LANG === "es" ? "caducado" : "expired";
  const d = Math.floor(ms / DAY); ms -= d * DAY;
  const h = Math.floor(ms / 3600000); ms -= h * 3600000;
  const m = Math.floor(ms / 60000);
  const s = Math.floor((ms % 60000) / 1000);
  if (d > 0) return d + t("days") + " " + h + t("hours");
  if (h > 0) return h + t("hours") + " " + m + t("minutes");
  if (m > 0) return m + t("minutes") + " " + s + "s";
  return s + "s";
}

function stateOf(sub) {
  if (sub.status === "pending") return "pending";
  const left = msLeft(sub.expiresAt);
  if (left <= 0) return "expired";
  if (left <= CFG.renewalWindowDays * DAY) return "expiring";
  return "active";
}

function fmtDate(iso) {
  return new Date(iso).toLocaleString(LANG === "es" ? "es-ES" : "en-GB", {
    day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit"
  });
}

/* ---------- Validación ---------- */
function validateLabel(label) {
  const v = String(label || "").trim().toLowerCase();
  const es = LANG === "es";
  if (!v) return { ok: false, msg: es ? "Escribe un nombre." : "Enter a name." };
  if (v.length < CFG.minLabelLength)
    return { ok: false, msg: es ? "Mínimo " + CFG.minLabelLength + " caracteres." : "At least " + CFG.minLabelLength + " characters." };
  if (v.length > CFG.maxLabelLength)
    return { ok: false, msg: es ? "Máximo " + CFG.maxLabelLength + " caracteres." : "At most " + CFG.maxLabelLength + " characters." };
  if (!/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/.test(v))
    return { ok: false, msg: es
      ? "Solo letras, números y guiones. No puede empezar ni acabar en guión."
      : "Letters, numbers and hyphens only. Cannot start or end with a hyphen." };
  if (v.includes("--"))
    return { ok: false, msg: es ? "Sin guiones dobles." : "No double hyphens." };
  if (CFG.blockedLabels.includes(v))
    return { ok: false, msg: es ? "Ese nombre está reservado." : "That name is reserved." };
  return { ok: true, value: v };
}

function validateRecord(type, value) {
  const v = String(value || "").trim();
  const es = LANG === "es";
  if (!v) return { ok: false, msg: es ? "Indica el destino." : "Enter a target." };
  if (type === "A") {
    if (!/^(\d{1,3}\.){3}\d{1,3}$/.test(v))
      return { ok: false, msg: es ? "IPv4 no válida. Ejemplo: 203.0.113.42" : "Invalid IPv4. Example: 203.0.113.42" };
    if (v.split(".").some(o => Number(o) > 255))
      return { ok: false, msg: es ? "Cada bloque va de 0 a 255." : "Each block ranges 0-255." };
  }
  if (type === "AAAA" && !/^[0-9a-f:]+$/i.test(v))
    return { ok: false, msg: es ? "IPv6 no válida." : "Invalid IPv6." };
  if (type === "CNAME" && !/^[a-z0-9.-]+\.[a-z]{2,}$/i.test(v))
    return { ok: false, msg: es ? "Escribe un host, ej. mi-app.vercel.app" : "Enter a host, e.g. my-app.vercel.app" };
  if (type === "TXT" && v.length > 255)
    return { ok: false, msg: es ? "Máximo 255 caracteres." : "255 characters max." };
  return { ok: true, value: v };
}

function passwordScore(pw) {
  let s = 0;
  if (pw.length >= 8) s++;
  if (pw.length >= 12) s++;
  if (/[a-z]/.test(pw) && /[A-Z]/.test(pw)) s++;
  if (/\d/.test(pw)) s++;
  if (/[^\w\s]/.test(pw)) s++;
  return Math.min(s, 4);
}

/* ---------- Avisos ---------- */
function toast(title, body, kind, ms) {
  kind = kind || "info"; ms = ms || 4200;
  let host = $(".toasts");
  if (!host) { host = el("div", { class: "toasts" }); document.body.append(host); }
  const node = el("div", { class: "toast toast--" + kind, role: "status" },
    el("div", {}, el("strong", {}, title), body ? el("span", {}, body) : ""),
    el("button", { "aria-label": "Cerrar", onclick: () => node.remove(), html: "&times;" })
  );
  host.append(node);
  setTimeout(() => node.remove(), ms);
}

async function copyText(text, label) {
  try {
    await navigator.clipboard.writeText(text);
    toast(t("copied"), label || text, "ok", 2200);
  } catch (e) {
    toast(LANG === "es" ? "No se pudo copiar" : "Copy failed",
          LANG === "es" ? "Selecciona el texto y cópialo a mano." : "Select the text and copy manually.", "warn");
  }
}

/* ---------- Modales ---------- */
function openModal(opts) {
  const backdrop = el("div", { class: "modal-backdrop" });
  backdrop.innerHTML =
    '<div class="modal ' + (opts.wide ? "modal--wide" : "") + '" role="dialog" aria-modal="true">' +
      '<div class="modal__head"><h3>' + escapeHtml(opts.title) + '</h3>' +
      '<button class="icon-btn" data-close aria-label="Cerrar">' + ICONS.x + '</button></div>' +
      '<div class="modal__body">' + opts.bodyHTML + '</div>' +
      (opts.footerHTML ? '<div class="modal__foot">' + opts.footerHTML + '</div>' : '') +
    '</div>';
  document.body.append(backdrop);
  document.body.style.overflow = "hidden";

  const close = () => {
    backdrop.remove();
    document.body.style.overflow = "";
    document.removeEventListener("keydown", onKey);
  };
  const onKey = e => { if (e.key === "Escape") close(); };

  backdrop.addEventListener("click", e => { if (e.target === backdrop) close(); });
  $$("[data-close]", backdrop).forEach(b => b.addEventListener("click", close));
  document.addEventListener("keydown", onKey);
  const first = $(".modal input, .modal select, .modal button", backdrop);
  if (first) first.focus();

  if (opts.onMount) opts.onMount(backdrop, close);
  return { root: backdrop, close: close };
}

function confirmAction(opts) {
  return new Promise(resolve => {
    let settled = false;
    const done = v => { if (!settled) { settled = true; resolve(v); } };
    openModal({
      title: opts.title,
      bodyHTML: '<p style="margin:0;color:var(--paper-2);font-size:14px">' + escapeHtml(opts.message) + '</p>',
      footerHTML:
        '<button class="btn btn--ghost" data-close>' + (LANG === "es" ? "Cancelar" : "Cancel") + '</button>' +
        '<button class="btn ' + (opts.danger ? "btn--danger" : "btn--primary") + '" data-ok>' + escapeHtml(opts.confirmLabel) + '</button>',
      onMount: (root, closeFn) => {
        $("[data-ok]", root).addEventListener("click", () => { closeFn(); done(true); });
        root.addEventListener("click", e => { if (e.target === root) done(false); });
        $$("[data-close]", root).forEach(b => b.addEventListener("click", () => done(false)));
        document.addEventListener("keydown", function esc(e) {
          if (e.key === "Escape") { document.removeEventListener("keydown", esc); done(false); }
        });
      }
    });
  });
}

/* ---------- Iconos ---------- */
const ICONS = {
  grid:   '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></svg>',
  globe:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.7 2.5 15.3 0 18M12 3c-2.5 2.7-2.5 15.3 0 18"/></svg>',
  pulse:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 12h4l3-8 4 16 3-8h4"/></svg>',
  cog:    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="3.2"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.2 5.2l1.4 1.4M17.4 17.4l1.4 1.4M18.8 5.2l-1.4 1.4M6.6 17.4l-1.4 1.4"/></svg>',
  book:   '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 5a2 2 0 0 1 2-2h13v18H6a2 2 0 0 0-2 2z"/><path d="M4 19a2 2 0 0 1 2-2h13"/></svg>',
  shield: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 3l7 3v6c0 4.5-3 8-7 9-4-1-7-4.5-7-9V6z"/><path d="M9.5 12l1.8 1.8L15 10"/></svg>',
  x:      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 6l12 12M18 6L6 18"/></svg>',
  search: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>',
  copy:   '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/></svg>',
  trash:  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 7h16M10 11v6M14 11v6"/><path d="M6 7l1 12a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-12M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/></svg>',
  edit:   '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 20h4L20 8a2.8 2.8 0 0 0-4-4L4 16z"/></svg>',
  ext:    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M14 4h6v6M20 4l-9 9"/><path d="M18 14v5a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h5"/></svg>',
  sun:    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4"/></svg>',
  moon:   '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5z"/></svg>',
  menu:   '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 7h16M4 12h16M4 17h16"/></svg>',
  out:    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3"/><path d="M10 17l-5-5 5-5M5 12h10"/></svg>'
};

/* ---------- Anillo de caducidad ---------- */
function ttlRing(sub) {
  const total = (sub.totalMs && sub.totalMs > 0) ? sub.totalMs : CFG.trialDays * DAY;
  const left = Math.max(0, msLeft(sub.expiresAt));
  const pct = Math.max(0, Math.min(1, left / total));
  const r = 19, c = 2 * Math.PI * r;
  const days = Math.max(0, Math.ceil(left / DAY));
  return '<div class="ttl-ring" title="' + countdown(sub.expiresAt) + '">' +
    '<svg width="46" height="46" viewBox="0 0 46 46">' +
      '<circle class="ttl-ring__bg" cx="23" cy="23" r="' + r + '"></circle>' +
      '<circle class="ttl-ring__fg" cx="23" cy="23" r="' + r + '" stroke-dasharray="' + c.toFixed(1) +
      '" stroke-dashoffset="' + ((1 - pct) * c).toFixed(1) + '"></circle>' +
    '</svg>' +
    '<div class="ttl-ring__num">' + (left <= 0 ? "0" : days) + '</div></div>';
}

/* ---------- Sesión ---------- */
const Session = {
  get() {
    try { return JSON.parse(localStorage.getItem("jx.session") || "null"); }
    catch (e) { return null; }
  },
  set(s) { localStorage.setItem("jx.session", JSON.stringify(s)); },
  clear() { localStorage.removeItem("jx.session"); },
  requireAuth() {
    const s = this.get();
    if (!s || !s.token) { location.replace("index.html"); return null; }
    return s;
  }
};

/* ---------- Cabecera común ---------- */
function mountChrome() {
  const themeBtn = $("#themeToggle");
  if (themeBtn) {
    themeBtn.innerHTML = document.documentElement.dataset.theme === "dark" ? ICONS.sun : ICONS.moon;
    themeBtn.addEventListener("click", toggleTheme);
  }
  const langBtn = $("#langToggle");
  if (langBtn) {
    langBtn.textContent = LANG.toUpperCase();
    langBtn.addEventListener("click", () => {
      setLang(LANG === "es" ? "en" : "es");
      langBtn.textContent = LANG.toUpperCase();
      window.dispatchEvent(new CustomEvent("jx:lang"));
    });
  }
  const burger = $("#sideToggle");
  if (burger) {
    burger.innerHTML = ICONS.menu;
    burger.addEventListener("click", () => {
      const side = $(".side");
      if (side) side.classList.toggle("is-open");
    });
  }
  $$("[data-brand-name]").forEach(n => n.textContent = CFG.brandName);
  $$("[data-root-domain]").forEach(n => n.textContent = CFG.rootDomain);
  $$("[data-trial-days]").forEach(n => n.textContent = CFG.trialDays);
  $$("[data-renew-days]").forEach(n => n.textContent = CFG.renewalWindowDays);
}

applyTheme(localStorage.getItem("jx.theme") || CFG.defaultTheme || "dark");
document.documentElement.lang = LANG;
