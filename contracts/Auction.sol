// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./RoundManager.sol";
contract Auction is RoundManager {

    address payable internal  lastPlayer;
    uint256 internal lastBlock = 0;
    uint256 internal lastBet = 0;

    uint256 internal basicAuctionDuration = 69;

    address public immutable WETH;

    constructor (address _router, address _developers, address _WETH, PaperToken _paper) public {
        router = _router; // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        developers = _developers; // 0x2fd852c9a9aBb66788F96955E9928aEF3D71aE98
        WETH = _WETH; // 0xc778417e063141139fce010982780140aa0cd5ab  DAI 0xc7ad46e0b8a400bb3c915120d284aafba8fc4735
        paper = _paper; // 0x2cbef5b1356456a2830dfef6393daca2b3dfb7a5
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

    function betInAuction(uint256 _tokenId, uint256 _tokenAmount, address payable player) internal {
        if(lastBlock.add(basicAuctionDuration ) < block.timestamp && lastBlock != 0) {
            endAuction(lastPlayer);
        } else {
            lastBet = updateRoundData(_tokenId, _tokenAmount, player);

            lastPlayer = player;
            lastBlock = block.timestamp;
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
        return _swapWeTH;
    }

    function endAuction(address payable winner) internal {
        uint256 amountForRansom = roundBalance.div(10);
        uint256 maxReturn = getAmountTokens(WETH, address(paper), amountForRansom);

        if (maxReturn < amountForRansom) {
            amountForRansom = maxReturn;
        }
        uint256 swapEth = swap(amountForRansom, WETH, address(paper), maxReturn, 0x0000000000000000000000000000000000000005);
        uint256 userReward = roundBalance.sub(amountForRansom);

        IWETH(WETH).withdraw(userReward);
        winner.transfer(userReward);

        roundBalance = 0;

        lastBet = 0;
        lastPlayer = address(0x0);
        lastBlock = 0;

        emit EndRound(lastPlayer, swapEth);
        emit NewRound(roundLimit, paperReward);
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

}