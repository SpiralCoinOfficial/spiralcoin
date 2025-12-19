// QA Routes Test: redirects and basic endpoints
import { getGlobalDispatcher, fetch as undiciFetch } from 'undici';
const fetch = globalThis.fetch ?? undiciFetch;

const ports = [5000, 5001, 5002, 5003, 5004, 5005];

async function head(url) {
  const res = await fetch(url, { method: 'HEAD', redirect: 'manual' });
  return { status: res.status, headers: res.headers };
}

async function get(url, opts={}) {
  const res = await fetch(url, { redirect: 'manual', ...opts });
  const text = await res.text();
  return { status: res.status, headers: res.headers, text };
}

async function findPort() {
  for (const p of ports) {
    try {
      const r = await fetch(`http://127.0.0.1:${p}/health`, { redirect: 'manual' });
      if (r.ok) return p;
    } catch {}
  }
  return null;
}

(async () => {
  const port = await findPort();
  if (!port) { console.error('No backend found'); process.exit(1); }
  const base = `http://127.0.0.1:${port}`;

  // 1) Redirect /Trading_platform.html -> /trading_platform.html
  const r1 = await get(`${base}/Trading_platform.html`);
  console.log('GET /Trading_platform.html ->', r1.status, r1.headers.get('location'));

  // 2) Redirect /trading -> /trading_platform.html
  const r2 = await get(`${base}/trading`);
  console.log('GET /trading ->', r2.status, r2.headers.get('location'));

  // 3) trading_platform.html returns HTML
  const r3 = await get(`${base}/trading_platform.html`);
  console.log('GET /trading_platform.html ->', r3.status, 'HTML length', r3.text.length);

  // 4) pairs endpoint
  const r4 = await fetch(`${base}/api/market/pairs`);
  console.log('GET /api/market/pairs ->', r4.status);

  // Gracefully close undici dispatcher to avoid libuv assertion on Windows.
  try {
    await getGlobalDispatcher().close();
  } catch {}
  // Allow natural process exit without forcing process.exit().
})();
