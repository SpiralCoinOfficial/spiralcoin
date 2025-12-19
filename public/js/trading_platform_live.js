// Live data loader for SpiralCoin Exchange homepage and /exchange.trade
(async function() {
  async function fetchQuotes() {
    try {
      const res = await fetch('/api/market/quotes');
      const data = await res.json();
      if (data.SPRC) {
        document.getElementById('spc-usdt-price').textContent = `$${data.SPRC.usd?.toFixed(4) ?? '—'}`;
        document.getElementById('spc-usd-price').textContent = `$${data.SPRC.usd?.toFixed(4) ?? '—'}`;
        // Add more pairs if available
      }
    } catch (e) {}
  }
  fetchQuotes();
  setInterval(fetchQuotes, 10000);
  // TODO: Add SSE and chart live updates as in trading_platform.html
})();
