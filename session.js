import { currentUser } from "../../lib/auth.js";
import { dbEnv } from "../../lib/db.js";

export default async function handler(req, res) {
  if (dbEnv()) return res.status(200).json({ user: null });
  try {
    res.status(200).json({ user: await currentUser(req) });
  } catch {
    res.status(200).json({ user: null });
  }
}
