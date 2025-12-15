#pragma once
#include "state_db.h"
#include <vector>
class StateDBImpl : public StateDB {
public:
#if HAVE_EVMONE
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

private:
    DQVECalculator dqveCalculator;
    std::vector<DQVECalculator::MarketData> marketHistory;
    DQVECalculator::MarketData currentMarketData;
};
