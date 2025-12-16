#include "state_db_impl.h"
#include <iostream>
#include <random>
#include <chrono>

const std::string DATA_DIR = "data/";
const std::string BLOCKCHAIN_FILE = DATA_DIR + "blockchain.json";
const std::string WALLETS_FILE = DATA_DIR + "wallets.json";
const std::string PRIMARY_ADDRESS = "0x928072b3A3A42e7dFD577a91167DfAa08f0E653E";

// Helper function to check if a file is open and not empty
static bool isFileReadable(std::ifstream& stream) {
    return stream.is_open() && stream.peek() != std::char_traits<char>::eof();
}

StateDBImpl::StateDBImpl() {
    std::error_code ec;
    std::filesystem::create_directories(DATA_DIR, ec);
    loadState();
}

#ifdef HAVE_EVMONE
std::string StateDBImpl::address_to_string(const evmc::address& addr) const {
    char buf[43];
    snprintf(buf, sizeof(buf), "0x%02x%02x%02x%02x...", addr.bytes[0], addr.bytes[1], addr.bytes[2], addr.bytes[3]);
    return std::string(buf);
}
bool StateDBImpl::account_exists(const evmc::address& addr) const { return true; }
uint64_t StateDBImpl::get_balance(const evmc::address& addr) const { return 0; }
void StateDBImpl::set_balance(const evmc::address& addr, uint64_t amount) {}
evmc::bytes32 StateDBImpl::get_storage(const evmc::address& addr, const evmc::bytes32& key) const { return evmc::bytes32{}; }
void StateDBImpl::set_storage(const evmc::address& addr, const evmc::bytes32& key, const evmc::bytes32& value) {}
std::vector<uint8_t> StateDBImpl::get_code(const evmc::address& addr) const { return {}; }
bool StateDBImpl::account_has_code(const evmc::address& addr) const { return false; }
bool StateDBImpl::transfer(const evmc::address& from, const evmc::address& to, uint64_t value) { return true; }
#endif

void StateDBImpl::commit() {
    std::lock_guard<std::mutex> lock(db_mutex);
    std::cout << "[*] Committing state..." << std::endl;
    saveState();
}

// Blockchain operations
int StateDBImpl::getBalance(const std::string &addr) {
    std::lock_guard<std::mutex> lock(db_mutex);
    std::string address = addr.empty() ? PRIMARY_ADDRESS : addr;
    return wallets[address];
}

int StateDBImpl::getBlockCount() const {
    return blockHeight;
}

std::string StateDBImpl::getBlock(int height) {
    std::lock_guard<std::mutex> lock(db_mutex);
    if (blockchain.find(height) != blockchain.end()) {
        json j;
        Block &b = blockchain.at(height);
        j["hash"] = b.hash;
        j["height"] = b.height;
        j["transactions"] = json::array();
        for (auto &tx : b.txs) {
            j["transactions"].push_back({{"from", tx.from}, {"to", tx.to}, {"amount", tx.amount}, {"txid", tx.txid}});
        }
        return j.dump();
    }
    return "{\"error\":\"Block not found\"}";
}

std::string StateDBImpl::sendToAddress(const std::string &to, int amount) {
    std::lock_guard<std::mutex> lock(db_mutex);
    if (wallets[PRIMARY_ADDRESS] < amount) return "{\"error\":\"Insufficient funds\"}";
    wallets[PRIMARY_ADDRESS] -= amount;
    wallets[to] += amount;
    Transaction tx{PRIMARY_ADDRESS, to, "tx" + std::to_string(txCounter++), amount};
    blockchain[blockHeight].txs.push_back(tx);
    saveState();
    return tx.txid;
}

std::string StateDBImpl::getWalletInfo() {
    std::lock_guard<std::mutex> lock(db_mutex);
    json j;
    for (auto &[addr, bal] : wallets) {
        j["addresses"][addr] = bal;
    }
    j["txcount"] = txCounter;
    return j.dump();
}

std::string StateDBImpl::getNewAddress() {
    std::lock_guard<std::mutex> lock(db_mutex);
    static std::mt19937_64 rng(std::random_device{}());
    static std::uniform_int_distribution<int> dist(0, 15);
    std::string addr = "0x";
    for (int i = 0; i < 40; i++) addr += "0123456789ABCDEF"[dist(rng)];
    wallets[addr] = 0;
    saveState();
    return addr;
}

void StateDBImpl::mineBlock() {
    std::lock_guard<std::mutex> lock(db_mutex);
    blockHeight++;
    Block b{blockHeight, "000000block" + std::to_string(blockHeight), {}};
    blockchain[blockHeight] = b;
    wallets[PRIMARY_ADDRESS] += miningReward;
    saveState();
    std::cout << "[*] New block mined. Height: " << blockHeight << std::endl;
}

// DQVE integration implementation
DQVECalculator::DQVEResult StateDBImpl::calculateDQVE() {
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

void StateDBImpl::updateMarketData(const DQVECalculator::MarketData& data) {
    currentMarketData = data;
    marketHistory.push_back(data);
    if (marketHistory.size() > 100) {
        marketHistory.erase(marketHistory.begin());
    }
}

// Private helper methods
void StateDBImpl::saveState() {
    json jchain;
    for (auto &[h, b] : blockchain) {
        json jb;
        jb["hash"] = b.hash;
        jb["height"] = b.height;
        jb["transactions"] = json::array();
        for (auto &tx : b.txs) {
            jb["transactions"].push_back({{"from", tx.from}, {"to", tx.to}, {"amount", tx.amount}, {"txid", tx.txid}});
        }
        jchain[std::to_string(h)] = jb;
    }
    std::ofstream(BLOCKCHAIN_FILE) << jchain.dump(4);
    json jw;
    for (auto &[addr, bal] : wallets) jw[addr] = bal;
    std::ofstream(WALLETS_FILE) << jw.dump(4);
}

void StateDBImpl::loadState() {
    std::ifstream ifs(BLOCKCHAIN_FILE);
    if (isFileReadable(ifs)) {
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
    if (isFileReadable(wifs)) {
        json jw;
        wifs >> jw;
        for (auto &[addr, bal] : jw.items()) wallets[addr] = bal;
        wifs.close();
    }
    if (wallets.find(PRIMARY_ADDRESS) == wallets.end()) wallets[PRIMARY_ADDRESS] = 1000000;
}
