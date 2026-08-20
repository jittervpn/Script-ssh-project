/* ============================================================
   JitterX Panel Cloud — panel
   ============================================================ */

const session = Session.requireAuth();
mountChrome();

let SUBS = [];
let LOG = [];
let filterText = "";
let filterState = "";

/* ---------- Iconos ---------- */
const iconSlots = { "i-grid": "grid", "i-globe": "globe", "i-pulse": "pulse", "i-cog": "cog", "i-book": "book", "i-shield": "shield", "i-search": "search" };
Object.keys(iconSlots).forEach(id => {
  const n = document.getElementById(id);
  if (n) n.outerHTML = ICONS[iconSlots[id]];
});
$("#logoutBtn").innerHTML = ICONS.out;

/* ---------- Identidad ---------- */
const me = session.user;
$("#userName").textContent = me.name || me.email.split("@")[0];
$("#userMail").textContent = me.email;
$("#userAvatar").textContent = (me.name || me.email)[0].toUpperCase();
if (me.role === "admin") $("#adminLink").hidden = false;

$("#logoutBtn").addEventListener("click", async () => {
  const ok = await confirmAction({
    title: "Cerrar sesión",
    message: "Volverás a la pantalla de acceso. Tus subdominios siguen activos.",
    confirmLabel: "Cerrar sesión"
  });
  if (ok) { Session.clear(); location.replace("index.html"); }
});

/* ---------- Navegación ---------- */
const TITLES = { overview: "Resumen", subdomains: "Subdominios", activity: "Actividad", settings: "Ajustes", help: "Ayuda" };

function go(view) {
  if (!TITLES[view]) view = "overview";
  $$(".view").forEach(v => v.hidden = v.id !== "view-" + view);
  $$(".nav-item[data-view]").forEach(n => n.classList.toggle("is-active", n.dataset.view === view));
  $("#viewTitle").textContent = TITLES[view];
  $("#searchWrap").hidden = view !== "subdomains";
  const side = $(".side"); if (side) side.classList.remove("is-open");
  history.replaceState(null, "", "#" + view);
  if (view === "activity") renderFullLog();
  if (view === "settings") renderSettings();
  if (view === "help") renderHelp();
}

$$(".nav-item[data-view]").forEach(n => {
  n.addEventListener("click", () => go(n.dataset.view));
  n.addEventListener("keydown", e => {
    if (e.key === "Enter" || e.key === " ") { e.preventDefault(); go(n.dataset.view); }
  });
});

$("#searchInput").addEventListener("input", e => { filterText = e.target.value.toLowerCase().trim(); renderZones(); });
$("#filterState").addEventListener("change", e => { filterState = e.target.value; renderZones(); });
$("#refreshBtn").addEventListener("click", () => load(true));
$("#newBtn").addEventListener("click", () => openCreate());

/* ---------- Carga ---------- */
async function load(notify) {
  try {
    const results = await Promise.all([
      API.listSubdomains(),
      API.activity().catch(() => ({ entries: [] }))
    ]);
    SUBS = results[0].subdomains || [];
    LOG = results[1].entries || [];
    renderAll();
    if (notify) toast("Lista actualizada", SUBS.length + " registro(s) en la zona.", "ok", 2000);
    warnExpiring();
  } catch (e) {
    $("#zoneList").innerHTML = "";
    toast("No se pudo cargar", e.message, "error", 6000);
  }
}

function renderAll() { renderStats(); renderZones(); renderSoon(); renderMiniLog(); renderQuota(); }

/* ---------- Resumen ---------- */
function renderStats() {
  const by = s => SUBS.filter(x => stateOf(x) === s).length;
  const soonest = SUBS.filter(s => msLeft(s.expiresAt) > 0)
    .sort((a, b) => msLeft(a.expiresAt) - msLeft(b.expiresAt))[0];

  const hour = new Date().getHours();
  const salute = hour < 6 ? "Buenas noches" : hour < 13 ? "Buenos días" : hour < 21 ? "Buenas tardes" : "Buenas noches";
  $("#greeting").textContent = salute + ", " + (me.name || me.email.split("@")[0]);

  const cards = [
    { label: "ACTIVOS", value: by("active"), note: "funcionando ahora mismo", accent: "var(--live)" },
    { label: "CADUCAN PRONTO", value: by("expiring"), note: "menos de " + CFG.renewalWindowDays + " días", accent: "var(--signal)" },
    { label: "PROPAGANDO", value: by("pending"), note: "esperando a los resolvers", accent: "var(--pulse)" },
    {
      label: "SIGUIENTE CADUCIDAD",
      value: soonest ? countdown(soonest.expiresAt) : "—",
      note: soonest ? soonest.fqdn : "nada programado",
      accent: "var(--paper-3)", small: true
    }
  ];

  $("#statsRow").innerHTML = cards.map(c =>
    '<div class="stat" style="--accent:' + c.accent + '">' +
      '<div class="stat__label">' + c.label + '</div>' +
      '<div class="stat__value"' + (c.small ? ' style="font-size:20px"' : '') + '>' + escapeHtml(String(c.value)) + '</div>' +
      '<div class="stat__note">' + escapeHtml(c.note) + '</div>' +
    '</div>').join("");
}

function renderQuota() {
  const active = SUBS.filter(s => msLeft(s.expiresAt) > 0).length;
  const max = CFG.maxSubdomainsPerUser;
  $("#quotaText").textContent = active + "/" + max;
  $("#quotaBar").style.width = Math.min(100, (active / max) * 100) + "%";
  $("#navCount").textContent = SUBS.length;
  const btn = $("#newBtn");
  btn.disabled = active >= max;
  btn.title = active >= max ? "Has llegado a tu cuota" : "";
}

function renderSoon() {
  const soon = SUBS.filter(s => msLeft(s.expiresAt) > 0)
    .sort((a, b) => msLeft(a.expiresAt) - msLeft(b.expiresAt)).slice(0, 4);
  $("#soonList").innerHTML = soon.length
    ? soon.map(s =>
        '<div class="log-line" style="align-items:center">' +
          '<span class="mono" style="flex:1;color:var(--paper)">' + escapeHtml(s.fqdn) + '</span>' +
          '<span class="tag ' + (stateOf(s) === "expiring" ? "tag--warn" : "tag--live") + '">' + countdown(s.expiresAt) + '</span>' +
        '</div>').join("")
    : '<p style="color:var(--paper-3);font-size:13.5px;margin:0">Todavía no tienes ningún subdominio en marcha.</p>';
}

const LOG_TEXT = {
  "account.created": "Cuenta creada",
  "session.opened": "Sesión iniciada",
  "subdomain.created": "Subdominio creado",
  "subdomain.renewed": "Subdominio renovado",
  "subdomain.released": "Subdominio liberado",
  "record.updated": "Registro modificado",
  "password.changed": "Contraseña cambiada",
  "user.updated": "Usuario modificado"
};
const logText = e => (LOG_TEXT[e.action] || e.action) + " · " + (e.detail || "");

function renderMiniLog() {
  const rows = LOG.slice(0, 5);
  $("#miniLog").innerHTML = rows.length
    ? rows.map(e => '<div class="log-line"><time>' + fmtDate(e.at) + '</time><span>' + escapeHtml(logText(e)) + '</span></div>').join("")
    : '<p style="color:var(--paper-3);font-size:13.5px;margin:0">Aún no hay movimientos.</p>';
}

function renderFullLog() {
  $("#fullLog").innerHTML = LOG.length
    ? LOG.map(e => '<div class="log-line"><time>' + fmtDate(e.at) + '</time><span>' + escapeHtml(logText(e)) + '</span></div>').join("")
    : '<div class="empty"><h3>Nada que contar todavía</h3><p>Cuando crees o renueves un subdominio aparecerá aquí.</p></div>';
}

/* ---------- Lista de zona ---------- */
function renderZones() {
  const list = SUBS.filter(s => {
    if (filterState && stateOf(s) !== filterState) return false;
    if (filterText && (s.fqdn + " " + s.value + " " + s.type + " " + (s.note || "")).toLowerCase().indexOf(filterText) === -1) return false;
    return true;
  });

  const host = $("#zoneList");

  if (!SUBS.length) {
    host.innerHTML =
      '<div class="empty">' +
        '<div class="empty__art">; ' + escapeHtml(CFG.rootDomain) + ' — tu zona está vacía\n;\n' +
        ';   nombre.' + escapeHtml(CFG.rootDomain) + '.   IN   A   0.0.0.0\n' +
        ';   esperando tu primer registro</div>' +
        '<h3>Reserva tu primer subdominio</h3>' +
        '<p>Elige un nombre, apúntalo a una IP o a un host, y estará vivo durante ' + CFG.trialDays + ' días.</p>' +
        '<button class="btn btn--primary" id="emptyCreateBtn">Crear subdominio</button>' +
      '</div>';
    const b = $("#emptyCreateBtn");
    if (b) b.addEventListener("click", () => openCreate());
    return;
  }

  if (!list.length) {
    host.innerHTML = '<div class="empty"><h3>Ningún resultado</h3><p>Prueba con otro nombre o cambia el filtro de estado.</p></div>';
    return;
  }

  const stateTag = {
    active:   '<span class="tag tag--live">activo</span>',
    expiring: '<span class="tag tag--warn">caduca pronto</span>',
    expired:  '<span class="tag tag--dead">caducado</span>',
    pending:  '<span class="tag tag--pulse">propagando</span>'
  };

  host.innerHTML = list.map(s => {
    const st = stateOf(s);
    const canRenew = msLeft(s.expiresAt) <= CFG.renewalWindowDays * DAY;
    const renewalsLeft = CFG.maxRenewals ? (CFG.maxRenewals - (s.renewals || 0)) : "∞";
    return '' +
    '<article class="zone" data-state="' + st + '" data-id="' + s.id + '">' +
      '<div>' +
        '<div class="zone__record">' +
          '<span class="zone__host"><b>' + escapeHtml(s.label) + '</b>.' + escapeHtml(CFG.rootDomain) + '.</span>' +
          '<span class="zone__type">' + escapeHtml(s.type) + '</span>' +
          '<span class="zone__value">' + escapeHtml(s.value) + '</span>' +
          '<span class="zone__comment">; TTL ' + (s.ttl || 300) + (s.proxied ? " · proxy on" : "") + '</span>' +
        '</div>' +
        '<div class="zone__meta">' +
          stateTag[st] +
          '<span class="tag tag--plain">' + t("expiresIn") + " " + countdown(s.expiresAt) + '</span>' +
          '<span class="tag tag--plain">renovaciones: ' + renewalsLeft + '</span>' +
          (s.note ? '<span class="tag tag--plain">' + escapeHtml(s.note) + '</span>' : '') +
        '</div>' +
      '</div>' +
      '<div class="zone__actions">' +
        ttlRing(s) +
        '<button class="icon-btn" data-act="copy" title="Copiar el host">' + ICONS.copy + '</button>' +
        '<button class="icon-btn" data-act="open" title="Abrir en el navegador">' + ICONS.ext + '</button>' +
        '<button class="icon-btn" data-act="edit" title="Editar el registro">' + ICONS.edit + '</button>' +
        '<button class="btn btn--sm ' + (canRenew ? "btn--primary" : "") + '" data-act="renew"' +
          (canRenew ? '' : ' disabled title="Podrás renovar cuando queden ' + CFG.renewalWindowDays + ' días"') + '>Renovar</button>' +
        '<button class="icon-btn" data-act="delete" title="Liberar" style="color:var(--alert)">' + ICONS.trash + '</button>' +
      '</div>' +
    '</article>';
  }).join("");

  $$(".zone [data-act]", host).forEach(btn => {
    btn.addEventListener("click", () => {
      const id = btn.closest(".zone").dataset.id;
      const sub = SUBS.filter(s => s.id === id)[0];
      const act = btn.dataset.act;
      if (act === "copy") copyText(sub.fqdn, "Host copiado");
      else if (act === "open") window.open("https://" + sub.fqdn, "_blank", "noopener");
      else if (act === "edit") openEdit(sub);
      else if (act === "renew") doRenew(sub);
      else if (act === "delete") doDelete(sub);
    });
  });
}

/* ---------- Crear ---------- */
function openCreate() {
  const types = CFG.recordTypes.map(x => '<option value="' + x + '">' + x + '</option>').join("");

  openModal({
    title: "Crear subdominio",
    wide: true,
    bodyHTML:
      '<div class="field">' +
        '<label class="field__label" for="c-label">Nombre del subdominio</label>' +
        '<div class="host-group">' +
          '<input class="input" id="c-label" placeholder="mi-proyecto" maxlength="' + CFG.maxLabelLength + '" autocomplete="off" spellcheck="false">' +
          '<span class="host-group__suffix">.' + escapeHtml(CFG.rootDomain) + '</span>' +
        '</div>' +
        '<p class="field__hint" id="c-avail">Letras, números y guiones. De ' + CFG.minLabelLength + ' a ' + CFG.maxLabelLength + ' caracteres.</p>' +
      '</div>' +
      '<div class="grid grid--2" style="gap:12px">' +
        '<div class="field"><label class="field__label" for="c-type">Tipo de registro</label>' +
          '<select class="select" id="c-type">' + types + '</select></div>' +
        '<div class="field"><label class="field__label" for="c-value">Destino</label>' +
          '<input class="input input--mono" id="c-value" placeholder="203.0.113.42" autocomplete="off" spellcheck="false"></div>' +
      '</div>' +
      '<div class="field"><label class="field__label" for="c-note">Nota (solo tú la ves)</label>' +
        '<input class="input" id="c-note" placeholder="Landing del cliente" maxlength="40"></div>' +
      '<label class="switch" id="c-proxy-wrap" style="margin:6px 0 16px">' +
        '<input type="checkbox" id="c-proxy" checked><span class="switch__track"></span>' +
        '<span style="font-size:13.5px">Pasar por el proxy de Cloudflare <span style="color:var(--paper-3)">— añade HTTPS y oculta tu IP</span></span>' +
      '</label>' +
      '<div class="console" style="box-shadow:none">' +
        '<div class="console__bar"><span>se escribirá en la zona</span></div>' +
        '<div class="console__body"><div class="console__line" id="c-preview"></div></div>' +
      '</div>' +
      '<p class="field__error" id="c-error" style="margin-top:12px"></p>' +
      '<div class="notice" style="margin-top:14px"><div>Caduca a los <strong>' + CFG.trialDays +
        '</strong> días. Te avisamos en el panel cuando queden ' + CFG.renewalWindowDays + ' días y podrás renovar en un clic.</div></div>',
    footerHTML:
      '<button class="btn btn--ghost" data-close>Cancelar</button>' +
      '<button class="btn btn--primary" id="c-submit">Crear subdominio</button>',
    onMount: (root, close) => {
      const label = $("#c-label", root), type = $("#c-type", root), value = $("#c-value", root);
      const proxy = $("#c-proxy", root), proxyWrap = $("#c-proxy-wrap", root);
      const preview = $("#c-preview", root), avail = $("#c-avail", root), err = $("#c-error", root);

      const placeholders = { A: "203.0.113.42", AAAA: "2606:4700::6810:85e5", CNAME: "mi-app.vercel.app", TXT: "verificacion=abc123" };

      const paint = () => {
        const l = label.value.trim().toLowerCase() || "nombre";
        const v = value.value.trim() || placeholders[type.value];
        const expires = new Date(Date.now() + CFG.trialDays * DAY).toLocaleDateString("es-ES");
        preview.innerHTML =
          '<span class="console__h">' + escapeHtml(l) + "." + escapeHtml(CFG.rootDomain) + '.</span>  ' +
          '<span class="console__c">300 IN</span> <span class="console__k">' + type.value + '</span> ' +
          '<span class="console__v">' + escapeHtml(v) + '</span> ' +
          '<span class="console__c">; caduca ' + expires + '</span>';
      };

      type.addEventListener("change", () => {
        value.placeholder = placeholders[type.value];
        const canProxy = ["A", "AAAA", "CNAME"].indexOf(type.value) !== -1;
        proxyWrap.style.opacity = canProxy ? "1" : ".4";
        proxy.disabled = !canProxy;
        paint();
      });
      value.addEventListener("input", paint);

      let timer;
      label.addEventListener("input", () => {
        label.value = label.value.toLowerCase().replace(/[^a-z0-9-]/g, "");
        paint();
        clearTimeout(timer);
        const check = validateLabel(label.value);
        if (!check.ok) {
          avail.textContent = label.value ? check.msg : "De " + CFG.minLabelLength + " a " + CFG.maxLabelLength + " caracteres.";
          avail.style.color = label.value ? "var(--alert)" : "var(--paper-3)";
          return;
        }
        avail.textContent = "Comprobando disponibilidad…";
        avail.style.color = "var(--paper-3)";
        timer = setTimeout(async () => {
          try {
            const r = await API.checkAvailability(check.value);
            avail.textContent = r.available
              ? check.value + "." + CFG.rootDomain + " está libre."
              : "Ese nombre ya está cogido. Prueba otro.";
            avail.style.color = r.available ? "var(--live)" : "var(--alert)";
          } catch (e) { avail.textContent = "No se pudo comprobar ahora mismo."; }
        }, 420);
      });

      paint();

      $("#c-submit", root).addEventListener("click", async () => {
        err.textContent = "";
        const l = validateLabel(label.value);
        if (!l.ok) { err.textContent = l.msg; label.focus(); return; }
        const v = validateRecord(type.value, value.value);
        if (!v.ok) { err.textContent = v.msg; value.focus(); return; }

        const btn = $("#c-submit", root);
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner"></span> Escribiendo en la zona…';
        try {
          const res = await API.createSubdomain({
            label: l.value, type: type.value, value: v.value,
            proxied: proxy.checked && !proxy.disabled,
            note: $("#c-note", root).value.trim()
          });
          close();
          toast("Subdominio creado", res.subdomain.fqdn + " propagando. Suele tardar menos de un minuto.", "ok", 6000);
          await load();
          go("subdomains");
        } catch (ex) {
          err.textContent = ex.message;
          btn.disabled = false;
          btn.textContent = "Crear subdominio";
        }
      });
    }
  });
}

/* ---------- Editar ---------- */
function openEdit(sub) {
  const types = CFG.recordTypes.map(x =>
    '<option value="' + x + '"' + (x === sub.type ? " selected" : "") + '>' + x + '</option>').join("");
  openModal({
    title: "Editar " + sub.fqdn,
    bodyHTML:
      '<dl class="kv" style="margin-bottom:18px">' +
        '<dt>host</dt><dd>' + escapeHtml(sub.fqdn) + '</dd>' +
        '<dt>creado</dt><dd>' + fmtDate(sub.createdAt) + '</dd>' +
        '<dt>caduca</dt><dd>' + fmtDate(sub.expiresAt) + '</dd>' +
        '<dt>id</dt><dd>' + escapeHtml(sub.recordId || sub.id) + '</dd>' +
      '</dl>' +
      '<div class="grid grid--2" style="gap:12px">' +
        '<div class="field"><label class="field__label" for="e-type">Tipo</label>' +
          '<select class="select" id="e-type">' + types + '</select></div>' +
        '<div class="field"><label class="field__label" for="e-value">Destino</label>' +
          '<input class="input input--mono" id="e-value" value="' + escapeHtml(sub.value) + '"></div>' +
      '</div>' +
      '<div class="field"><label class="field__label" for="e-note">Nota</label>' +
        '<input class="input" id="e-note" value="' + escapeHtml(sub.note || "") + '" maxlength="40"></div>' +
      '<label class="switch"><input type="checkbox" id="e-proxy"' + (sub.proxied ? " checked" : "") + '>' +
        '<span class="switch__track"></span><span style="font-size:13.5px">Proxy de Cloudflare</span></label>' +
      '<p class="field__error" id="e-error" style="margin-top:12px"></p>',
    footerHTML:
      '<button class="btn btn--ghost" data-close>Cancelar</button>' +
      '<button class="btn btn--primary" id="e-save">Guardar cambios</button>',
    onMount: (root, close) => {
      $("#e-save", root).addEventListener("click", async () => {
        const type = $("#e-type", root).value;
        const v = validateRecord(type, $("#e-value", root).value);
        if (!v.ok) { $("#e-error", root).textContent = v.msg; return; }
        const btn = $("#e-save", root);
        btn.disabled = true; btn.innerHTML = '<span class="spinner"></span> Guardando…';
        try {
          await API.updateSubdomain(sub.id, {
            type: type, value: v.value,
            proxied: $("#e-proxy", root).checked,
            note: $("#e-note", root).value.trim()
          });
          close();
          toast("Registro actualizado", sub.fqdn + " apunta ahora a " + v.value + ".", "ok");
          load();
        } catch (ex) {
          $("#e-error", root).textContent = ex.message;
          btn.disabled = false; btn.textContent = "Guardar cambios";
        }
      });
    }
  });
}

async function doRenew(sub) {
  try {
    const res = await API.renewSubdomain(sub.id);
    toast("Renovado", sub.fqdn + " vuelve a tener " + CFG.trialDays + " días. Caduca el " + fmtDate(res.subdomain.expiresAt) + ".", "ok", 5500);
    load();
  } catch (e) { toast("No se pudo renovar", e.message, "error", 6000); }
}

async function doDelete(sub) {
  const ok = await confirmAction({
    title: "Liberar " + sub.fqdn,
    message: "Se borra el registro de la zona y el nombre queda libre para cualquiera. No se puede deshacer.",
    confirmLabel: "Liberar subdominio",
    danger: true
  });
  if (!ok) return;
  try {
    await API.deleteSubdomain(sub.id);
    toast("Liberado", sub.fqdn + " ya no existe en la zona.", "warn");
    load();
  } catch (e) { toast("No se pudo liberar", e.message, "error", 6000); }
}

/* ---------- Ajustes ---------- */
function renderSettings() {
  $("#accountKv").innerHTML =
    '<dt>nombre</dt><dd>' + escapeHtml(me.name || "—") + '</dd>' +
    '<dt>correo</dt><dd>' + escapeHtml(me.email) + '</dd>' +
    '<dt>rol</dt><dd>' + (me.role === "admin" ? "administración" : "usuario") + '</dd>' +
    '<dt>cuota</dt><dd>' + CFG.maxSubdomainsPerUser + ' subdominios activos</dd>' +
    '<dt>duración</dt><dd>' + CFG.trialDays + ' días por subdominio</dd>' +
    '<dt>modo</dt><dd>' + (API.demo ? "demostración local" : "conectado a Cloudflare") + '</dd>';

  $("#prefTheme").checked = document.documentElement.dataset.theme === "light";
  $("#prefLang").checked = LANG === "en";
  $("#prefWarn").checked = localStorage.getItem("jx.warn") !== "0";
  $("#demoResetWrap").hidden = !API.demo;
}

$("#prefTheme").addEventListener("change", e => applyTheme(e.target.checked ? "light" : "dark"));
$("#prefLang").addEventListener("change", e => {
  setLang(e.target.checked ? "en" : "es");
  $("#langToggle").textContent = LANG.toUpperCase();
  renderAll();
});
$("#prefWarn").addEventListener("change", e => localStorage.setItem("jx.warn", e.target.checked ? "1" : "0"));

$("#pwForm").addEventListener("submit", async e => {
  e.preventDefault();
  const err = $("#pwError"); err.textContent = "";
  const cur = $("#pw-cur").value, next = $("#pw-new").value;
  if (next.length < 8) { err.textContent = "La nueva necesita 8 caracteres como mínimo."; return; }
  try {
    await API.changePassword({ current: cur, next: next });
    $("#pw-cur").value = ""; $("#pw-new").value = "";
    toast("Contraseña guardada", "Úsala en tu próximo acceso.", "ok");
  } catch (ex) { err.textContent = ex.message; }
});

$("#releaseAllBtn").addEventListener("click", async () => {
  if (!SUBS.length) { toast("Nada que liberar", "No tienes subdominios activos.", "info"); return; }
  const ok = await confirmAction({
    title: "Liberar todos",
    message: "Se borrarán " + SUBS.length + " registro(s) de la zona. No se puede deshacer.",
    confirmLabel: "Liberar todos", danger: true
  });
  if (!ok) return;
  for (const s of SUBS.slice()) { try { await API.deleteSubdomain(s.id); } catch (e) {} }
  toast("Zona limpia", "Se han liberado todos tus subdominios.", "warn");
  load();
});

$("#resetDemoBtn").addEventListener("click", async () => {
  const ok = await confirmAction({
    title: "Borrar la demostración",
    message: "Se borran las cuentas y subdominios de prueba guardados en este navegador.",
    confirmLabel: "Borrar datos", danger: true
  });
  if (!ok) return;
  API.resetDemo(); Session.clear(); location.replace("index.html");
});

/* ---------- Ayuda ---------- */
function renderHelp() {
  const faqs = [
    ["¿Cuánto dura mi subdominio?",
     CFG.trialDays + " días desde que lo creas. En el panel verás la cuenta atrás y podrás renovarlo cuando queden " + CFG.renewalWindowDays + " días o menos."],
    ["¿Qué pasa si caduca?",
     "El registro se borra de la zona y el nombre vuelve a estar libre. Puedes volver a pedirlo si nadie lo ha cogido antes."],
    ["¿Qué tipo de registro elijo?",
     "A si tienes una IPv4. AAAA para IPv6. CNAME si apuntas a un host como mi-app.vercel.app. TXT para verificar un servicio."],
    ["¿Para qué sirve el proxy naranja?",
     "Cloudflare se pone delante de tu servidor: te da HTTPS gratis, oculta la IP de origen y filtra tráfico malo. Actívalo salvo que necesites conexión directa."],
    ["Lo he creado y no funciona todavía",
     "Los cambios de DNS tardan en llegar a todos los resolvers. Suele ser menos de un minuto, pero dale hasta 5. Prueba en una ventana privada."],
    ["¿Puedo cambiar a dónde apunta?",
     "Sí, cuantas veces quieras. Pulsa el lápiz en la línea del subdominio y edita el destino."],
    ["¿Cuántos puedo tener?",
     CFG.maxSubdomainsPerUser + " activos a la vez. Si liberas uno, el hueco queda libre al momento."],
    ["Necesito ayuda con otra cosa",
     "Escribe a " + CFG.supportEmail + " indicando tu correo de la cuenta y el subdominio."]
  ];
  $("#helpGrid").innerHTML = faqs.map(f =>
    '<div class="card"><div class="card__title">' + escapeHtml(f[0]) + '</div>' +
    '<p style="margin:0;color:var(--paper-2);font-size:13.5px">' + escapeHtml(f[1]) + '</p></div>').join("");
}

/* ---------- Avisos y relojes ---------- */
function warnExpiring() {
  if (localStorage.getItem("jx.warn") === "0") return;
  const urgent = SUBS.filter(s => { const l = msLeft(s.expiresAt); return l > 0 && l < DAY; });
  if (urgent.length) {
    toast("Caduca en menos de 24 horas",
      urgent.map(s => s.fqdn).join(", ") + " — renueva antes de que se borre.", "warn", 9000);
  }
}

setInterval(() => {
  if (!$("#view-subdomains").hidden || !$("#view-overview").hidden) {
    renderZones(); renderStats(); renderSoon();
  }
}, 30000);

setInterval(() => { if (SUBS.some(s => stateOf(s) === "pending")) load(); }, 20000);

window.addEventListener("jx:lang", () => { renderAll(); renderHelp(); });

/* ---------- Arranque ---------- */
$("#zoneList").innerHTML = '<div class="skeleton"></div><div class="skeleton"></div><div class="skeleton"></div>';
go(location.hash.replace("#", "") || "overview");
load();
