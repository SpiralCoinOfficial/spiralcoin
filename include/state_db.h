#pragma once
#include <string>
#include <vector>
#include <cstdint>
#include "dqve_calculator.h"
#if HAVE_EVMONE
#include <evmone/evmone.h>
#endif
class StateDB {
public:
    virtual ~StateDB() = default;
#if HAVE_EVMONE
    virtual std::string address_to_string(const evmc::address& addr) const = 0;
    virtual bool account_exists(const evmc::address& addr) const = 0;
    virtual uint64_t get_balance(const evmc::address& addr) const = 0;
    virtual void set_balance(const evmc::address& addr, uint64_t amount) = 0;
    virtual evmc::bytes32 get_storage(const evmc::address& addr, const evmc::bytes32& key) const = 0;
    virtual void set_storage(const evmc::address& addr, const evmc::bytes32& key, const evmc::bytes32& value) = 0;
    virtual std::vector<uint8_t> get_code(const evmc::address& addr) const = 0;
    virtual bool account_has_code(const evmc::address& addr) const = 0;
    virtual bool transfer(const evmc::address& from, const evmc::address& to, uint64_t value) = 0;
#endif
    virtual void commit() = 0;

    // DQVE integration
    virtual DQVECalculator::DQVEResult calculateDQVE() = 0;
    virtual void updateMarketData(const DQVECalculator::MarketData& data) = 0;
};
