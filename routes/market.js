import express from "express";
export const marketRouter = express.Router();

let currentPrice = 0.05;

marketRouter.get("/price", (req, res) => {
    res.json({ price: currentPrice });
});

marketRouter.post("/update", (req, res) => {
    const { price } = req.body;
    if (typeof price === "number" && price > 0) {
        currentPrice = price;
        res.json({ price: currentPrice });
    } else {
        res.status(400).json({ error: "Invalid price" }); 
 }
});
