#if (HAVE_EVMONE)
#include "state_db_impl.h"
#include <evmone/evmone.h>
#include <iostream>
void run_evm_logic(StateDBImpl& db) {
    std::cout << "[*] Running optional EVM logic..." << std::endl;
    evmc::address addr{};
    uint64_t balance = db.get_balance(addr);
    std::cout << "Balance: " << balance << std::endl;
}
#else
#include <iostream>
// Forward declaration to avoid including EVM-specific headers when EVMONE is not available.
class StateDBImpl;

// Provide a stub with the same signature so callers don't need to be gated on HAVE_EVMONE.
void run_evm_logic(StateDBImpl& /*db*/) {
    std::cout << "[*] EVMONE not available. Skipping EVM logic." << std::endl;
}
#endif
