// QA Auth Refresh Test: login -> refresh -> account -> logout
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

  const email = `qa_refresh_${Date.now()}_${Math.floor(Math.random()*1e6)}@example.com`;
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
  if (!login.ok || !login.body.token || !login.body.refreshToken) process.exit(3);
  const token1 = login.body.token;
  const refreshToken = login.body.refreshToken;

  // account with token1
  const account1 = await getJson(`${base}/api/account`, {
    headers: { 'Authorization': `Bearer ${token1}` }
  });
  console.log('Account(1):', account1.status, account1.body);
  if (!account1.ok) process.exit(4);

  // refresh
  const refresh = await getJson(`${base}/api/auth/refresh`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken })
  });
  console.log('Refresh:', refresh.status, refresh.body);
  if (!refresh.ok || !refresh.body.token) process.exit(5);
  const token2 = refresh.body.token;

  // account with token2
  const account2 = await getJson(`${base}/api/account`, {
    headers: { 'Authorization': `Bearer ${token2}` }
  });
  console.log('Account(2):', account2.status, account2.body);
  if (!account2.ok) process.exit(6);

  // logout
  const logout = await getJson(`${base}/api/auth/logout`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken })
  });
  console.log('Logout:', logout.status, logout.body);

  // attempt refresh again should fail
  const refreshAgain = await getJson(`${base}/api/auth/refresh`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken })
  });
  console.log('Refresh After Logout:', refreshAgain.status, refreshAgain.body);
  if (refreshAgain.ok) process.exit(7);

  setTimeout(() => process.exit(0), 50);
})();
