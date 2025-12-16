#pragma once
#include "state_db.h"
#include <vector>
#include <map>
#include <string>
#include <fstream>
#include <filesystem>
#include <mutex>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

struct Transaction {
    std::string from, to, txid;
    int amount;
};

struct Block {
    int height;
    std::string hash;
    std::vector<Transaction> txs;
};

class StateDBImpl : public StateDB {
public:
    StateDBImpl();

#ifdef HAVE_EVMONE
    std::string address_to_string(const evmc::address& addr) const override;
    bool account_exists(const evmc::address& addr) const override;
    uint64_t get_balance(const evmc::address& addr) const override;
    void set_balance(const evmc::address& addr, uint64_t amount) override;
    evmc::bytes32 get_storage(const evmc::address& addr, const evmc::bytes32& key) const override;
    void set_storage(const evmc::address& addr, const evmc::bytes32& key, const evmc::bytes32& value) override;
    std::vector<uint8_t> get_code(const evmc::address& addr) const override;
    bool account_has_code(const evmc::address& addr) const override;
    bool transfer(const evmc::address& from, const evmc::address& to, uint64_t value) override;
#endif
    void commit() override;

    // DQVE integration
    DQVECalculator::DQVEResult calculateDQVE() override;
    void updateMarketData(const DQVECalculator::MarketData& data) override;

    // Blockchain operations
    int getBalance(const std::string &addr = "");
    int getBlockCount() const;
    std::string getBlock(int height);
    std::string sendToAddress(const std::string &to, int amount);
    std::string getWalletInfo();
    std::string getNewAddress();
    void mineBlock();

private:
    int blockHeight = 1;
    int txCounter = 0;
    int miningReward = 50;
    std::map<int, Block> blockchain;
    std::map<std::string, int> wallets;
    DQVECalculator dqveCalculator;
    std::vector<DQVECalculator::MarketData> marketHistory;
    DQVECalculator::MarketData currentMarketData;
    std::mutex db_mutex;

    void saveState();
    void loadState();
};
