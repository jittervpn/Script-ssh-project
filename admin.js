/* ============================================================
   JitterX Panel Cloud — administración
   ============================================================ */

const session = Session.requireAuth();
mountChrome();

if (session.user.role !== "admin") {
  toast("Sin permiso", "Esta sección es solo para administración.", "error");
  setTimeout(() => location.replace("dashboard.html"), 1500);
}

const searchIcon = document.getElementById("i-search");
if (searchIcon) searchIcon.outerHTML = ICONS.search;

$("#userName").textContent = session.user.name || session.user.email;
$("#userMail").textContent = session.user.email;
$("#userAvatar").textContent = (session.user.name || session.user.email)[0].toUpperCase();

let DATA = { users: [], subdomains: [], log: [] };
let q = "";

const TITLES = { pulse: "Estado del servicio", users: "Usuarios", records: "Todos los registros", audit: "Auditoría" };

function go(view) {
  $$(".view").forEach(v => v.hidden = v.id !== "view-" + view);
  $$(".nav-item[data-view]").forEach(n => n.classList.toggle("is-active", n.dataset.view === view));
  $("#viewTitle").textContent = TITLES[view];
  const side = $(".side"); if (side) side.classList.remove("is-open");
}
$$(".nav-item[data-view]").forEach(n => n.addEventListener("click", () => go(n.dataset.view)));

$("#adminSearch").addEventListener("input", e => {
  q = e.target.value.toLowerCase().trim();
  renderUsers(); renderRecords();
});

async function load() {
  try {
    DATA = await API.adminData();
    renderStats(); renderChart(); renderUsers(); renderRecords(); renderAudit();
  } catch (e) {
    toast("No se pudo cargar", e.message, "error", 6000);
  }
}

function renderStats() {
  const subs = DATA.subdomains;
  const active = subs.filter(s => msLeft(s.expiresAt) > 0).length;
  const soon = subs.filter(s => { const l = msLeft(s.expiresAt); return l > 0 && l <= CFG.renewalWindowDays * DAY; }).length;
  const newUsers = DATA.users.filter(u => Date.now() - new Date(u.createdAt).getTime() < 7 * DAY).length;
  const capacity = Math.max(1, DATA.users.length * CFG.maxSubdomainsPerUser);

  const cards = [
    { l: "USUARIOS", v: DATA.users.length, n: newUsers + " esta semana", a: "var(--pulse)" },
    { l: "REGISTROS ACTIVOS", v: active, n: "de " + subs.length + " creados en total", a: "var(--live)" },
    { l: "CADUCAN PRONTO", v: soon, n: "en " + CFG.renewalWindowDays + " días o menos", a: "var(--signal)" },
    { l: "OCUPACIÓN", v: Math.round((active / capacity) * 100) + "%", n: "de la cuota repartida", a: "var(--paper-3)" }
  ];
  $("#adminStats").innerHTML = cards.map(c =>
    '<div class="stat" style="--accent:' + c.a + '">' +
      '<div class="stat__label">' + c.l + '</div>' +
      '<div class="stat__value">' + c.v + '</div>' +
      '<div class="stat__note">' + c.n + '</div></div>').join("");
}

function renderChart() {
  const buckets = [];
  for (let i = 0; i < 7; i++) {
    const from = Date.now() + i * DAY, to = from + DAY;
    buckets.push({
      day: new Date(from).toLocaleDateString("es-ES", { weekday: "short", day: "numeric" }),
      count: DATA.subdomains.filter(s => {
        const e = new Date(s.expiresAt).getTime();
        return e >= from && e < to;
      }).length
    });
  }
  const max = Math.max(1, ...buckets.map(b => b.count));
  $("#expiryChart").innerHTML =
    '<div style="display:flex;gap:10px;align-items:flex-end;height:150px;padding-top:8px">' +
    buckets.map(b =>
      '<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:7px;height:100%;justify-content:flex-end">' +
        '<span class="mono" style="font-size:12px;color:var(--paper-2)">' + b.count + '</span>' +
        '<div style="width:100%;height:' + Math.max(3, (b.count / max) * 100) + '%;border-radius:6px 6px 2px 2px;' +
        'background:linear-gradient(180deg,var(--signal),rgba(255,176,32,.25))"></div>' +
        '<span class="mono" style="font-size:10.5px;color:var(--paper-3)">' + b.day + '</span>' +
      '</div>').join("") + '</div>';
}

function renderUsers() {
  const rows = DATA.users.filter(u => !q ||
    u.email.toLowerCase().indexOf(q) !== -1 || (u.name || "").toLowerCase().indexOf(q) !== -1);

  $("#usersTable").innerHTML =
    '<thead><tr><th>Usuario</th><th>Alta</th><th>Subdominios</th><th>Rol</th><th>Estado</th><th></th></tr></thead><tbody>' +
    rows.map(u => {
      const count = DATA.subdomains.filter(s => s.userId === u.id && msLeft(s.expiresAt) > 0).length;
      return '<tr>' +
        '<td><div style="font-weight:600">' + escapeHtml(u.name || "—") + '</div>' +
        '<div class="mono" style="color:var(--paper-3)">' + escapeHtml(u.email) + '</div></td>' +
        '<td class="mono">' + fmtDate(u.createdAt) + '</td>' +
        '<td class="mono">' + count + '/' + CFG.maxSubdomainsPerUser + '</td>' +
        '<td>' + (u.role === "admin" ? '<span class="tag tag--pulse">admin</span>' : '<span class="tag tag--plain">usuario</span>') + '</td>' +
        '<td>' + (u.suspended ? '<span class="tag tag--dead">suspendido</span>' : '<span class="tag tag--live">activo</span>') + '</td>' +
        '<td style="text-align:right"><button class="btn btn--sm ' + (u.suspended ? "" : "btn--danger") +
          '" data-user="' + u.id + '" data-susp="' + (u.suspended ? "0" : "1") + '">' +
          (u.suspended ? "Reactivar" : "Suspender") + '</button></td></tr>';
    }).join("") + '</tbody>';

  $$("#usersTable [data-user]").forEach(b => b.addEventListener("click", async () => {
    try {
      await API.adminUser(b.dataset.user, { suspended: b.dataset.susp === "1" });
      toast("Usuario actualizado",
        b.dataset.susp === "1" ? "La cuenta queda suspendida." : "La cuenta vuelve a estar activa.", "ok");
      load();
    } catch (e) { toast("No se pudo actualizar", e.message, "error"); }
  }));
}

function renderRecords() {
  const rows = DATA.subdomains.filter(s => !q ||
    s.fqdn.toLowerCase().indexOf(q) !== -1 || (s.userEmail || "").toLowerCase().indexOf(q) !== -1);
  const tags = { active: "tag--live", expiring: "tag--warn", expired: "tag--dead", pending: "tag--pulse" };
  const names = { active: "activo", expiring: "caduca pronto", expired: "caducado", pending: "propagando" };

  $("#recordsTable").innerHTML =
    '<thead><tr><th>Host</th><th>Tipo</th><th>Destino</th><th>Propietario</th><th>Caduca</th><th>Estado</th><th></th></tr></thead><tbody>' +
    rows.map(s => {
      const st = stateOf(s);
      return '<tr>' +
        '<td class="mono" style="color:var(--paper)">' + escapeHtml(s.fqdn) + '</td>' +
        '<td><span class="zone__type">' + escapeHtml(s.type) + '</span></td>' +
        '<td class="mono">' + escapeHtml(s.value) + '</td>' +
        '<td class="mono">' + escapeHtml(s.userEmail || "—") + '</td>' +
        '<td class="mono">' + countdown(s.expiresAt) + '</td>' +
        '<td><span class="tag ' + tags[st] + '">' + names[st] + '</span></td>' +
        '<td style="text-align:right"><button class="btn btn--sm btn--danger" data-del="' + s.id + '">Borrar</button></td>' +
      '</tr>';
    }).join("") + '</tbody>';

  $$("#recordsTable [data-del]").forEach(b => b.addEventListener("click", async () => {
    const sub = DATA.subdomains.filter(s => s.id === b.dataset.del)[0];
    const ok = await confirmAction({
      title: "Borrar " + sub.fqdn,
      message: "El registro se elimina de la zona y el usuario lo pierde. No se puede deshacer.",
      confirmLabel: "Borrar registro", danger: true
    });
    if (!ok) return;
    try { await API.deleteSubdomain(sub.id); toast("Registro borrado", sub.fqdn, "warn"); load(); }
    catch (e) { toast("No se pudo borrar", e.message, "error"); }
  }));
}

const LOG_TEXT = {
  "account.created": "Cuenta creada", "session.opened": "Sesión iniciada",
  "subdomain.created": "Subdominio creado", "subdomain.renewed": "Subdominio renovado",
  "subdomain.released": "Subdominio liberado", "record.updated": "Registro modificado",
  "password.changed": "Contraseña cambiada", "user.updated": "Usuario modificado"
};

function renderAudit() {
  $("#auditLog").innerHTML = DATA.log.length
    ? DATA.log.map(e => '<div class="log-line"><time>' + fmtDate(e.at) + '</time><span>' +
        escapeHtml((LOG_TEXT[e.action] || e.action) + " · " + (e.detail || "")) + '</span></div>').join("")
    : '<div class="empty"><h3>Sin actividad</h3><p>Todavía no se ha registrado ningún movimiento.</p></div>';
}

$("#exportBtn").addEventListener("click", () => {
  const head = "host,tipo,destino,propietario,creado,caduca,estado\n";
  const body = DATA.subdomains.map(s =>
    [s.fqdn, s.type, s.value, s.userEmail, s.createdAt, s.expiresAt, stateOf(s)]
      .map(v => '"' + String(v === undefined || v === null ? "" : v).replace(/"/g, '""') + '"').join(",")
  ).join("\n");
  const url = URL.createObjectURL(new Blob([head + body], { type: "text/csv;charset=utf-8" }));
  const a = el("a", { href: url, download: "jitterx-registros-" + new Date().toISOString().slice(0, 10) + ".csv" });
  document.body.append(a); a.click(); a.remove(); URL.revokeObjectURL(url);
  toast("CSV listo", "Descarga iniciada.", "ok");
});

load();
setInterval(load, 60000);
