#!/usr/bin/env node
/*
  Production TLS Checker
  - Attempts an HTTPS request with normal verification (should succeed if chain/trust is correct)
  - Opens a raw TLS socket with rejectUnauthorized=false to extract protocol, cipher, and peer cert chain
  - Prints a concise report

  Usage: node scripts/prod_tls_check.js --host www.spiralcoin.net --port 443
*/
import https from 'https';
import tls from 'tls';

function parseArgs() {
  const args = process.argv.slice(2);
  const out = { host: 'www.spiralcoin.net', port: 443 };
  for (let i = 0; i < args.length; i++) {
    const k = args[i];
    if (k === '--host' && args[i + 1]) { out.host = args[++i]; }
    else if (k === '--port' && args[i + 1]) { out.port = Number(args[++i]); }
  }
  return out;
}

function tryHttpsHead(host) {
  return new Promise((resolve) => {
    const opts = { method: 'HEAD', host, port: 443, path: '/', timeout: 8000 };
    const req = https.request(opts, (res) => {
      resolve({ ok: true, statusCode: res.statusCode, headers: res.headers });
    });
    req.on('error', (err) => resolve({ ok: false, error: String(err) }));
    req.on('timeout', () => { req.destroy(new Error('Timeout')); });
    req.end();
  });
}

function getChain(cert) {
  const chain = [];
  let cur = cert;
  const seen = new Set();
  while (cur && typeof cur === 'object') {
    const key = `${cur.subject?.CN || ''}|${cur.issuer?.CN || ''}|${cur.fingerprint || ''}`;
    if (seen.has(key)) break;
    seen.add(key);
    chain.push({
      subject: cur.subject,
      issuer: cur.issuer,
      valid_from: cur.valid_from,
      valid_to: cur.valid_to,
      fingerprint: cur.fingerprint,
      serialNumber: cur.serialNumber
    });
    cur = cur.issuerCertificate && cur.issuerCertificate !== cur ? cur.issuerCertificate : null;
  }
  return chain;
}

function tlsInspect(host, port) {
  return new Promise((resolve) => {
    const s = tls.connect({ host, port, servername: host, rejectUnauthorized: false }, () => {
      const proto = s.getProtocol?.() || null;
      const cipher = s.getCipher?.() || null;
      const ocsp = s.getOCSPResponse ? (s.getOCSPResponse() ? true : false) : null;
      const cert = s.getPeerCertificate(true);
      const chain = getChain(cert);
      s.end();
      resolve({ protocol: proto, cipher, ocspStapling: ocsp, chain });
    });
    s.on('error', (err) => resolve({ error: String(err) }));
    s.setTimeout(8000, () => { s.destroy(new Error('Timeout')); });
  });
}

(async () => {
  const { host, port } = parseArgs();
  console.log(`[TLS] Checking https://${host}:${port}`);

  const head = await tryHttpsHead(host);
  if (head.ok) {
    console.log(`[TLS] HTTPS request OK: ${head.statusCode}`);
  } else {
    console.log(`[TLS] HTTPS request FAILED: ${head.error}`);
  }

  const info = await tlsInspect(host, port);
  if (info.error) {
    console.log(`[TLS] TLS inspect error: ${info.error}`);
  } else {
    console.log(`[TLS] Protocol: ${info.protocol || 'n/a'}`);
    console.log(`[TLS] Cipher: ${info.cipher?.name || 'n/a'}`);
    console.log(`[TLS] OCSP stapling present: ${info.ocspStapling === true ? 'yes' : 'no'}`);
    console.log(`[TLS] Chain:`);
    info.chain.forEach((c, i) => {
      console.log(`  #${i + 1} Subject CN=${c.subject?.CN || ''} | Issuer CN=${c.issuer?.CN || ''} | valid ${c.valid_from} -> ${c.valid_to}`);
    });
  }
})();
