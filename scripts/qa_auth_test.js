// QA Auth Test: signup -> login -> account
import { fetch as undiciFetch } from 'undici';
const fetch = globalThis.fetch ?? undiciFetch;

const ports = [5000, 5001, 5002, 5003, 5004, 5005];

async function getJson(url, init) {
  const res = await fetch(url, { cache: 'no-store', ...init });
  const ct = res.headers.get('content-type') || '';
  const body = ct.includes('application/json') ? await res.json() : await res.text();
  return { ok: res.ok, status: res.status, headers: res.headers, body };
}

async function findPort() {
  for (const p of ports) {
    try {
      const r = await getJson(`http://127.0.0.1:${p}/health`);
      if (r.ok && r.body && r.body.status === 'healthy') return p;
    } catch {}
  }
  return null;
}

(async () => {
  const port = await findPort();
  if (!port) { console.error('No backend found'); process.exit(1); }
  const base = `http://127.0.0.1:${port}`;

  const email = `qa_${Date.now()}_${Math.floor(Math.random()*1e6)}@example.com`;
  const password = 'Test1234!qa';

  // signup
  const signup = await getJson(`${base}/api/auth/signup`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  console.log('Signup:', signup.status, signup.body);
  if (!signup.ok) process.exit(2);

  // login
  const login = await getJson(`${base}/api/auth/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  console.log('Login:', login.status, login.body);
  if (!login.ok || !login.body.token) process.exit(3);

  const token = login.body.token;

  // account
  const account = await getJson(`${base}/api/account`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  console.log('Account:', account.status, account.body);
  if (!account.ok || account.body.email !== email) process.exit(4);

  // brief delay to allow sockets to settle on Windows
  setTimeout(() => process.exit(0), 50);
})();
