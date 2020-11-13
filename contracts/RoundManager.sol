// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./TokensManager.sol";

contract RoundManager is TokensManager {

    uint256 internal roundLimit = 3e18;

    uint256 internal roundBalance;
    uint256 internal accumulatedBalance;

    struct Round {
        address winner;
        uint256 prize;
    }

    struct Bet {
        address player;
        uint256 bet;
    }

    struct LastRate {
        uint256 rate;
        uint256 round;
    }

    Round[] internal finishedRounds;
    mapping(address => LastRate) internal lastRates;
    mapping(uint256 => uint256) public pendingPrizes;

    event NewRound(uint256 limit, uint256 paperReward);
    event NewRate(address player, uint256 rate);
    event EndRound(address winner, uint256 prize);

    function setRoundLimit(uint256 _newAmount) public onlyOwner {
        roundLimit =  _newAmount;
    }


    function getRoundLimit() public view returns(uint256) {
        return roundLimit ;
    }


    function getRoundBalance() public view returns(uint256) {
        return roundBalance;
    }


    function getAccumulatedBalance() public view returns(uint256) {
        return accumulatedBalance;
    }


    function getAmountForRansom(uint256 _roundBalance, uint256 _part) public pure returns(uint256) {
        return (_roundBalance.mul(_part)).div(100);
    }


    function getWinner(uint256 _roundId) public view returns(address _winner, uint256 _prize) {
        _winner = finishedRounds[_roundId].winner;
        _prize = finishedRounds[_roundId].prize;
    }


    function getCountOfRewards() public view returns(uint256) {
        return finishedRounds.length;
    }


    function getLastBet(address _player) public view returns(uint256 amount, uint256 round) {
        amount = lastRates[_player].rate;
        round = lastRates[_player].round;
    }
}