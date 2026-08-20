/* ============================================================
   JitterX Panel Cloud — capa de datos
   Si CFG.apiBase está configurado, habla con el Worker.
   Si no, arranca el backend de demostración local.
   ============================================================ */

const DEMO = !CFG.apiBase;

/* ---------- Cliente real (Cloudflare Worker) ---------- */
async function callApi(path, opts) {
  opts = opts || {};
  const method = opts.method || "GET";
  const auth = opts.auth !== false;
  const headers = { "Content-Type": "application/json" };
  if (auth) {
    const s = Session.get();
    if (s && s.token) headers.Authorization = "Bearer " + s.token;
  }
  let res;
  try {
    res = await fetch(CFG.apiBase + path, {
      method: method, headers: headers,
      body: opts.body ? JSON.stringify(opts.body) : undefined
    });
  } catch (e) {
    throw new Error(LANG === "es"
      ? "No se llegó al servidor. Revisa la URL del Worker en config.js."
      : "Server unreachable. Check the Worker URL in config.js.");
  }
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && auth) { Session.clear(); location.replace("index.html"); }
  if (!res.ok) throw new Error(data.error || ("Error " + res.status));
  return data;
}

/* ---------- Backend de demostración (navegador) ---------- */
const Demo = {
  key: "jx.demo.db",

  db() {
    let db = null;
    try { db = JSON.parse(localStorage.getItem(this.key)); } catch (e) { db = null; }
    if (!db) {
      db = {
        users: [{
          id: "u_admin",
          email: CFG.demoAdminEmail,
          name: "Administración",
          password: CFG.demoAdminPassword,
          role: "admin",
          createdAt: new Date(Date.now() - 30 * DAY).toISOString(),
          suspended: false
        }],
        subs: [],
        log: []
      };
      this.save(db);
    }
    return db;
  },

  save(db) { localStorage.setItem(this.key, JSON.stringify(db)); },
  wait(ms) { return new Promise(r => setTimeout(r, ms === undefined ? 380 : ms)); },
  id(prefix) { return prefix + "_" + Math.random().toString(36).slice(2, 10); },

  log(db, userId, action, detail) {
    db.log.unshift({ id: this.id("l"), userId: userId, action: action, detail: detail, at: new Date().toISOString() });
    db.log = db.log.slice(0, 400);
  },

  user(db) {
    const s = Session.get();
    return db.users.find(u => s && s.user && u.id === s.user.id) || null;
  },

  async register(d) {
    await this.wait();
    const db = this.db();
    const email = String(d.email).toLowerCase().trim();
    if (db.users.some(u => u.email === email))
      throw new Error(LANG === "es" ? "Ese correo ya tiene cuenta." : "That email already has an account.");
    if (String(d.password).length < 8)
      throw new Error(LANG === "es" ? "La contraseña necesita 8 caracteres como mínimo." : "Password needs at least 8 characters.");
    const user = {
      id: this.id("u"), email: email, name: d.name || email.split("@")[0],
      password: d.password, role: "user", createdAt: new Date().toISOString(), suspended: false
    };
    db.users.push(user);
    this.log(db, user.id, "account.created", email);
    this.save(db);
    return this.session(user);
  },

  async login(d) {
    await this.wait();
    const db = this.db();
    const user = db.users.find(u => u.email === String(d.email).toLowerCase().trim());
    if (!user || user.password !== d.password)
      throw new Error(LANG === "es" ? "Correo o contraseña incorrectos." : "Wrong email or password.");
    if (user.suspended)
      throw new Error(LANG === "es" ? "Cuenta suspendida. Escribe a soporte." : "Account suspended. Contact support.");
    this.log(db, user.id, "session.opened", user.email);
    this.save(db);
    return this.session(user);
  },

  session(user) {
    return {
      token: "demo." + user.id,
      user: { id: user.id, email: user.email, name: user.name, role: user.role }
    };
  },

  async list() {
    await this.wait(200);
    const db = this.db();
    const me = this.user(db);
    if (!me) throw new Error(LANG === "es" ? "Sesión caducada." : "Session expired.");
    db.subs.forEach(s => {
      if (s.status === "pending" && Date.now() - new Date(s.createdAt).getTime() > 25000) s.status = "active";
    });
    this.save(db);
    return { subdomains: db.subs.filter(s => s.userId === me.id) };
  },

  async create(d) {
    await this.wait(700);
    const db = this.db();
    const me = this.user(db);
    const mine = db.subs.filter(s => s.userId === me.id && msLeft(s.expiresAt) > 0);
    if (mine.length >= CFG.maxSubdomainsPerUser)
      throw new Error(LANG === "es"
        ? "Has llegado a tu cuota de " + CFG.maxSubdomainsPerUser + " subdominios activos."
        : "You reached your quota of " + CFG.maxSubdomainsPerUser + " active subdomains.");
    if (db.subs.some(s => s.label === d.label && msLeft(s.expiresAt) > 0))
      throw new Error(LANG === "es" ? "Ese subdominio ya está cogido." : "That subdomain is taken.");

    const now = Date.now();
    const sub = {
      id: this.id("s"),
      userId: me.id,
      userEmail: me.email,
      label: d.label,
      fqdn: d.label + "." + CFG.rootDomain,
      type: d.type,
      value: d.value,
      proxied: !!d.proxied,
      note: d.note || "",
      ttl: 300,
      status: "pending",
      recordId: "demo-" + Math.random().toString(16).slice(2, 12),
      createdAt: new Date(now).toISOString(),
      expiresAt: new Date(now + CFG.trialDays * DAY).toISOString(),
      totalMs: CFG.trialDays * DAY,
      renewals: 0
    };
    db.subs.unshift(sub);
    this.log(db, me.id, "subdomain.created", sub.fqdn);
    this.save(db);
    return { subdomain: sub };
  },

  async update(id, patch) {
    await this.wait(450);
    const db = this.db();
    const me = this.user(db);
    const sub = db.subs.find(s => s.id === id && (s.userId === me.id || me.role === "admin"));
    if (!sub) throw new Error(LANG === "es" ? "Subdominio no encontrado." : "Subdomain not found.");
    Object.assign(sub, patch);
    sub.status = "active";
    this.log(db, me.id, "record.updated", sub.fqdn);
    this.save(db);
    return { subdomain: sub };
  },

  async renew(id) {
    await this.wait(500);
    const db = this.db();
    const me = this.user(db);
    const sub = db.subs.find(s => s.id === id && (s.userId === me.id || me.role === "admin"));
    if (!sub) throw new Error(LANG === "es" ? "Subdominio no encontrado." : "Subdomain not found.");
    if (CFG.maxRenewals && sub.renewals >= CFG.maxRenewals)
      throw new Error(LANG === "es"
        ? "Este subdominio ya se renovó " + CFG.maxRenewals + " veces."
        : "This subdomain was already renewed " + CFG.maxRenewals + " times.");
    const base = Math.max(Date.now(), new Date(sub.expiresAt).getTime());
    sub.expiresAt = new Date(base + CFG.trialDays * DAY).toISOString();
    sub.totalMs = new Date(sub.expiresAt).getTime() - Date.now();
    sub.renewals++;
    sub.status = "active";
    this.log(db, me.id, "subdomain.renewed", sub.fqdn);
    this.save(db);
    return { subdomain: sub };
  },

  async remove(id) {
    await this.wait(420);
    const db = this.db();
    const me = this.user(db);
    const sub = db.subs.find(s => s.id === id && (s.userId === me.id || me.role === "admin"));
    if (!sub) throw new Error(LANG === "es" ? "Subdominio no encontrado." : "Subdomain not found.");
    db.subs = db.subs.filter(s => s.id !== id);
    this.log(db, me.id, "subdomain.released", sub.fqdn);
    this.save(db);
    return { ok: true };
  },

  async available(label) {
    await this.wait(220);
    const db = this.db();
    return { available: !db.subs.some(s => s.label === label && msLeft(s.expiresAt) > 0) };
  },

  async activity() {
    await this.wait(180);
    const db = this.db();
    const me = this.user(db);
    if (!me) return { entries: [] };
    return { entries: db.log.filter(l => me.role === "admin" || l.userId === me.id).slice(0, 60) };
  },

  async changePassword(d) {
    await this.wait(400);
    const db = this.db();
    const me = this.user(db);
    const rec = db.users.find(u => u.id === me.id);
    if (rec.password !== d.current)
      throw new Error(LANG === "es" ? "La contraseña actual no coincide." : "Current password doesn't match.");
    rec.password = d.next;
    this.log(db, me.id, "password.changed", me.email);
    this.save(db);
    return { ok: true };
  },

  async adminData() {
    await this.wait(300);
    const db = this.db();
    const me = this.user(db);
    if (!me || me.role !== "admin") throw new Error(LANG === "es" ? "Solo administración." : "Admins only.");
    return {
      users: db.users.map(u => ({
        id: u.id, email: u.email, name: u.name, role: u.role,
        createdAt: u.createdAt, suspended: u.suspended
      })),
      subdomains: db.subs,
      log: db.log.slice(0, 120)
    };
  },

  async adminUser(id, patch) {
    await this.wait(300);
    const db = this.db();
    const me = this.user(db);
    if (!me || me.role !== "admin") throw new Error("Solo administración.");
    const u = db.users.find(x => x.id === id);
    if (!u) throw new Error("Usuario no encontrado.");
    Object.assign(u, patch);
    this.log(db, me.id, "user.updated", u.email);
    this.save(db);
    return { ok: true };
  },

  reset() { localStorage.removeItem(this.key); }
};

/* ---------- Fachada única ---------- */
const API = {
  demo: DEMO,

  register: d => DEMO ? Demo.register(d) : callApi("/api/auth/register", { method: "POST", body: d, auth: false }),
  login:    d => DEMO ? Demo.login(d)    : callApi("/api/auth/login",    { method: "POST", body: d, auth: false }),

  listSubdomains:  ()      => DEMO ? Demo.list()          : callApi("/api/subdomains"),
  createSubdomain: d       => DEMO ? Demo.create(d)       : callApi("/api/subdomains", { method: "POST", body: d }),
  updateSubdomain: (id, d) => DEMO ? Demo.update(id, d)   : callApi("/api/subdomains/" + id, { method: "PATCH", body: d }),
  renewSubdomain:  id      => DEMO ? Demo.renew(id)       : callApi("/api/subdomains/" + id + "/renew", { method: "POST" }),
  deleteSubdomain: id      => DEMO ? Demo.remove(id)      : callApi("/api/subdomains/" + id, { method: "DELETE" }),

  checkAvailability: label => DEMO ? Demo.available(label)
    : callApi("/api/availability?label=" + encodeURIComponent(label), { auth: false }),

  activity:       ()      => DEMO ? Demo.activity()          : callApi("/api/activity"),
  changePassword: d       => DEMO ? Demo.changePassword(d)   : callApi("/api/account/password", { method: "POST", body: d }),

  adminData: ()      => DEMO ? Demo.adminData()      : callApi("/api/admin/overview"),
  adminUser: (id, d) => DEMO ? Demo.adminUser(id, d) : callApi("/api/admin/users/" + id, { method: "PATCH", body: d }),

  resetDemo: () => Demo.reset()
};
