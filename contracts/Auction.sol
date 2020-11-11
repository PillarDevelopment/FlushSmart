// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./RoundManager.sol";

contract Auction is RoundManager {

    struct Round {
        address winner;
        uint256 prize;
    }

    address payable internal  lastPlayer;
    uint256 internal lastBlock = 0;
    uint256 internal lastBet = 0;

    uint256 internal basicAuctionDuration = 69;

    address public immutable WETH;

    Round[] internal finishedRounds;

    event AuctionStep(uint256 lastBet, address lastPlayer, uint256 lastBlock);

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
        if (roundBalance.add(getAmountTokens(availableTokens[_tokenId], WETH, _tokenAmount)) < roundLimit) {
            updateRoundData(_tokenId, _tokenAmount, msg.sender);
        }
        else {
            betInAuction(_tokenId, _tokenAmount, msg.sender);
        }
    }



    function betInAuction(uint256 _tokenId, uint256 _tokenAmount, address payable player) public {
        if(lastBlock.add(basicAuctionDuration) < block.number && lastBlock != 0) {
            endAuction(lastPlayer);
        } else {
            require(lastBet < getAmountTokens(availableTokens[_tokenId], WETH, _tokenAmount), "Current bet cannot be less than previous bet");
            lastBet = updateRoundData(_tokenId, _tokenAmount, player);
            lastPlayer = player;
            lastBlock = block.number;
            emit AuctionStep(lastBet, lastPlayer, lastBlock);
        }
    }


    function updateRoundData(uint256 _tokenId, uint256 _tokenAmount, address player) internal returns(uint256) {
        transferTokens(_tokenId, _tokenAmount);
        uint256 _swapWeTH = swap(_tokenAmount,
                                availableTokens[_tokenId],
                                WETH,
                                getAmountTokens(availableTokens[_tokenId], WETH, _tokenAmount),
                                address(this));
        mintToken(player);
        roundBalance = roundBalance.add(_swapWeTH);
        accumulatedBalance = accumulatedBalance.add(_swapWeTH);

        emit NewRate(player, _swapWeTH);

        lastRate[_userAddress].rate = _swapWeTH;
        lastRate[_userAddress].round = getCountOfRewards();

        return _swapWeTH;
    }


    function endAuction(address payable winner) internal {
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
        emit EndRound(lastPlayer, burnPaper.add(allocatePaper));
        emit NewRound(roundLimit, paperReward);

        roundBalance = 0;
        lastBet = 0;
        lastPlayer = address(0x0);
        lastBlock = 0;
        finishedRounds.push(Round({winner: winner, prize: userReward}));
    }


    function setAuctionDuration(uint256 _newAmount) public onlyOwner {
        basicAuctionDuration = _newAmount;
    }


    function getAuctionLastBet() public view returns(uint256) {
        return lastBet;
    }


    function getAuctionLastBlock() public view returns(uint256) {
        return lastBlock;
    }


    function getAuctionLastPlayer() public view returns(address) {
        return lastPlayer;
    }


    function getBasicAuctionDuration() public view returns(uint256) {
        return basicAuctionDuration;
    }


    function getCountOfRewards() public view returns(uint256) {
        return finishedRounds.length;
    }


    function getWinner(uint256 _id) public view returns(address _winner, uint256 _prize) {
        _winner = finishedRounds[_id].winner;
        _prize = finishedRounds[_id].prize;
    }

}