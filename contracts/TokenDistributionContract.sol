// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

/// @title Token Distribution Contract to allow users to mint DUMB Tokens
/// @author Howard Lee
/// @notice Contract is used to allow users to mint DUMB Tokens and record user reward info.

import "./DumbTokens.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenDistributionContract is Ownable, ReentrancyGuard {
    /// @dev struct to store user rewards data
    struct userInfo {
        uint256 nextMint;
        uint256 totalReward;
        uint256 rewardRemaining;
        uint256 rewardWithdrawn;
    }

    DumbTokens public immutable tokens;
    mapping(address => userInfo) public users;
    /// @dev this is the period of 1 day, users allowed to mint tokens once per day only.
    uint256 constant period = 86400;

    event rewardGiven(
        uint256 indexed _timestamp,
        address indexed _address,
        uint256 _reward
    );
    event userWithdrawn(
        uint256 indexed _timestamp,
        address indexed _address,
        uint256 _amount
    );
    event supplyCreated(uint256 indexed _timestamp, uint256 _amount);
    event supplyBurned(uint256 indexed _timestamp, uint256 _amount);

    /// @dev init DUMB tokens and mint total supply of tokens to this contract
    constructor() {
        tokens = new DumbTokens(address(this));
    }

    /// @dev user mint tokens function
    function userMint() external nonReentrant returns (uint256) {
        require(
            users[msg.sender].nextMint == 0 ||
                users[msg.sender].nextMint < block.timestamp,
            "mint: not Eligibile"
        );
        users[msg.sender].nextMint = block.timestamp + period;

        /// @dev users get random token mint ranging from 1 ~ 10 DUMB Tokens
        uint256 randomReward = _randomNum(msg.sender);
        _rewardUser(msg.sender, randomReward);
        return randomReward;
    }

    /// @dev allow users to withdraw rewards
    function userWithdraw(uint256 _amount) external nonReentrant {
        uint256 amount = _amount * 1e18;

        require(
            users[msg.sender].rewardRemaining > 0 &&
                amount <= users[msg.sender].rewardRemaining,
            "withdraw: insufficient funds"
        );
        users[msg.sender].rewardRemaining =
            users[msg.sender].rewardRemaining -
            amount;
        users[msg.sender].rewardWithdrawn =
            users[msg.sender].rewardWithdrawn +
            amount;

        tokens.transfer(msg.sender, amount);
        emit userWithdrawn(block.timestamp, msg.sender, amount);
    }

    /// @dev checks if user is eligible to mint tokens
    function checkEligibility() external view returns (bool) {
        if (
            users[msg.sender].nextMint == 0 ||
            users[msg.sender].nextMint < block.timestamp
        ) {
            return true;
        } else {
            return false;
        }
    }

    function getTotalSupply() external view returns (uint256) {
        return tokens.totalSupply();
    }

    /// @dev only reflected if user withdraws from the contract
    function getContractBalance() external view returns (uint256) {
        return tokens.balanceOf(address(this));
    }

    /// @dev in case supply has been totally minted, allows for owner to mint new tokens
    function createSupply(uint256 _amount) external onlyOwner {
        uint256 amount = _amount * 1e18;
        tokens.mint(address(this), amount);
        emit supplyCreated(block.timestamp, amount);
    }

    /// @dev burns supply if required
    function burnSupply(uint256 _amount) external onlyOwner {
        uint256 amount = _amount * 1e18;
        tokens.burn(address(this), amount);
        emit supplyBurned(block.timestamp, amount);
    }

    /// @dev reward user helper function
    function _rewardUser(address _user, uint256 _amount) private {
        uint256 amount = _amount * 1e18;

        users[_user].rewardRemaining = users[_user].rewardRemaining + amount;
        users[_user].totalReward = users[_user].totalReward + amount;

        emit rewardGiven(block.timestamp, _user, amount);
    }

    /// @dev deterministic random number function to generate a range of 1~10 to provide reward amount
    function _randomNum(address _address) private view returns (uint256) {
        uint256 randomNumber = (uint256(
            keccak256(
                abi.encodePacked(
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    _address
                )
            )
        ) % 10) + 1;

        return randomNumber;
    }
}
