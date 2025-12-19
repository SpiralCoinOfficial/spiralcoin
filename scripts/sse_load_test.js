#!/usr/bin/env node
/*
  SSE Load Test
  Spawns N concurrent SSE clients against quotes and/or candles endpoints and
  reports connection success, errors, and basic event counts.

  Usage:
    BASE_URL=https://www.spiralcoin.net node scripts/sse_load_test.js --clients 50 --endpoint quotes
    BASE_URL=https://www.spiralcoin.net node scripts/sse_load_test.js --clients 50 --endpoint candles --asset SPRC --vs USD --interval 1m
*/

function parseArgs() {
  const out = { clients: 20, endpoint: 'quotes', asset: 'SPRC', vs: 'USD', interval: '1m' };
  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; i++) {
    const k = args[i];
    if (k === '--clients' && args[i + 1]) out.clients = Number(args[++i]);
    else if (k === '--endpoint' && args[i + 1]) out.endpoint = String(args[++i]);
    else if (k === '--asset' && args[i + 1]) out.asset = String(args[++i]);
    else if (k === '--vs' && args[i + 1]) out.vs = String(args[++i]);
    else if (k === '--interval' && args[i + 1]) out.interval = String(args[++i]);
  }
  return out;
}

async function connectSSE(url, { maxEvents = 10, timeoutMs = 15000 } = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  let count = 0;
  let ok = false;
  let error = null;
  try {
    const res = await fetch(url, { headers: { 'Accept': 'text/event-stream' }, signal: controller.signal, cache: 'no-store' });
    if (res.ok) ok = true;
    const reader = res.body.getReader();
    const decoder = new TextDecoder('utf-8');
    let buf = '';
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buf += decoder.decode(value, { stream: true });
      let idx;
      while ((idx = buf.indexOf('\n\n')) >= 0) {
        const chunk = buf.slice(0, idx);
        buf = buf.slice(idx + 2);
        if (chunk.includes('data:')) {
          count += 1;
          if (count >= maxEvents) {
            clearTimeout(timeout);
            controller.abort();
            return { ok, count };
          }
        }
      }
    }
  } catch (e) {
    error = String(e?.message || e);
  } finally {
    clearTimeout(timeout);
  }
  return { ok, count, error };
}

(async () => {
  const { clients, endpoint, asset, vs, interval } = parseArgs();
  const base = process.env.BASE_URL || 'http://localhost:5000';
  let url = `${base}/api/market/stream/quotes`;
  if (endpoint === 'candles') {
    const params = new URLSearchParams({ asset, vs, interval });
    url = `${base}/api/market/stream/candles?${params.toString()}`;
  }
  console.log(`[LOAD] Target: ${url} | clients=${clients}`);

  const tasks = Array.from({ length: clients }, () => connectSSE(url, { maxEvents: 5, timeoutMs: 15000 }));
  const results = await Promise.all(tasks);
  const okCount = results.filter(r => r.ok).length;
  const totalEvents = results.reduce((acc, r) => acc + (r.count || 0), 0);
  const errors = results.filter(r => r.error);

  console.log(`[LOAD] Connections OK: ${okCount}/${clients}`);
  console.log(`[LOAD] Total events received: ${totalEvents}`);
  if (errors.length) {
    console.log(`[LOAD] Errors (${errors.length}):`);
    errors.slice(0, 5).forEach((e, i) => console.log(`  #${i + 1}: ${e.error}`));
  }
})();
