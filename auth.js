// Registro, login y sesiones. Contraseñas con scrypt (nativo de Node, sin dependencias).
import crypto from "node:crypto";
import { db } from "./db.js";

const SESSION_DAYS = 30;
const COOKIE = "jx_session";

export const hashPassword = (plain) => {
  const salt = crypto.randomBytes(16).toString("hex");
  return `${salt}:${crypto.scryptSync(plain, salt, 64).toString("hex")}`;
};

export const verifyPassword = (plain, stored) => {
  try {
    const [salt, hash] = String(stored).split(":");
    return crypto.timingSafeEqual(Buffer.from(hash, "hex"), crypto.scryptSync(plain, salt, 64));
  } catch {
    return false;
  }
};

const sha = (v) => crypto.createHash("sha256").update(v).digest("hex");

export function getCookie(req, name) {
  const m = (req.headers.cookie || "").match(new RegExp("(?:^|;\\s*)" + name + "=([^;]+)"));
  return m ? m[1] : null;
}

export async function createSession(res, req, usuarioId) {
  const token = crypto.randomBytes(32).toString("hex");
  await db.insert("sesiones", {
    token: sha(token),
    usuario_id: usuarioId,
    expira_en: new Date(Date.now() + SESSION_DAYS * 864e5).toISOString(),
    ip: (req.headers["x-forwarded-for"] || "").split(",")[0].trim() || null,
    agente: (req.headers["user-agent"] || "").slice(0, 200),
  });
  res.setHeader("set-cookie",
    `${COOKIE}=${token}; Path=/; Max-Age=${SESSION_DAYS * 86400}; HttpOnly; Secure; SameSite=Lax`);
}

export async function currentUser(req) {
  const raw = getCookie(req, COOKIE);
  if (!raw) return null;
  const sesion = await db.one("sesiones", { token: `eq.${sha(raw)}` }, "usuario_id,expira_en");
  if (!sesion) return null;
  if (new Date(sesion.expira_en) < new Date()) {
    await db.remove("sesiones", { token: `eq.${sha(raw)}` }).catch(() => {});
    return null;
  }
  const user = await db.one("usuarios", { id: `eq.${sesion.usuario_id}` }, "id,email,nombre,bloqueado,creado_en");
  return user && !user.bloqueado ? user : null;
}

export async function destroySession(res, req) {
  const raw = getCookie(req, COOKIE);
  if (raw) await db.remove("sesiones", { token: `eq.${sha(raw)}` }).catch(() => {});
  res.setHeader("set-cookie", `${COOKIE}=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax`);
}

export const validEmail = (e) => /^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i.test(e);
