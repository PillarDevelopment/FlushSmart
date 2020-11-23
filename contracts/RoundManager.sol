// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./TokensManager.sol";

contract RoundManager is TokensManager {

    uint256 public roundLimit = 1e18;
    uint256 public roundBalance;
    uint256 public accumulatedBalance;

    struct Round {
        address winner;
        uint256 prize;
    }

    struct Bet {
        address player;
        uint256 bet;
    }

    struct UserBet {
        uint256 bet;
        uint256 round;
    }

    uint256 public finishedRounds = 0;
    mapping(address => UserBet) public bets;

    event NewRound(uint256 limit, uint256 paperReward);
    event NewBet(address player, uint256 rate);
    event EndRound(address winner, uint256 prize);

    function setRoundLimit(uint256 _newAmount) public onlyOwner {
        roundLimit =  _newAmount;
    }

    function getAmountForRedeem(uint256 _roundBalance, uint256 _part) public pure returns(uint256) {
        return (_roundBalance.mul(_part)).div(100);
    }
}