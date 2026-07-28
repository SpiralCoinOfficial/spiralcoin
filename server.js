require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const User = require('./models/User');

const app = express();
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/spiralcoin';

app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Connect to MongoDB
mongoose.connect(MONGO_URI)
  .then(() => console.log('MongoDB connected successfully'))
  .catch(err => console.error('MongoDB connection error:', err));

app.get('/api/status', (req, res) => {
  res.json({ status: 'online', project: 'SPIRALCOIN (SPLC)' });
});

// User profile / allocation route
app.post('/api/user', async (req, res) => {
  try {
    const { username, walletAddress } = req.body;
    let user = await User.findOne({ walletAddress });
    if (!user) {
      user = new User({ username, walletAddress, splcBalance: 1000 });
      await user.save();
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`SpiralCoin backend running on port ${PORT}`);
});
