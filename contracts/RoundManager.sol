// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./TokensManager.sol";
contract RoundManager is TokensManager {

    uint256 internal roundLimit = 3e18;

    uint256 internal roundBalance;
    uint256 internal accumulatedBalance;

    struct Rate {
        uint256 rate;
        uint256 round;
    }

    mapping (address => Rate) public lastRate;

    event NewRound(uint256 limit, uint256 reward);
    event NewRate(address _player, uint256 _rate);
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


    function getLastBet(address _userAddress) public view returns(uint256 amount, uint256 roundId) {
        amount = lastRate[_userAddress].rate;
        roundId = lastRate[_userAddress].round;
    }

}