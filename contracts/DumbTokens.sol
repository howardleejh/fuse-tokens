// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

/// @title ERC20 DUMB Tokens
/// @author Howard Lee
/// @notice ERC20 Token contract deployed for DAO, staking and NFT minting

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DumbTokens is ERC20, Ownable {
    uint256 initialSupply = 1_000_000_000 ether;

    constructor(address _address) ERC20("DUMB Tokens", "DUMB") {
        _mint(_address, initialSupply);
    }

    function mint(address _address, uint256 _amount) external onlyOwner {
        _mint(_address, _amount);
    }

    function burn(address _address, uint256 _amount) external onlyOwner {
        _burn(_address, _amount);
    }
}
