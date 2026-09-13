import { db, dbEnv } from "../../lib/db.js";
import { hashPassword, createSession, validEmail } from "../../lib/auth.js";
import { limit } from "../../lib/ratelimit.js";

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).json({ error: "Método no permitido" });
  const over = limit(req, { max: 5, windowMs: 600000 });
  if (over) return res.status(429).json({ error: over });
  const cfg = dbEnv();
  if (cfg) return res.status(500).json({ error: cfg });

  const b = typeof req.body === "string" ? JSON.parse(req.body || "{}") : req.body || {};
  const email = String(b.email || "").trim().toLowerCase();
  const password = String(b.password || "");
  const nombre = String(b.nombre || "").trim().slice(0, 60) || null;

  if (!validEmail(email)) return res.status(400).json({ error: "Escribe un correo válido." });
  if (password.length < 8) return res.status(400).json({ error: "La contraseña debe tener al menos 8 caracteres." });

  try {
    if (await db.one("usuarios", { email: `eq.${email}` }, "id")) {
      return res.status(409).json({ error: "Ya existe una cuenta con ese correo. Inicia sesión." });
    }
    const user = await db.insert("usuarios", { email, password: hashPassword(password), nombre });
    await createSession(res, req, user.id);
    res.status(201).json({ ok: true, user: { id: user.id, email: user.email, nombre: user.nombre } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
