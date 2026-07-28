const API_BASE = "/api";

// --- Fetch Wallet Balance ---
async function fetchWallet() {
    const res = await fetch(`${API_BASE}/wallet`);
    const data = await res.json();
    document.getElementById("walletBalance").innerText = data.balance;
}

// --- Fetch Live Market Data ---
async function fetchMarket() {
    const res = await fetch(`${API_BASE}/market`);
    const data = await res.json();
    document.getElementById("splcPrice").innerText = data.SPLC.price;
    document.getElementById("splcMarketCap").innerText = data.SPLC.marketCap;
    document.getElementById("btcPrice").innerText = data.BTC.price;
    document.getElementById("btcMarketCap").innerText = data.BTC.marketCap;
    document.getElementById("ethPrice").innerText = data.ETH.price;
    document.getElementById("ethMarketCap").innerText = data.ETH.marketCap;
}

// --- Buy/Sell/Mine ---
async function buySPLC() {
    const amount = document.getElementById("buyAmount").value;
    const res = await fetch(`${API_BASE}/buy`, { method:"POST", headers:{'Content-Type':'application/json'}, body:JSON.stringify({amount}) });
    const result = await res.json();
    alert(result.message);
    fetchWallet();
}
async function sellSPLC() {
    const amount = document.getElementById("sellAmount").value;
    const res = await fetch(`${API_BASE}/sell`, { method:"POST", headers:{'Content-Type':'application/json'}, body:JSON.stringify({amount}) });
    const result = await res.json();
    alert(result.message);
    fetchWallet();
}
async function mineSPLC() {
    const res = await fetch(`${API_BASE}/mine`, { method:"POST" });
    const result = await res.json();
    alert(result.message);
    fetchWallet();
}

// --- Event Listeners ---
document.getElementById("buyButton").addEventListener("click", buySPLC);
document.getElementById("sellButton").addEventListener("click", sellSPLC);
document.getElementById("mineButton").addEventListener("click", mineSPLC);

// --- Auto Refresh ---
setInterval(fetchWallet, 5000);
setInterval(fetchMarket, 5000);
fetchWallet();
fetchMarket();
