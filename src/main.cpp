#include <iostream>
#include <thread>
#include <chrono>
#include <csignal>
#include <mutex>

// Set Windows SDK version for httplib compatibility
#define _WIN32_WINNT 0x0A00  // Windows 10 or later

#include "httplib.h"
#include <nlohmann/json.hpp>
#include "dqve_calculator.h"
#include "state_db_impl.h"

using json = nlohmann::json;

bool running = true;

// Global database instance
StateDBImpl* db = nullptr;

void signalHandler(int signum) {
    std::cout << "\n[!] Caught signal " << signum << ", shutting down SpiralCoin...\n";
    running = false;
}

// RPC method handlers
json handleGetBalance(const json &jreq) {
    std::string addr = jreq["params"].empty() ? "" : jreq["params"][0].get<std::string>();
    return {{"result", db->getBalance(addr)}};
}

json handleGetWalletInfo(const json &jreq) {
    return {{"result", json::parse(db->getWalletInfo())}};
}

json handleSendToAddress(const json &jreq) {
    if (jreq["params"].size() < 2) {
        return {{"error", "Invalid parameters"}};
    }
    std::string to = jreq["params"][0].get<std::string>();
    int amount = jreq["params"][1].get<int>();
    return {{"result", db->sendToAddress(to, amount)}};
}

json handleGetNewAddress(const json &jreq) {
    return {{"result", db->getNewAddress()}};
}

json handleGetBlockCount(const json &jreq) {
    return {{"result", db->getBlockCount()}};
}

json handleGetBlock(const json &jreq) {
    if (jreq["params"].empty()) {
        return {{"error", "Block height required"}};
    }
    int h = jreq["params"][0].get<int>();
    return {{"result", json::parse(db->getBlock(h))}};
}

json handleGetInfo(const json &jreq) {
    return {{"result", {{"status", "SpiralCoin Node OK"}, {"blocks", db->getBlockCount()}, {"connections", 1}}}};
}

json handleGetDQVE(const json &jreq) {
    auto dqveResult = db->calculateDQVE();
    json dqveJson;
    dqveJson["valuation"] = dqveResult.valuation;
    dqveJson["confidence"] = dqveResult.confidence;
    dqveJson["trend_strength"] = dqveResult.trendStrength;
    dqveJson["momentum"] = dqveResult.momentum;
    dqveJson["recommendation"] = dqveResult.recommendation;
    dqveJson["factors"] = dqveResult.factors;
    dqveJson["timestamp"] = dqveResult.timestamp;
    return {{"result", dqveJson}};
}

json handleUpdateDQVE(const json &jreq) {
    if (jreq["params"].size() < 5) {
        return {{"error", "Insufficient parameters for market data update"}};
    }
    try {
        DQVECalculator::MarketData marketData;
        marketData.price = jreq["params"][0].get<double>();
        marketData.volume = jreq["params"][1].get<double>();
        marketData.marketCap = jreq["params"][2].get<double>();
        marketData.volatility = jreq["params"][3].get<double>();
        marketData.liquidity = jreq["params"][4].get<double>();
        marketData.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
        db->updateMarketData(marketData);
        return {{"result", "Market data updated successfully"}};
    } catch (const std::exception &e) {
        return {{"error", std::string("Parameter parsing error: ") + e.what()}};
    }
}

void setupRPCServer() {
    httplib::Server svr;
    svr.Post("/rpc", [](const httplib::Request &req, httplib::Response &res) {
        try {
            auto jreq = json::parse(req.body);
            json jres;
            jres["id"] = jreq["id"];
            std::string method = jreq["method"].get<std::string>();

            if (method == "getbalance") {
                jres = handleGetBalance(jreq);
            } else if (method == "getwalletinfo") {
                jres = handleGetWalletInfo(jreq);
            } else if (method == "sendtoaddress") {
                jres = handleSendToAddress(jreq);
            } else if (method == "getnewaddress") {
                jres = handleGetNewAddress(jreq);
            } else if (method == "getblockcount") {
                jres = handleGetBlockCount(jreq);
            } else if (method == "getblock") {
                jres = handleGetBlock(jreq);
            } else if (method == "getinfo") {
                jres = handleGetInfo(jreq);
            } else if (method == "getdqve") {
                jres = handleGetDQVE(jreq);
            } else if (method == "updatedqve") {
                jres = handleUpdateDQVE(jreq);
            } else {
                jres["error"] = "Unknown method";
            }

            res.set_content(jres.dump(), "application/json");
        } catch (const std::exception &e) {
            json errorRes = {{"error", std::string("RPC error: ") + e.what()}};
            res.set_content(errorRes.dump(), "application/json");
        }
    });

    std::cout << "[*] Starting RPC server on port 8545..." << std::endl;
    svr.listen("0.0.0.0", 8545);
}

int main() {
    std::signal(SIGINT, signalHandler);
    std::signal(SIGTERM, signalHandler);

    try {
        db = new StateDBImpl();
        std::cout << "[*] Database initialized successfully" << std::endl;
    } catch (const std::exception &e) {
        std::cerr << "[ERROR] Failed to initialize database: " << e.what() << std::endl;
        return 1;
    }

    std::thread rpcThread(setupRPCServer);

    // Mining loop
    while (running) {
        std::this_thread::sleep_for(std::chrono::seconds(10));
        if (running && db) db->mineBlock();
    }

    if (db) delete db;
    rpcThread.join();
    return 0;
}
