import express from "express";
import axios from "axios";
import dotenv from "dotenv";
import path from "path";

dotenv.config();
const app = express();
const PORT = process.env.PORT || 8080;

// Serve static files
app.use(express.static(process.cwd()));

// Fetch crypto market data
async function fetchCryptoData() {
  const coins = ['spiralcoin','bitcoin','ethereum','binancecoin','cardano','solana'];
  try {
    const resp = await axios.get(`${process.env.COINGECKO_API}/coins/markets`, {
      params: { vs_currency:'usd', ids: coins.join(','), order:'market_cap_desc', per_page:10 }
    });
    return resp.data;
  } catch(e) {
    return [{id:'error',current_price:0,name:'Error',market_cap:0}];
  }
}

// Fetch trending news
async function fetchNews() {
  try {
    const resp = await axios.get(process.env.NEWS_API);
    return resp.data.data || [];
  } catch(e) {
    return [{title:'Unable to fetch news', url:'#'}];
  }
}

app.get('/', async (req,res)=>{
  const crypto = await fetchCryptoData();
  const news = await fetchNews();
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>SpiralCoin - God Mode Ultra Premium</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<style>
body{margin:0;font-family:Arial,sans-serif;background:#000;color:#f5c518;}
header{display:flex;align-items:center;padding:20px;background:#111;}
header img{height:60px;margin-right:20px;}
h1{font-size:2.5rem;margin:0;}
.container{display:flex;flex-wrap:wrap;padding:20px;gap:20px;}
.left,.right{flex:1 1 45%;min-width:300px;}
.card{background:#111;padding:20px;border-radius:15px;margin-bottom:20px;box-shadow:0 0 15px rgba(0,0,0,0.5);}
h2{margin-top:0;}
.price{font-size:1.8rem;}
.news-item{margin-bottom:10px;}
.news-item a{color:#f5c518;text-decoration:none;}
.ticker{overflow:hidden;white-space:nowrap;border-top:1px solid #333;border-bottom:1px solid #333;padding:10px 0;margin-bottom:20px;}
.ticker span{display:inline-block;padding:0 50px;animation:ticker 5s linear infinite;}
@keyframes ticker{0%{transform:translateX(100%);}100%{transform:translateX(-100%);}}
footer{text-align:center;padding:10px;color:#888;}
canvas{background:#111;border-radius:15px;}
</style>
</head>
<body>
<header>
<img src="${process.env.SPIRALCOIN_LOGO}" alt="SpiralCoin Logo">
<h1>SpiralCoin - God Mode Ultra Premium</h1>
</header>
<div class="ticker">
${crypto.map(c=>`<span>${c.name.toUpperCase()}: $${c.current_price}</span>`).join('')}
</div>
<div class="container">
<div class="left">
<div class="card">
<h2>Live Crypto Prices</h2>
${crypto.map(c=>`<p>${c.name.toUpperCase()}: $${c.current_price} | Market Cap: $${c.market_cap}</p>`).join('')}
</div>
</div>
<div class="right">
<div class="card">
<h2>Latest News</h2>
${news.map(n=>`<div class="news-item"><a href="${n.url}" target="_blank">${n.title}</a></div>`).join('')}
</div>
</div>
</div>
<footer>SpiralCoin © 2025 - God Mode Ultra Premium</footer>
</body>
</html>
  `);
});

app.listen(PORT, () => console.log(`🚀 SpiralCoin God Mode dashboard running on http://localhost:${PORT}`));
