import { db, dbEnv } from "../../lib/db.js";
import { verifyPassword, createSession, validEmail } from "../../lib/auth.js";
import { limit } from "../../lib/ratelimit.js";

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).json({ error: "Método no permitido" });
  const over = limit(req, { max: 10, windowMs: 600000 });
  if (over) return res.status(429).json({ error: over });
  const cfg = dbEnv();
  if (cfg) return res.status(500).json({ error: cfg });

  const b = typeof req.body === "string" ? JSON.parse(req.body || "{}") : req.body || {};
  const email = String(b.email || "").trim().toLowerCase();
  const password = String(b.password || "");
  if (!validEmail(email) || !password) return res.status(400).json({ error: "Correo o contraseña incorrectos." });

  try {
    const user = await db.one("usuarios", { email: `eq.${email}` }, "id,email,nombre,password,bloqueado");
    // Mismo mensaje siempre, para no revelar qué correos existen
    if (!user || !verifyPassword(password, user.password)) {
      return res.status(401).json({ error: "Correo o contraseña incorrectos." });
    }
    if (user.bloqueado) return res.status(403).json({ error: "Esta cuenta está suspendida." });

    await createSession(res, req, user.id);
    await db.update("usuarios", { id: `eq.${user.id}` }, { ultimo_login: new Date().toISOString() }).catch(() => {});
    res.status(200).json({ ok: true, user: { id: user.id, email: user.email, nombre: user.nombre } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
