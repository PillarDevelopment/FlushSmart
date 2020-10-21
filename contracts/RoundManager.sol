// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./TokensManager.sol";
contract RoundManager is TokensManager{

    address public developers;

    uint256 private roundLimit = 3e18;
    uint256 private paperReward = 1e18;
    uint256 private roundBalance;
    uint256 public accumulatedBalance;

    event NewRound(uint256 limit, uint256 reward);
    event EndRound(address winner, uint256 prize);

    function setRoundLimit(uint256 _newAmount) public onlyOwner {
        roundLimit =  _newAmount;
    }

    function setPaperReward(uint256 _newAmount) public onlyOwner {
        paperReward = _newAmount;
    }

    function getRoundLimit() public view returns(uint256) {
        return roundLimit ;
    }

    function getPaperReward() public view returns(uint256) {
        return paperReward;
    }

    function getRoundBalance() public view returns(uint256) {
        return roundBalance;
    }

}
