/**
 * ============================================================
 * JitterX Panel Cloud — Worker de Cloudflare
 * ------------------------------------------------------------
 * Aquí vive el token de Cloudflare. Nunca en el navegador.
 *
 * Secretos (wrangler secret put NOMBRE):
 *   CF_API_TOKEN     token con permiso Zone.DNS:Edit sobre tu zona
 *   CF_ZONE_ID       id de la zona (portada de Cloudflare, columna derecha)
 *   SESSION_SECRET   cadena larga y aleatoria para firmar sesiones
 *
 * Variables (wrangler.toml):
 *   ROOT_DOMAIN, TRIAL_DAYS, MAX_PER_USER, RENEWAL_WINDOW_DAYS,
 *   MAX_RENEWALS, ALLOWED_ORIGIN, ADMIN_EMAILS, EXTRA_BLOCKED
 *
 * KV: binding DB
 * Cron: purga los registros caducados
 * ============================================================
 */

const DAY = 86400000;

const BLOCKED = new Set([
  "www","mail","smtp","imap","pop","ftp","ns","ns1","ns2","admin","root","api",
  "cdn","dev","test","staging","panel","cpanel","webmail","vpn","git","blog",
  "shop","app","dash","cloudflare","jitterx","support","billing","login",
  "secure","autodiscover","autoconfig","mx","dkim","dmarc","spf"
]);

/* ---------- HTTP ---------- */
function cors(env) {
  return {
    "Access-Control-Allow-Origin": env.ALLOWED_ORIGIN || "*",
    "Access-Control-Allow-Methods": "GET,POST,PATCH,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Max-Age": "86400"
  };
}
const json = (env, data, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...cors(env) }
  });
const fail = (env, msg, status = 400) => json(env, { error: msg }, status);

/* ---------- Criptografía ---------- */
const enc = new TextEncoder();
const b64u = buf => btoa(String.fromCharCode(...new Uint8Array(buf)))
  .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const toHex = a => [...new Uint8Array(a)].map(b => b.toString(16).padStart(2, "0")).join("");

async function hashPassword(password, saltHex) {
  const salt = saltHex
    ? Uint8Array.from(saltHex.match(/../g).map(h => parseInt(h, 16)))
    : crypto.getRandomValues(new Uint8Array(16));
  const key = await crypto.subtle.importKey("raw", enc.encode(password), "PBKDF2", false, ["deriveBits"]);
  const bits = await crypto.subtle.deriveBits(
    { name: "PBKDF2", salt, iterations: 150000, hash: "SHA-256" }, key, 256);
  return { salt: toHex(salt), hash: toHex(bits) };
}

async function verifyPassword(password, stored) {
  if (!stored || !stored.salt) return false;
  const { hash } = await hashPassword(password, stored.salt);
  if (hash.length !== stored.hash.length) return false;
  let diff = 0;
  for (let i = 0; i < hash.length; i++) diff |= hash.charCodeAt(i) ^ stored.hash.charCodeAt(i);
  return diff === 0;
}

const hmacKey = secret =>
  crypto.subtle.importKey("raw", enc.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign", "verify"]);

async function signToken(payload, secret) {
  const head = b64u(enc.encode(JSON.stringify({ alg: "HS256", typ: "JWT" })));
  const body = b64u(enc.encode(JSON.stringify(payload)));
  const sig = b64u(await crypto.subtle.sign("HMAC", await hmacKey(secret), enc.encode(head + "." + body)));
  return head + "." + body + "." + sig;
}

async function readToken(token, secret) {
  const parts = String(token || "").split(".");
  if (parts.length !== 3) return null;
  const [head, body, sig] = parts;
  const expected = b64u(await crypto.subtle.sign("HMAC", await hmacKey(secret), enc.encode(head + "." + body)));
  if (sig !== expected) return null;
  try {
    const payload = JSON.parse(atob(body.replace(/-/g, "+").replace(/_/g, "/")));
    if (payload.exp && Date.now() > payload.exp) return null;
    return payload;
  } catch (e) { return null; }
}

/* ---------- API de Cloudflare ---------- */
async function cfDns(env, path, options = {}) {
  const res = await fetch(
    "https://api.cloudflare.com/client/v4/zones/" + env.CF_ZONE_ID + "/dns_records" + path,
    {
      ...options,
      headers: {
        Authorization: "Bearer " + env.CF_API_TOKEN,
        "Content-Type": "application/json",
        ...(options.headers || {})
      }
    });
  const data = await res.json();
  if (!data.success) {
    throw new Error((data.errors && data.errors[0] && data.errors[0].message) || "Cloudflare rechazó la operación");
  }
  return data.result;
}

/* ---------- Almacén ---------- */
const store = {
  userByEmail: (env, email) => env.DB.get("user:email:" + email.toLowerCase(), "json"),
  userById:    (env, id)    => env.DB.get("user:id:" + id, "json"),

  async putUser(env, user) {
    await env.DB.put("user:id:" + user.id, JSON.stringify(user));
    await env.DB.put("user:email:" + user.email, JSON.stringify(user));
  },

  sub: (env, id) => env.DB.get("sub:" + id, "json"),
  putSub: (env, sub) => env.DB.put("sub:" + sub.id, JSON.stringify(sub)),

  async delSub(env, sub) {
    await env.DB.delete("sub:" + sub.id);
    await env.DB.delete("label:" + sub.label);
  },

  label: (env, label) => env.DB.get("label:" + label),

  async listSubs(env, userId) {
    const out = [];
    let cursor;
    while (true) {
      const page = await env.DB.list({ prefix: "sub:", cursor });
      for (const k of page.keys) {
        const s = await env.DB.get(k.name, "json");
        if (s && (!userId || s.userId === userId)) out.push(s);
      }
      if (page.list_complete) break;
      cursor = page.cursor;
    }
    return out.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  },

  async listUsers(env) {
    const out = [];
    const page = await env.DB.list({ prefix: "user:id:" });
    for (const k of page.keys) {
      const u = await env.DB.get(k.name, "json");
      if (u) out.push({ id: u.id, email: u.email, name: u.name, role: u.role, createdAt: u.createdAt, suspended: u.suspended });
    }
    return out;
  },

  log(env, userId, action, detail) {
    const id = Date.now() + "_" + Math.random().toString(36).slice(2, 8);
    return env.DB.put("log:" + id, JSON.stringify({
      id, userId, action, detail, at: new Date().toISOString()
    }), { expirationTtl: 60 * 60 * 24 * 60 });
  },

  async listLog(env, userId) {
    const page = await env.DB.list({ prefix: "log:", limit: 400 });
    const out = [];
    for (const k of page.keys) {
      const e = await env.DB.get(k.name, "json");
      if (e && (!userId || e.userId === userId)) out.push(e);
    }
    return out.sort((a, b) => new Date(b.at) - new Date(a.at)).slice(0, 80);
  },

  async rateLimit(env, key, max, windowSec) {
    const k = "rl:" + key;
    const n = Number(await env.DB.get(k)) || 0;
    if (n >= max) return false;
    await env.DB.put(k, String(n + 1), { expirationTtl: windowSec });
    return true;
  }
};

/* ---------- Validación ---------- */
function checkLabel(label, env) {
  const v = String(label || "").trim().toLowerCase();
  if (!/^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/.test(v)) return "Nombre no válido.";
  if (v.length < 3 || v.length > 24) return "El nombre debe tener entre 3 y 24 caracteres.";
  if (v.includes("--")) return "Sin guiones dobles.";
  if (BLOCKED.has(v)) return "Ese nombre está reservado.";
  const extra = (env.EXTRA_BLOCKED || "").split(",").map(s => s.trim()).filter(Boolean);
  if (extra.includes(v)) return "Ese nombre está reservado.";
  return null;
}

function checkRecord(type, value) {
  const v = String(value || "").trim();
  if (!["A", "AAAA", "CNAME", "TXT"].includes(type)) return "Tipo de registro no admitido.";
  if (!v) return "Indica el destino.";
  if (type === "A" && (!/^(\d{1,3}\.){3}\d{1,3}$/.test(v) || v.split(".").some(o => Number(o) > 255)))
    return "IPv4 no válida.";
  if (type === "AAAA" && !/^[0-9a-f:]+$/i.test(v)) return "IPv6 no válida.";
  if (type === "CNAME" && !/^[a-z0-9.-]+\.[a-z]{2,}$/i.test(v)) return "Host de destino no válido.";
  if (type === "TXT" && v.length > 255) return "El TXT no puede pasar de 255 caracteres.";
  return null;
}

async function auth(request, env) {
  const header = request.headers.get("Authorization") || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return null;
  const payload = await readToken(token, env.SESSION_SECRET);
  if (!payload) return null;
  const user = await store.userById(env, payload.sub);
  if (!user || user.suspended) return null;
  return user;
}

function isAdmin(user, env) {
  const admins = (env.ADMIN_EMAILS || "").split(",").map(s => s.trim().toLowerCase()).filter(Boolean);
  return user.role === "admin" || admins.includes(user.email);
}

/* ---------- Router ---------- */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const p = url.pathname;
    const method = request.method;

    if (method === "OPTIONS") return new Response(null, { status: 204, headers: cors(env) });

    const trialDays   = Number(env.TRIAL_DAYS || 7);
    const maxPerUser  = Number(env.MAX_PER_USER || 3);
    const renewWindow = Number(env.RENEWAL_WINDOW_DAYS || 3);
    const maxRenewals = Number(env.MAX_RENEWALS || 4);
    const ip = request.headers.get("CF-Connecting-IP") || "0.0.0.0";

    try {
      if (p === "/" || p === "/api/health") {
        return json(env, { ok: true, service: "jitterx-panel-cloud", rootDomain: env.ROOT_DOMAIN, trialDays });
      }

      /* --- registro --- */
      if (p === "/api/auth/register" && method === "POST") {
        if (!await store.rateLimit(env, "reg:" + ip, 5, 3600))
          return fail(env, "Demasiados intentos. Prueba dentro de una hora.", 429);

        const { email, password, name } = await request.json();
        const mail = String(email || "").toLowerCase().trim();
        if (!/^[^@\s]+@[^@\s]+\.[a-z]{2,}$/i.test(mail)) return fail(env, "Correo no válido.");
        if (String(password || "").length < 8) return fail(env, "La contraseña necesita 8 caracteres como mínimo.");
        if (await store.userByEmail(env, mail)) return fail(env, "Ese correo ya tiene cuenta.");

        const admins = (env.ADMIN_EMAILS || "").split(",").map(s => s.trim().toLowerCase());
        const user = {
          id: crypto.randomUUID(),
          email: mail,
          name: String(name || mail.split("@")[0]).slice(0, 40),
          password: await hashPassword(password),
          role: admins.includes(mail) ? "admin" : "user",
          createdAt: new Date().toISOString(),
          suspended: false
        };
        await store.putUser(env, user);
        await store.log(env, user.id, "account.created", mail);
        const token = await signToken({ sub: user.id, exp: Date.now() + 7 * DAY }, env.SESSION_SECRET);
        return json(env, { token, user: { id: user.id, email: user.email, name: user.name, role: user.role } });
      }

      /* --- acceso --- */
      if (p === "/api/auth/login" && method === "POST") {
        if (!await store.rateLimit(env, "login:" + ip, 12, 900))
          return fail(env, "Demasiados intentos. Espera unos minutos.", 429);

        const { email, password } = await request.json();
        const user = await store.userByEmail(env, String(email || "").toLowerCase().trim());
        if (!user || !await verifyPassword(password || "", user.password))
          return fail(env, "Correo o contraseña incorrectos.", 401);
        if (user.suspended) return fail(env, "Cuenta suspendida. Escribe a soporte.", 403);

        await store.log(env, user.id, "session.opened", user.email);
        const token = await signToken({ sub: user.id, exp: Date.now() + 7 * DAY }, env.SESSION_SECRET);
        return json(env, { token, user: { id: user.id, email: user.email, name: user.name, role: user.role } });
      }

      /* --- disponibilidad (pública) --- */
      if (p === "/api/availability" && method === "GET") {
        const label = (url.searchParams.get("label") || "").toLowerCase();
        const bad = checkLabel(label, env);
        if (bad) return json(env, { available: false, reason: bad });
        const taken = await store.label(env, label);
        return json(env, { available: !taken });
      }

      /* --- de aquí en adelante hace falta sesión --- */
      const user = await auth(request, env);
      if (!user) return fail(env, "Sesión caducada. Vuelve a entrar.", 401);

      if (p === "/api/subdomains" && method === "GET") {
        return json(env, { subdomains: await store.listSubs(env, user.id) });
      }

      /* --- crear --- */
      if (p === "/api/subdomains" && method === "POST") {
        if (!await store.rateLimit(env, "create:" + user.id, 10, 3600))
          return fail(env, "Has creado demasiados subdominios seguidos. Espera un rato.", 429);

        const { label, type, value, proxied, note } = await request.json();
        const l = String(label || "").toLowerCase().trim();
        const badLabel = checkLabel(l, env);
        if (badLabel) return fail(env, badLabel);
        const badRecord = checkRecord(type, value);
        if (badRecord) return fail(env, badRecord);
        if (await store.label(env, l)) return fail(env, "Ese subdominio ya está cogido.", 409);

        const mine = (await store.listSubs(env, user.id))
          .filter(s => new Date(s.expiresAt).getTime() > Date.now());
        if (mine.length >= maxPerUser)
          return fail(env, "Has llegado a tu cuota de " + maxPerUser + " subdominios activos.", 403);

        const fqdn = l + "." + env.ROOT_DOMAIN;
        const canProxy = ["A", "AAAA", "CNAME"].includes(type);
        const record = await cfDns(env, "", {
          method: "POST",
          body: JSON.stringify({
            type,
            name: fqdn,
            content: String(value).trim(),
            ttl: 300,
            proxied: canProxy ? !!proxied : false,
            comment: "jitterx:" + user.id
          })
        });

        const now = Date.now();
        const sub = {
          id: crypto.randomUUID(),
          userId: user.id,
          userEmail: user.email,
          label: l,
          fqdn,
          type,
          value: String(value).trim(),
          proxied: canProxy ? !!proxied : false,
          note: String(note || "").slice(0, 40),
          ttl: 300,
          status: "pending",
          recordId: record.id,
          createdAt: new Date(now).toISOString(),
          expiresAt: new Date(now + trialDays * DAY).toISOString(),
          totalMs: trialDays * DAY,
          renewals: 0
        };
        await store.putSub(env, sub);
        await env.DB.put("label:" + l, sub.id,
          { expirationTtl: Math.floor(trialDays * DAY / 1000) + 3600 });
        await store.log(env, user.id, "subdomain.created", fqdn);
        return json(env, { subdomain: sub }, 201);
      }

      /* --- rutas con id --- */
      const m = p.match(/^\/api\/subdomains\/([^/]+)(\/renew)?$/);
      if (m) {
        const sub = await store.sub(env, m[1]);
        if (!sub) return fail(env, "Subdominio no encontrado.", 404);
        if (sub.userId !== user.id && !isAdmin(user, env)) return fail(env, "No es tuyo.", 403);

        if (m[2] && method === "POST") {
          const left = new Date(sub.expiresAt).getTime() - Date.now();
          if (left > renewWindow * DAY)
            return fail(env, "Podrás renovar cuando queden " + renewWindow + " días o menos.");
          if (maxRenewals && sub.renewals >= maxRenewals)
            return fail(env, "Este subdominio ya se renovó " + maxRenewals + " veces.");

          const base = Math.max(Date.now(), new Date(sub.expiresAt).getTime());
          sub.expiresAt = new Date(base + trialDays * DAY).toISOString();
          sub.totalMs = new Date(sub.expiresAt).getTime() - Date.now();
          sub.renewals++;
          sub.status = "active";
          await store.putSub(env, sub);
          await env.DB.put("label:" + sub.label, sub.id, {
            expirationTtl: Math.floor((new Date(sub.expiresAt).getTime() - Date.now()) / 1000) + 3600
          });
          await store.log(env, user.id, "subdomain.renewed", sub.fqdn);
          return json(env, { subdomain: sub });
        }

        if (method === "PATCH") {
          const { type, value, proxied, note } = await request.json();
          const newType = type || sub.type;
          const newValue = value !== undefined ? String(value).trim() : sub.value;
          const bad = checkRecord(newType, newValue);
          if (bad) return fail(env, bad);
          const canProxy = ["A", "AAAA", "CNAME"].includes(newType);

          await cfDns(env, "/" + sub.recordId, {
            method: "PUT",
            body: JSON.stringify({
              type: newType, name: sub.fqdn, content: newValue, ttl: 300,
              proxied: canProxy ? !!proxied : false, comment: "jitterx:" + sub.userId
            })
          });

          sub.type = newType;
          sub.value = newValue;
          sub.proxied = canProxy ? !!proxied : false;
          if (note !== undefined) sub.note = String(note).slice(0, 40);
          sub.status = "active";
          await store.putSub(env, sub);
          await store.log(env, user.id, "record.updated", sub.fqdn);
          return json(env, { subdomain: sub });
        }

        if (method === "DELETE") {
          try { await cfDns(env, "/" + sub.recordId, { method: "DELETE" }); } catch (e) {}
          await store.delSub(env, sub);
          await store.log(env, user.id, "subdomain.released", sub.fqdn);
          return json(env, { ok: true });
        }
      }

      if (p === "/api/activity" && method === "GET") {
        return json(env, { entries: await store.listLog(env, isAdmin(user, env) ? null : user.id) });
      }

      if (p === "/api/account/password" && method === "POST") {
        const { current, next } = await request.json();
        const full = await store.userById(env, user.id);
        if (!await verifyPassword(current || "", full.password))
          return fail(env, "La contraseña actual no coincide.", 403);
        if (String(next || "").length < 8)
          return fail(env, "La nueva necesita 8 caracteres como mínimo.");
        full.password = await hashPassword(next);
        await store.putUser(env, full);
        await store.log(env, user.id, "password.changed", user.email);
        return json(env, { ok: true });
      }

      if (p === "/api/admin/overview" && method === "GET") {
        if (!isAdmin(user, env)) return fail(env, "Solo administración.", 403);
        return json(env, {
          users: await store.listUsers(env),
          subdomains: await store.listSubs(env),
          log: await store.listLog(env)
        });
      }

      const au = p.match(/^\/api\/admin\/users\/([^/]+)$/);
      if (au && method === "PATCH") {
        if (!isAdmin(user, env)) return fail(env, "Solo administración.", 403);
        const target = await store.userById(env, au[1]);
        if (!target) return fail(env, "Usuario no encontrado.", 404);
        const patch = await request.json();
        if (patch.suspended !== undefined) target.suspended = !!patch.suspended;
        if (patch.role && ["user", "admin"].includes(patch.role)) target.role = patch.role;
        await store.putUser(env, target);
        await store.log(env, user.id, "user.updated", target.email);
        return json(env, { ok: true });
      }

      return fail(env, "Ruta no encontrada.", 404);

    } catch (err) {
      return fail(env, err.message || "Error inesperado en el servidor.", 500);
    }
  },

  /* --- Cron: borra de la zona todo lo caducado --- */
  async scheduled(event, env, ctx) {
    ctx.waitUntil((async () => {
      const subs = await store.listSubs(env);
      const now = Date.now();
      for (const sub of subs) {
        if (sub.status === "pending" && now - new Date(sub.createdAt).getTime() > 60000) {
          sub.status = "active";
          await store.putSub(env, sub);
        }
        if (new Date(sub.expiresAt).getTime() + 3600000 < now) {
          try { await cfDns(env, "/" + sub.recordId, { method: "DELETE" }); } catch (e) {}
          await store.delSub(env, sub);
          await store.log(env, sub.userId, "subdomain.released", sub.fqdn + " (caducado)");
        }
      }
    })());
  }
};
