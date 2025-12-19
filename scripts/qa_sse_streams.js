#!/usr/bin/env node
/*
  SSE QA: reads a few events from quotes and candles SSE endpoints and prints them.
  Requires Node >= 18 (global fetch, web streams).
*/

async function readSSE(url, { maxEvents = 5, timeoutMs = 15000 } = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  let count = 0;

  console.log(`\n[QA] Connecting to SSE: ${url}`);
  const res = await fetch(url, {
    headers: { 'Accept': 'text/event-stream' },
    signal: controller.signal,
    cache: 'no-store'
  });
  console.log(`[QA] Status: ${res.status} ${res.statusText} | CT: ${res.headers.get('content-type')}`);

  const reader = res.body.getReader();
  const decoder = new TextDecoder('utf-8');
  let buf = '';

  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buf += decoder.decode(value, { stream: true });
      // Split events by blank line separators (\n\n)
      let idx;
      while ((idx = buf.indexOf('\n\n')) >= 0) {
        const chunk = buf.slice(0, idx);
        buf = buf.slice(idx + 2);
        const lines = chunk.split('\n');
        const dataLines = lines
          .filter(l => l.startsWith('data:'))
          .map(l => l.slice(5).trim())
          .join('\n');
        if (dataLines) {
          try {
            const obj = JSON.parse(dataLines);
            console.log(`[QA] Event ${count + 1}:`, JSON.stringify(obj).slice(0, 500));
          } catch (_) {
            console.log(`[QA] Event ${count + 1} (raw):`, dataLines);
          }
          count += 1;
          if (count >= maxEvents) {
            clearTimeout(timeout);
            controller.abort();
            return;
          }
        }
      }
    }
  } catch (e) {
    console.log(`[QA] Stream ended: ${e?.name || e}`);
  } finally {
    clearTimeout(timeout);
  }
}

async function main() {
  const base = process.env.BASE_URL || 'http://localhost:5000';
  console.log(`[QA] Using BASE_URL=${base}`);

  await readSSE(`${base}/api/market/stream/quotes`, { maxEvents: 3, timeoutMs: 10000 });
  await readSSE(`${base}/api/market/stream/candles?asset=SPRC&vs=USD&interval=1m`, { maxEvents: 3, timeoutMs: 10000 });

  console.log('\n[QA] SSE streams check done.');
}

main().catch(err => {
  console.error('[QA] Error:', err);
  process.exitCode = 1;
});
