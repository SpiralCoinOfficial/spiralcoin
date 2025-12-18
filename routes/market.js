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

// Server-Sent Events stream for price updates (~20 Hz)
marketRouter.get("/stream", (req, res) => {
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.flushHeaders?.();

    const send = () => {
        const payload = JSON.stringify({ price: currentPrice, ts: Date.now() });
        res.write(`data: ${payload}\n\n`);
    };
    // Send an initial event promptly
    send();
    // Stream at ~50ms interval (~20 Hz)
    const interval = setInterval(send, 50);

    req.on("close", () => {
        clearInterval(interval);
        try { res.end(); } catch {}
    });
});
