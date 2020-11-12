// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./RoundManager.sol";
import "./Random.sol";

contract Lottery is RoundManager, Random {

    address public immutable WETH;

    Bet[] public bets;

    mapping(address => uint256) public betsHistory;


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

        uint256 betAmount = _swapWeTH;
        if (roundBalance.add(betAmount) > roundLimit) {
            betAmount = roundLimit.sub(roundBalance);
        }

        roundBalance = roundBalance.add(_swapWeTH);
        accumulatedBalance = accumulatedBalance.add(_swapWeTH);

        emit NewRate(msg.sender, _swapWeTH);

        betsHistory[msg.sender] = bets.length; // addNewRate(msg.sender, _swapWeTH);
        bets.push(Bet({ player: msg.sender,
        bet: betAmount}));

        if(roundBalance >= roundLimit) {
            givePrize();
        }
    }


    function givePrize() internal {
        uint256 prizeNumber = _randRange(0, roundLimit);

        uint256 a = 0;

        for(uint256 i = 0; i < bets.length; i++) {
            uint256 bet = bets[i].bet;

        }



        address payable winner;
        uint256 amountToBurn = getAmountForRansom(roundBalance, burnedPart);
        uint256 amountToAllocation = getAmountForRansom(roundBalance, allocationPart);

        uint256 maxReturn = getAmountTokens(WETH, address(paper), amountToBurn.add(amountToAllocation));

        if (maxReturn < amountToBurn.add(amountToAllocation)) {
            amountToBurn = amountToBurn.mul(maxReturn.div(amountToBurn.add(amountToAllocation)));              // todo посчитать пропорции в получившемся числе
            amountToAllocation = amountToAllocation.mul(maxReturn.div(amountToBurn.add(amountToAllocation)));
        }
        uint256 burnPaper = swap(amountToBurn, WETH, address(paper), getAmountTokens(WETH, address(paper), amountToBurn), 0x0000000000000000000000000000000000000005);
        uint256 allocatePaper = swap(amountToAllocation, WETH, address(paper), getAmountTokens(WETH, address(paper), amountToAllocation), allocatorContract);
        uint256 userReward = roundBalance.sub(amountToBurn.add(amountToAllocation));

        IWETH(WETH).withdraw(userReward);
        winner.transfer(userReward);

        finishedRounds.push(Round({winner: winner, prize: userReward}));
        clearRound();
        emit EndRound(winner, burnPaper.add(allocatePaper));
        emit NewRound(roundLimit, paperReward);
    }


    function clearRound() internal {
        for(uint256 i = 0; i < bets.length; i++) {
            betsHistory[bets[i].player] = 0;
        }
        delete bets;
        roundBalance = 0;
    }


    function getRateUserInfo(uint256 _id) public view returns(address player, uint256 rate) {
        player = bets[_id].player;
        rate = bets[_id].bet;
    }


    function getBetsLength() public view returns(uint256) {
        return bets.length;
    }

}