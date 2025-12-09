/****************************************************
  SpiralCoin SPLC — Full Production Bundle
  Frontend + Backend in one JS
  Ready for PM2 or Node.js
****************************************************/

// ==================== BACKEND ====================

const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const app = express();
const PORT = 4003;

// In-memory SPLC data
let data = {
  users: [
    { username: "Alice", balance: 5000 },
    { username: "Bob", balance: 3000 },
    { username: "Charlie", balance: 1200 }
  ],
  chain: {
    latestBlock: 1,
    totalSupply: 10000,
    marketCap: 48000
  }
};

// Middleware
app.use(cors());
app.use(bodyParser.json());

// ---- API Endpoints ----

// Get all users (Top movers)
app.get("/api/users", (req, res) => res.json(data.users));

// Get chain info
app.get("/api/chain", (req, res) => res.json(data.chain));

// Buy SPLC
app.post("/api/buy", (req, res) => {
  const { wallet, amount } = req.body;
  if (!wallet || !amount) return res.status(400).json({ message: "Invalid request" });

  let user = data.users.find(u => u.username === wallet);
  if (!user) {
    user = { username: wallet, balance: 0 };
    data.users.push(user);
  }
  user.balance += amount;
  data.chain.totalSupply += amount;
  res.json({ message: `${amount} SPLC purchased successfully!` });
});

// Sell SPLC
app.post("/api/sell", (req, res) => {
  const { wallet, amount } = req.body;
  if (!wallet || !amount) return res.status(400).json({ message: "Invalid request" });

  let user = data.users.find(u => u.username === wallet);
  if (!user || user.balance < amount) return res.status(400).json({ message: "Insufficient balance" });

  user.balance -= amount;
  data.chain.totalSupply -= amount;
  res.json({ message: `${amount} SPLC sold successfully!` });
});

// Mine SPLC
app.post("/api/mine", (req, res) => {
  const { wallet } = req.body;
  if (!wallet) return res.status(400).json({ message: "Invalid wallet" });

  let mined = Math.floor(Math.random() * 10) + 1; // random mining reward
  let user = data.users.find(u => u.username === wallet);
  if (!user) {
    user = { username: wallet, balance: 0 };
    data.users.push(user);
  }
  user.balance += mined;
  data.chain.latestBlock += 1;
  data.chain.totalSupply += mined;

  res.json({ message: `You mined ${mined} SPLC!` });
});

// Health check
app.get("/", (req, res) => res.json({ message: "SpiralCoin SPLC Backend Online" }));

// Start backend server
app.listen(PORT, () => {
  console.log(`🚀 SpiralCoin SPLC Backend running on http://localhost:${PORT}`);
});

// ==================== FRONTEND ====================

// Frontend API URL
const API_URL = `http://localhost:${PORT}`;
let userWallet = "";

// ---- Load chain info ----
async function loadChain() {
  try {
    const res = await fetch(`${API_URL}/api/chain`);
    const chain = await res.json();
    document.getElementById("latest-block").innerText = chain.latestBlock;
    document.getElementById("total-supply").innerText = chain.totalSupply;
    document.getElementById("market-cap").innerText = chain.marketCap;
    updateCharts(chain);
  } catch (err) {
    console.error("Error loading chain:", err);
  }
}

// ---- Load users / top movers ----
async function loadUsers() {
  try {
    const res = await fetch(`${API_URL}/api/users`);
    const users = await res.json();
    document.getElementById("top-movers").innerHTML = users
      .map(u => `<div>${u.username} (${u.balance} SPLC)</div>`)
      .join("");
  } catch (err) {
    console.error("Error loading users:", err);
  }
}

// ---- Buy SPLC ----
async function buy(amount) {
  if (!userWallet) return alert("Enter wallet first");
  try {
    const res = await fetch(`${API_URL}/api/buy`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ wallet: userWallet, amount })
    });
    const result = await res.json();
    alert(result.message);
    loadChain();
    loadUsers();
  } catch (err) {
    console.error("Error buying SPLC:", err);
  }
}

// ---- Sell SPLC ----
async function sell(amount) {
  if (!userWallet) return alert("Enter wallet first");
  try {
    const res = await fetch(`${API_URL}/api/sell`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ wallet: userWallet, amount })
    });
    const result = await res.json();
    alert(result.message);
    loadChain();
    loadUsers();
  } catch (err) {
    console.error("Error selling SPLC:", err);
  }
}

// ---- Mine SPLC ----
async function mine() {
  if (!userWallet) return alert("Enter wallet first");
  try {
    const res = await fetch(`${API_URL}/api/mine`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ wallet: userWallet })
    });
    const result = await res.json();
    alert(result.message);
    loadChain();
    loadUsers();
  } catch (err) {
    console.error("Error mining SPLC:", err);
  }
}

// ---- Set wallet ----
function setWallet(address) {
  userWallet = address;
  localStorage.setItem("userWallet", address);
  alert("Wallet set: " + address);
}

// ---- Live updates ----
function startLiveUpdates() {
  loadChain();
  loadUsers();
  setInterval(() => {
    loadChain();
    loadUsers();
  }, 5000);
}

// ---- Attach frontend events ----
window.onload = function () {
  startLiveUpdates();
  document.getElementById("buy-btn").onclick = () => buy(parseFloat(document.getElementById("buy-amount").value));
  document.getElementById("sell-btn").onclick = () => sell(parseFloat(document.getElementById("sell-amount").value));
  document.getElementById("mine-btn").onclick = () => mine();
  document.getElementById("set-wallet-btn").onclick = () => setWallet(document.getElementById("wallet-input").value);
};

// ---- Update Charts Placeholder ----
function updateCharts(chain) {
  // Use this function to feed live chain data to your frontend charts
}
