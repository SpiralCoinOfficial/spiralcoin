// Simple smoke test for SpiralCoin backend
// Tries health, quotes, and candles endpoints across common ports

import { fetch as undiciFetch } from 'undici';
const fetch = globalThis.fetch ?? undiciFetch;
const portsToTry = [5000, 5001, 5002, 5003, 5004, 5005];

async function getJson(url) {
  const res = await fetch(url, { cache: 'no-store' });
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return await res.json();
}

async function findWorkingPort() {
  for (const p of portsToTry) {
    try {
      const h = await getJson(`http://127.0.0.1:${p}/health`);
      if (h && h.status === 'healthy') {
        // Verify quotes exist for this port
        const q = await getJson(`http://127.0.0.1:${p}/api/market/quotes`);
        if (q && (q.SPRC || q.BTC || q.ETH)) {
          return { port: p, health: h };
        }
      }
    } catch {}
  }
  return null;
}

(async () => {
  const found = await findWorkingPort();
  if (!found) {
    console.error('ERROR: Could not find a port with health and quotes.');
    process.exit(1);
  }
  const { port, health } = found;
  console.log(`OK: Health on port ${port} ->`, health);

  try {
    const quotes = await getJson(`http://127.0.0.1:${port}/api/market/quotes`);
    console.log('OK: Quotes:', quotes);
  } catch (e) {
    console.error('ERROR: Quotes endpoint failed:', e.message);
  }

  try {
    const candles = await getJson(`http://127.0.0.1:${port}/api/market/candles?asset=ETH&vs=USD&interval=1h`);
    const preview = Array.isArray(candles.candles) ? candles.candles.slice(0, 3) : candles;
    console.log('OK: Candles (ETH/USD/1h) preview:', preview);
  } catch (e) {
    console.error('ERROR: Candles endpoint failed:', e.message);
  }

  // Let pending async handles settle on Windows
  setTimeout(() => process.exit(0), 50);
})();
