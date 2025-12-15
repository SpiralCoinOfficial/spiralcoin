#include <iostream>
#include <thread>
#include <chrono>
#include <csignal>
#include <mutex>
#include <vector>
#include <string>
#include <map>
#include <fstream>
#include <random>
#include <filesystem>
#include "httplib.h"
#include <nlohmann/json.hpp>
#include "dqve_calculator.h"

using json = nlohmann::json;

bool running = true;
std::mutex db_mutex;
const std::string DATA_DIR = "data/";
const std::string BLOCKCHAIN_FILE = DATA_DIR + "blockchain.json";
const std::string WALLETS_FILE = DATA_DIR + "wallets.json";
const std::string PRIMARY_ADDRESS = "0x928072b3A3A42e7dFD577a91167DfAa08f0E653E";
const std::string SUPPLY_WALLET = "0xSPRC1111111111111111111111111111SupplyVault";
const long long INITIAL_SUPPLY = 20000000000000LL; // 20 trillion SPRC

struct Transaction { std::string from, to, txid; int amount; };
struct Block { int height; std::string hash; std::vector<Transaction> txs; };

class StateDBImpl {
public:
    StateDBImpl() {
        std::error_code ec;
        std::filesystem::create_directories(DATA_DIR, ec);
        loadState();
    }

    void commit() { std::lock_guard<std::mutex> lock(db_mutex); saveState(); }
    int getBalance(const std::string &addr = PRIMARY_ADDRESS) {
        std::lock_guard<std::mutex> lock(db_mutex);
        return wallets[addr];
    }
    int getBlockCount() { return blockHeight; }

    std::string getBlock(int height) {
        std::lock_guard<std::mutex> lock(db_mutex);
        if (blockchain.find(height) != blockchain.end()) {
            json j;
            Block &b = blockchain[height];
            j["hash"] = b.hash;
            j["height"] = b.height;
            j["transactions"] = json::array();
            for (auto &tx : b.txs) j["transactions"].push_back({{"from", tx.from}, {"to", tx.to}, {"amount", tx.amount}, {"txid", tx.txid}});
            return j.dump();
        }
        return "{\"error\":\"Block not found\"}";
    }

    std::string sendToAddress(const std::string &to, int amount) {
        std::lock_guard<std::mutex> lock(db_mutex);
        if (wallets[PRIMARY_ADDRESS] < amount) return "{\"error\":\"Insufficient funds\"}";
        wallets[PRIMARY_ADDRESS] -= amount;
        wallets[to] += amount;
        Transaction tx{PRIMARY_ADDRESS, to, "tx" + std::to_string(txCounter++), amount};
        blockchain[blockHeight].txs.push_back(tx);
        saveState();
        return tx.txid;
    }

    std::string getWalletInfo() {
        std::lock_guard<std::mutex> lock(db_mutex);
        json j;
        for (auto &[addr, bal] : wallets) j["addresses"][addr] = bal;
        j["txcount"] = txCounter;
        return j.dump();
    }

    std::string getNewAddress() {
        std::lock_guard<std::mutex> lock(db_mutex);
        static std::mt19937_64 rng(std::random_device{}());
        static std::uniform_int_distribution<int> dist(0, 15);
        std::string addr = "0x";
        for (int i = 0; i < 40; i++) addr += "0123456789ABCDEF"[dist(rng)];
        wallets[addr] = 0;
        saveState();
        return addr;
    }

    void mineBlock() {
        std::lock_guard<std::mutex> lock(db_mutex);
        blockHeight++;
        Block b{blockHeight, "000000block" + std::to_string(blockHeight), {}};
        blockchain[blockHeight] = b;
        wallets[PRIMARY_ADDRESS] += miningReward;
        saveState();
        std::cout << "[*] New block mined. Height: " << blockHeight << std::endl;
    }

    // DQVE methods
    DQVECalculator::DQVEResult calculateDQVE() {
        if (marketHistory.empty()) {
            DQVECalculator::DQVEResult result;
            result.valuation = currentMarketData.price;
            result.confidence = 0.0;
            result.trendStrength = 0.0;
            result.momentum = 0.0;
            result.recommendation = "INSUFFICIENT_DATA";
            result.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
            return result;
        }
        return dqveCalculator.calculateDQVE(marketHistory, currentMarketData);
    }

    void updateMarketData(const DQVECalculator::MarketData &data) {
        currentMarketData = data;
        marketHistory.push_back(data);
        if (marketHistory.size() > 100) {
            marketHistory.erase(marketHistory.begin());
        }
    }

private:
    int blockHeight = 1, txCounter = 0, miningReward = 50;
    std::map<int, Block> blockchain;
    std::map<std::string, int> wallets;
    DQVECalculator dqveCalculator;
    std::vector<DQVECalculator::MarketData> marketHistory;
    DQVECalculator::MarketData currentMarketData;

    void saveState() {
        json jchain;
        for (auto &[h, b] : blockchain) {
            json jb;
            jb["hash"] = b.hash;
            jb["height"] = b.height;
            jb["transactions"] = json::array();
            for (auto &tx : b.txs) jb["transactions"].push_back({{"from", tx.from}, {"to", tx.to}, {"amount", tx.amount}, {"txid", tx.txid}});
            jchain[std::to_string(h)] = jb;
        }
        std::ofstream(BLOCKCHAIN_FILE) << jchain.dump(4);
        json jw;
        for (auto &[addr, bal] : wallets) jw[addr] = bal;
        std::ofstream(WALLETS_FILE) << jw.dump(4);
    }

    void loadState() {
        std::ifstream ifs(BLOCKCHAIN_FILE);
        if (ifs.is_open()) {
            json j;
            ifs >> j;
            for (auto &[k, v] : j.items()) {
                Block b;
                b.height = v["height"];
                b.hash = v["hash"];
                for (auto &txj : v["transactions"]) {
                    Transaction tx;
                    tx.from = txj["from"];
                    tx.to = txj["to"];
                    tx.amount = txj["amount"];
                    tx.txid = txj["txid"];
                    b.txs.push_back(tx);
                }
                blockchain[b.height] = b;
            }
            blockHeight = blockchain.rbegin()->first;
            ifs.close();
        } else {
            blockchain[1] = {1, "000000genesis", {}};
            blockHeight = 1;
        }
        std::ifstream wifs(WALLETS_FILE);
        if (wifs.is_open()) {
            json jw;
            wifs >> jw;
            for (auto &[addr, bal] : jw.items()) wallets[addr] = bal;
            wifs.close();
        }
        if (wallets.find(PRIMARY_ADDRESS) == wallets.end()) wallets[PRIMARY_ADDRESS] = 1000000;
    }
};

StateDBImpl db;

void signalHandler(int signum) {
    std::cout << "\n[!] Caught signal " << signum << ", shutting down SpiralCoin...\n";
    running = false;
}

// RPC method handlers
json handleGetBalance(const json &jreq) {
    std::string addr = jreq["params"].empty() ? PRIMARY_ADDRESS : jreq["params"][0].get<std::string>();
    return {{"result", db.getBalance(addr)}};
}

json handleGetWalletInfo(const json &jreq) {
    return {{"result", json::parse(db.getWalletInfo())}};
}

json handleSendToAddress(const json &jreq) {
    if (jreq["params"].size() < 2) {
        return {{"error", "Invalid parameters"}};
    }
    std::string to = jreq["params"][0].get<std::string>();
    int amount = jreq["params"][1].get<int>();
    return {{"result", db.sendToAddress(to, amount)}};
}

json handleGetNewAddress(const json &jreq) {
    return {{"result", db.getNewAddress()}};
}

json handleGetBlockCount(const json &jreq) {
    return {{"result", db.getBlockCount()}};
}

json handleGetBlock(const json &jreq) {
    if (jreq["params"].empty()) {
        return {{"error", "Block height required"}};
    }
    int h = jreq["params"][0].get<int>();
    return {{"result", json::parse(db.getBlock(h))}};
}

json handleGetInfo(const json &jreq) {
    return {{"result", {{"status", "SpiralCoin Node OK"}, {"blocks", db.getBlockCount()}, {"connections", 1}}}};
}

json handleGetDQVE(const json &jreq) {
    auto dqveResult = db.calculateDQVE();
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
        db.updateMarketData(marketData);
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

    std::thread rpcThread(setupRPCServer);

    // Mining loop
    while (running) {
        std::this_thread::sleep_for(std::chrono::seconds(10));
        if (running) db.mineBlock();
    }

    rpcThread.join();
    return 0;
}
