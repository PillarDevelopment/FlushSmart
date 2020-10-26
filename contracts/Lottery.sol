// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./RoundManager.sol";

contract Lottery is RoundManager {

    address public immutable WETH;

    constructor (address _router, address _developers, address _WETH, PaperToken _paper, address _allocatorContract) public {
        router = _router; // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        developers = _developers; // 0x2fd852c9a9aBb66788F96955E9928aEF3D71aE98
        WETH = _WETH; // 0xc778417e063141139fce010982780140aa0cd5ab  DAI 0xc7ad46e0b8a400bb3c915120d284aafba8fc4735
        paper = _paper; // 0x2cbef5b1356456a2830dfef6393daca2b3dfb7a5
        allocatorContract = _allocatorContract;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function makeBet(uint256 _tokenId, uint256 _tokenAmount) public {
        transferTokens(_tokenId, _tokenAmount);
        uint256 _swapWeTH = swap(_tokenAmount,
                                availableTokens[_tokenId],
                                WETH,
                                getAmountTokens(availableTokens[_tokenId], WETH, _tokenAmount),
                                address(this));
        mintToken(msg.sender);
        roundBalance = roundBalance.add(_swapWeTH);
        accumulatedBalance = accumulatedBalance.add(_swapWeTH);

        if(roundBalance >= roundLimit) {
            win(msg.sender);
        }
    }

    function win(address payable winner) private {

        uint256 amountToBurn = getAmountForRansom(roundBalance, burnedPart);
        uint256 amountToAllocation = getAmountForRansom(roundBalance, allocationPart);

        uint256 maxReturnToBurn = getAmountTokens(WETH, address(paper), amountToBurn);
        uint256 maxReturnToAllocation = getAmountTokens(WETH, address(paper), amountToAllocation);

        if (maxReturnToBurn.add(maxReturnToAllocation) < amountToBurn.add(amountToAllocation)) {

            amountToBurn = 1; // todo посчитать пропорции в получившемся числе
            amountToAllocation = 1;
        }
            uint256 swapEth = swap(amountToBurn, WETH, address(paper), maxReturnToBurn, 0x0000000000000000000000000000000000000005);
            uint256 swapEth = swap(amountToAllocation, WETH, address(paper), maxReturnToAllocation, allocatorContract);
            uint256 userReward = roundBalance.sub(amountToBurn.add(amountToAllocation));

        IWETH(WETH).withdraw(userReward);
        winner.transfer(userReward);
        roundBalance = 0;

        emit EndRound(winner, swapEth);
        emit NewRound(roundLimit, paperReward);
    }

}