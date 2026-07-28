import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

let walletBalance = 1000;
let splcData = { price: 1.25, marketCap: 1250000 };

app.get('/api/wallet', (req, res) => {
    res.json({ balance: walletBalance });
});

app.get('/api/market', (req, res) => {
    res.json({
        SPLC: { price: splcData.price, marketCap: splcData.marketCap },
        BTC: { price: 65000, marketCap: 1280000000 },
        ETH: { price: 3500, marketCap: 420000000 }
    });
});

app.post('/api/buy', (req, res) => {
    const { amount } = req.body;
    const parsedAmount = parseFloat(amount) || 0;
    walletBalance += parsedAmount;
    res.json({ success: true, message: `Successfully bought ${parsedAmount} SPLC!` });
});

app.post('/api/sell', (req, res) => {
    const { amount } = req.body;
    const parsedAmount = parseFloat(amount) || 0;
    if (walletBalance >= parsedAmount) {
        walletBalance -= parsedAmount;
        res.json({ success: true, message: `Successfully sold ${parsedAmount} SPLC!` });
    } else {
        res.status(400).json({ success: false, message: 'Insufficient SPLC balance!' });
    }
});

app.post('/api/mine', (req, res) => {
    walletBalance += 10;
    res.json({ success: true, message: 'Mined 10 SPLC successfully!' });
});

app.listen(PORT, () => {
    console.log(`SpiralCoin server running at http://localhost:${PORT}`);
});
