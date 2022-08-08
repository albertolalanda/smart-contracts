// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

/// @title A token to buy the NumbersNFT
/// @author Alberto Lalanda
/// @notice Capped supply at 1 million. Contract inheriting from OpenZeppelin contracts.
contract Num is ERC20, Ownable, ERC20Capped, ERC20Permit {
    /// @notice Max supply capped on one million, hardcoded
    constructor()
        ERC20("NumbersCoin", "NUM")
        ERC20Capped(1_000_000 * 10**decimals())
        ERC20Permit("NumbersCoin")
    {
        ERC20._mint(msg.sender, 100 * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(account, amount);
    }
}
