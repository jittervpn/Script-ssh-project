// Acceso a Supabase por su API REST (sin dependencias npm).
// Usa la service_role key: solo se ejecuta en el servidor, nunca en el navegador.
import { clean } from "./cf.js";

const url = () => clean(process.env.SUPABASE_URL).replace(/\/$/, "");
const key = () => clean(process.env.SUPABASE_SERVICE_KEY);

export function dbEnv() {
  if (!url() || !key()) return "Faltan las variables SUPABASE_URL o SUPABASE_SERVICE_KEY en Vercel.";
  return null;
}

async function rest(path, { method = "GET", body, prefer } = {}) {
  const res = await fetch(`${url()}/rest/v1/${path}`, {
    method,
    headers: {
      apikey: key(),
      authorization: "Bearer " + key(),
      "content-type": "application/json",
      ...(prefer ? { prefer } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data = null;
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }
  if (!res.ok) {
    const msg = (data && (data.message || data.hint)) || `Error de base de datos (${res.status})`;
    throw new Error(msg);
  }
  return data;
}

export const db = {
  async find(table, filters = {}, select = "*", limit = 50) {
    const q = new URLSearchParams({ select, limit: String(limit) });
    for (const [k, v] of Object.entries(filters)) q.append(k, v);
    return rest(`${table}?${q}`);
  },
  async one(table, filters = {}, select = "*") {
    const rows = await this.find(table, filters, select, 1);
    return rows && rows[0] ? rows[0] : null;
  },
  async insert(table, row) {
    const rows = await rest(table, { method: "POST", body: row, prefer: "return=representation" });
    return rows && rows[0];
  },
  async update(table, filters, patch) {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries(filters)) q.append(k, v);
    return rest(`${table}?${q}`, { method: "PATCH", body: patch, prefer: "return=representation" });
  },
  async remove(table, filters) {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries(filters)) q.append(k, v);
    return rest(`${table}?${q}`, { method: "DELETE" });
  },
};
