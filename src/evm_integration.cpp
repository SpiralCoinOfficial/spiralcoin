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
void run_evm_logic(...) { std::cout << "[*] EVMONE not available. Skipping EVM logic." << std::endl; }
#endif
