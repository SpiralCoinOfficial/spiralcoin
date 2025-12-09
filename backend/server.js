const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const fs = require("fs");

const app = express();
const PORT = 4003;
const DATA_FILE = "./data.json";

app.use(cors());
app.use(bodyParser.json());

// --------------------
// Load & Save Data
// --------------------
function loadData() {
  if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(DATA_FILE, JSON.stringify({ users: [], chain: { latestBlock: 0, totalSupply: 1000000000, marketCap: 4800000000 } }, null, 2));
  }
  return JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
}

function saveData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

// --------------------
// DQVE formula
// --------------------
function DQVE({ balance, totalSupply, marketCap, blockNumber, userActivity }) {
  const k1 = 0.0001, k2 = 0.05, k3 = 0.1, k4 = 1, k5 = 0.5;
  return (
    k1 * balance ** 2 +
    k2 * totalSupply +
    k3 * marketCap +
    k4 * Math.log(blockNumber + 1) +
    k5 * Math.sqrt(userActivity + 1)
  );
}

function calculateMiningReward(user, chain) {
  return Math.max(1, Math.floor(DQVE({
    balance: user.balance,
    totalSupply: chain.totalSupply,
    marketCap: chain.marketCap,
    blockNumber: chain.latestBlock,
    userActivity: user.activity || 0
  }) / 100));
}

// --------------------
// API Endpoints
// --------------------
app.get("/api/users", (req, res) => {
  const data = loadData();
  const usersWithDQVE = data.users.map(u => ({
    username: u.username,
    balance: u.balance,
    activity: u.activity,
    dqve: DQVE({
      balance: u.balance,
      totalSupply: data.chain.totalSupply,
      marketCap: data.chain.marketCap,
      blockNumber: data.chain.latestBlock,
      userActivity: u.activity
    })
  }));
  res.json(usersWithDQVE);
});

app.get("/api/chain", (req, res) => {
  const data = loadData();
  res.json(data.chain);
});

app.post("/api/buy", (req, res) => {
  const { wallet, amount } = req.body;
  if (!wallet || !amount) return res.status(400).json({ message: "Invalid request" });

  const data = loadData();
  let user = data.users.find(u => u.username === wallet);
  if (!user) { user = { username: wallet, balance: 0, activity: 0 }; data.users.push(user); }

  user.balance += amount;
  user.activity += 1;
  data.chain.totalSupply += amount;

  saveData(data);
  res.json({ message: `${amount} SPLC purchased!`, balance: user.balance });
});

app.post("/api/sell", (req, res) => {
  const { wallet, amount } = req.body;
  if (!wallet || !amount) return res.status(400).json({ message: "Invalid request" });

  const data = loadData();
  let user = data.users.find(u => u.username === wallet);
  if (!user || user.balance < amount) return res.status(400).json({ message: "Insufficient balance" });

  user.balance -= amount;
  user.activity += 1;
  data.chain.totalSupply -= amount;

  saveData(data);
  res.json({ message: `${amount} SPLC sold!`, balance: user.balance });
});

app.post("/api/mine", (req, res) => {
  const { wallet } = req.body;
  if (!wallet) return res.status(400).json({ message: "Invalid wallet" });

  const data = loadData();
  let user = data.users.find(u => u.username === wallet);
  if (!user) { user = { username: wallet, balance: 0, activity: 0 }; data.users.push(user); }

  const reward = calculateMiningReward(user, data.chain);
  user.balance += reward;
  user.activity += 1;
  data.chain.latestBlock += 1;
  data.chain.totalSupply += reward;

  saveData(data);
  res.json({ message: `You mined ${reward} SPLC!`, balance: user.balance, reward });
});

// --------------------
// Start server
// --------------------
app.listen(PORT, () => console.log(`🚀 SpiralCoin SPLC backend live on port ${PORT}`));
