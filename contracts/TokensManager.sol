// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./PaperToken.sol";
import "../Interfaces/IUniswapV2Router02.sol";
import "../Interfaces/IWETH.sol";

contract TokenManager is Ownable{

    PaperToken public paper;
    address public immutable WETH;

    address private router;

    address[] public availableTokens;

    event AddNewToken(address token, uint256 tokenId);
    event UpdateToken(address previousToken,  address newToken, uint256 tokenId);

    function addTokens(address _token) public onlyOwner returns(uint256) {
        availableTokens.push(_token);
        emit AddNewToken(_token, availableTokens.length);
        IERC20(_token).approve(router, 1e66);
        return availableTokens.length;
    }

    function setToken(uint256 _tokenId, address _token) public onlyOwner {
        emit UpdateToken(availableTokens[_tokenId], _token, _tokenId);
        availableTokens[_tokenId] = _token;
        IERC20(_token).approve(router, 1e66);
    }

    function swap(uint256 _tokenAmount, address _a, address _b, uint256 amountMinArray, address _recipient) private returns(uint256){
        address[] memory _path = new address[](2);
        _path[0] = _a;
        _path[1] = _b;
        uint256[] memory amounts_ = IUniswapV2Router02(router).swapExactTokensForTokens(_tokenAmount,
                                                                                        amountMinArray,
                                                                                        _path,
                                                                                        _recipient,
                                                                                        now + 1200);
        return amounts_[amounts_.length - 1]; //
    }

    function mintToken(address _sender) private {
        paper.mintPaper(_sender, paperReward);
        paper.mintPaper(developers, paperReward.div(10));
    }

    function transferTokens(uint256 _tokenId, uint256 _tokenAmount) private {
        IERC20(availableTokens[_tokenId]).transferFrom(msg.sender, address(this), _tokenAmount);
    }

    function getAmountTokens(address _a, address _b, uint256 _tokenAmount) public view returns(uint256) {
        address[] memory _path = new address[](2);
        _path[0] = _a;
        _path[1] = _b;
        uint256[] memory amountMinArray = IUniswapV2Router02(router).getAmountsOut(_tokenAmount, _path);

        return amountMinArray[1];
    }

}
