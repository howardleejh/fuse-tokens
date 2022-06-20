// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

/// @title Trivia Contract to allow users to mint DUMB Tokens
/// @author Howard Lee
/// @notice contract is used to allow users to mint DUMB Tokens and record user reward info.

import "./DumbTokens.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TriviaContract is Ownable, ReentrancyGuard {
    /// @dev struct to store user rewards data

    struct userInfo {
        uint256 nextMint;
        uint256 totalReward;
        uint256 rewardRemaining;
        uint256 rewardWithdrawn;
    }

    DumbTokens public tokens;
    mapping(address => userInfo) public users;
    /// @dev this is the period of 1 day, users allowed to mint tokens once per day only.
    uint256 constant period = 86400;

    /// @dev init DUMB tokens and mint total supply of tokens to this contract
    constructor() {
        tokens = new DumbTokens(address(this));
    }

    /// @dev user mint tokens function
    function userMint(bool _answer) external nonReentrant returns (uint256) {
        require(
            users[msg.sender].nextMint == 0 ||
                users[msg.sender].nextMint < block.timestamp,
            "mint: not Eligibile"
        );
        users[msg.sender].nextMint = block.timestamp + period;

        if (_answer == true) {
            uint256 randomReward = _randomNum();
            _rewardUser(msg.sender, randomReward);
            return randomReward;
        }

        return 0;
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
    }

    /// @dev checks if user is eligible to mint tokens
    function checkEligibility() external view returns (bool) {
        if (
            users[msg.sender].nextMint == 0 ||
            users[msg.sender].nextMint < block.timestamp
        ) {
            return true;
        }
        return false;
    }

    /// @dev in case supply has been totally minted, allows for owner to mint new tokens
    function createSupply(uint256 _amount) external onlyOwner {
        uint256 amount = _amount * 1e18;
        tokens.mint(address(this), amount);
    }

    /// @dev burns supply if required
    function burnSupply(uint256 _amount) external onlyOwner {
        uint256 amount = _amount * 1e18;
        tokens.burn(address(this), amount);
    }

    /// @dev reward user helper function
    function _rewardUser(address _user, uint256 _amount) private {
        uint256 amount = _amount * 1e18;

        users[_user].rewardRemaining = users[_user].rewardRemaining + amount;
        users[_user].totalReward = users[_user].totalReward + amount;
    }

    /// @dev deterministic random number function to generate a range of 1~10 to provide reward amount
    function _randomNum() private view returns (uint256) {
        uint256 randomNumber = (uint256(
            keccak256(
                abi.encodePacked(
                    block.number,
                    block.timestamp,
                    block.difficulty
                )
            )
        ) % 10) + 1;

        return randomNumber;
    }
}
