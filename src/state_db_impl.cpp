#include "state_db_impl.h"
#include <iostream>
#if (HAVE_EVMONE)
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
void StateDBImpl::commit() { std::cout << "[*] Committing state..." << std::endl; }

// DQVE integration implementation
DQVECalculator::DQVEResult StateDBImpl::calculateDQVE() {
    if (marketHistory.empty()) {
        // Return default result if no market data available
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

    // Maintain market history (keep last 100 data points)
    marketHistory.push_back(data);
    if (marketHistory.size() > 100) {
        marketHistory.erase(marketHistory.begin());
    }
}
