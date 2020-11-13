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
        addNewRate(msg.sender, betAmount);

        if(roundBalance >= roundLimit) {
            givePrize();
        }
    }

    
    function addNewRate(address _player, uint256 _rateEth) internal {

        lastRates[_player].rate = _rateEth;
        lastRates[_player].round = getCountOfRewards();
        betsHistory[msg.sender] = bets.length;
        bets.push(Bet({ player: _player,
                        bet: _rateEth}));
        emit NewRate(msg.sender, _rateEth);
    }


    function givePrize() public {
        uint256 prizeNumber = _randRange(0, roundLimit);
        address payable winner = payable(generateWinner(prizeNumber));

        uint256 userReward = allocatePaper();

        IWETH(WETH).withdraw(userReward);
        winner.transfer(userReward);

        finishedRounds.push(Round({winner: winner, prize: userReward}));
        clearRound();
        emit EndRound(winner, userReward);
        emit NewRound(roundLimit, roundLimit);
    }


    function generateWinner(uint256 prizeNumber) public returns(address winner) {
        uint256 a = 0;
        for(uint256 i=0; i<bets.length; i++) {
            if (prizeNumber > a && prizeNumber <= a.add(bets[i].bet)) {
                winner = bets[i].player;
                break;
            }
            a = a.add(bets[i].bet);
        }
    }


    function clearRound() public {
        for(uint256 i = 0; i < bets.length; i++) {
            betsHistory[bets[i].player] = 0;
        }
        delete bets;
        roundBalance = 0;
    }


    function allocatePaper() public returns(uint256) {
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
        return userReward;
    }


    function getRateUserInfo(uint256 _userid) public view returns(address player, uint256 rate) {
        player = bets[_userid].player;
        rate = bets[_userid].bet;
    }


    function getBetsLength() public view returns(uint256) {
        return bets.length;
    }

}