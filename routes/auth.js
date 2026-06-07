import bcrypt from "bcryptjs";
import crypto from "crypto";
import express from "express";
import fs from "fs";
import jwt from "jsonwebtoken";
import path from "path";
import { fileURLToPath } from "url";

export const authRouter = express.Router();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.join(__dirname, "..");
const DATA_DIR = path.join(ROOT, "data");
const USERS_FILE = path.join(DATA_DIR, "users.json");
const USER_WALLETS_FILE = path.join(DATA_DIR, "user_wallets.json");

function resolveJwtSecret() {
  const configured = (process.env.JWT_SECRET || "").trim();
  if (configured) return configured;

  if ((process.env.NODE_ENV || "").toLowerCase() === "production") {
    throw new Error("JWT_SECRET is required when NODE_ENV=production");
  }

  const ephemeral = crypto.randomBytes(32).toString("hex");
  console.warn("[auth] JWT_SECRET is not set; using an ephemeral development secret.");
  return ephemeral;
}

const JWT_SECRET = resolveJwtSecret();

function ensureDataFiles() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(USERS_FILE)) fs.writeFileSync(USERS_FILE, JSON.stringify({ users: [] }, null, 2));
  if (!fs.existsSync(USER_WALLETS_FILE)) fs.writeFileSync(USER_WALLETS_FILE, JSON.stringify({ wallets: {} }, null, 2));
}

function readJson(p) {
  try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; }
}
function writeJson(p, obj) {
  const tmp = p + ".tmp";
  fs.writeFileSync(tmp, JSON.stringify(obj, null, 2));
  fs.renameSync(tmp, p);
}

ensureDataFiles();

authRouter.post("/register", (req, res) => {
  try {
    const { username, password } = req.body || {};
    if (!username || !password) return res.status(400).json({ error: "Missing username or password" });
    const users = readJson(USERS_FILE) || { users: [] };
    if (users.users.find(u => u.username.toLowerCase() === String(username).toLowerCase())) {
      return res.status(409).json({ error: "Username already exists" });
    }
    const id = "u_" + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
    const hash = bcrypt.hashSync(password, 10);
    users.users.push({ id, username, hash, settings: { theme: "dark" } });
    writeJson(USERS_FILE, users);
    const uw = readJson(USER_WALLETS_FILE) || { wallets: {} };
    if (!uw.wallets[id]) uw.wallets[id] = [];
    writeJson(USER_WALLETS_FILE, uw);
    const token = jwt.sign({ sub: id, username }, JWT_SECRET, { expiresIn: "7d" });
    res.json({ token, user: { id, username } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

authRouter.post("/login", (req, res) => {
  try {
    const { username, password } = req.body || {};
    if (!username || !password) return res.status(400).json({ error: "Missing username or password" });
    const users = readJson(USERS_FILE) || { users: [] };
    const user = users.users.find(u => u.username.toLowerCase() === String(username).toLowerCase());
    if (!user) return res.status(401).json({ error: "Invalid credentials" });
    const ok = bcrypt.compareSync(password, user.hash);
    if (!ok) return res.status(401).json({ error: "Invalid credentials" });
    const token = jwt.sign({ sub: user.id, username: user.username }, JWT_SECRET, { expiresIn: "7d" });
    res.json({ token, user: { id: user.id, username: user.username } });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export function authMiddleware(req, res, next) {
  try {
    const h = req.headers["authorization"] || "";
    const m = /^Bearer\s+(.+)$/i.exec(h);
    if (!m) return res.status(401).json({ error: "Missing token" });
    const payload = jwt.verify(m[1], JWT_SECRET);
    req.user = { id: payload.sub, username: payload.username };
    next();
  } catch (e) {
    return res.status(401).json({ error: "Invalid token" });
  }
}

export function readStores() {
  return {
    users: readJson(USERS_FILE) || { users: [] },
    userWallets: readJson(USER_WALLETS_FILE) || { wallets: {} }
  };
}

export function writeUserWallets(obj) {
  writeJson(USER_WALLETS_FILE, obj);
}
