// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// SpiralCoin ERC20/BEP20 token implementation
// Name/symbol/supply are configured via deployment script.
contract SPRC is ERC20, Ownable {
    uint8 private immutable _customDecimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner_,
        uint256 initialSupply_ // already scaled to decimals
    ) ERC20(name_, symbol_) Ownable(owner_) {
        _customDecimals = decimals_;
        if (initialSupply_ > 0) {
            _mint(owner_, initialSupply_);
        }
    }

    function decimals() public view override returns (uint8) {
        return _customDecimals;
    }
}
