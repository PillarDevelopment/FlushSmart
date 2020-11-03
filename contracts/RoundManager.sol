// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./TokensManager.sol";
contract RoundManager is TokensManager {

    uint256 internal roundLimit = 3e18;

    uint256 internal roundBalance;
    uint256 internal accumulatedBalance;
    uint256 internal countOfRewards;

    struct Round {
        address winner;
        uint256 prize;
    }
    
    Round[] internal finishedRounds;

    event NewRound(uint256 limit, uint256 reward);
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
        return (_roundBalance.div(100)).mul(_part);
    }

    function getCountOfRewards() public view returns(uint256) {
        return countOfRewards;
    }

    function getWinner(uint256 _id) public view returns(address _winner, uint256 _prize) {
        _winner = finishedRounds[_id].winner;
        _prize = finishedRounds[_id].prize;
    }

}
