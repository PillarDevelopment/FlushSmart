// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "/PaperToken.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {

        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

}


contract AllocatorContract is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public paperWethLP;
    PaperToken public paper;

    struct Farmer {
        uint256 amount;
        uint256 loss;
    }

    mapping (address => Farmer) public users;

    uint256 public debt;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);


    constructor(PaperToken _paper, IERC20 _paperLpToken) public {
        paper = _paper;
        paperWethLP = _paperLpToken;
    }


    function deposit(uint256 _amount) public {
        users[msg.sender].amount = users[msg.sender].amount.add(_amount);
        uint256 p = users[msg.sender].amount / paperWethLP.balanceOf(address(this)) * (paper.balanceOf(address(this)) + debt);

        if (p > users[msg.sender].loss) {
            uint256 pending = pending = p - user[address].loss;
            paper.transfer(msg.sender, pending);
            debt = debt + pending;
            users[msg.sender].loss = p;
        }

        debt = (paper.balanceOf(address(this)) + debt)*(paperWethLP.balanceOf(address(this)))/paperWethLP.balanceOf(address(this)) - paper.balanceOf(address(this));
        paperWethLP.safeTransferFrom(address(msg.sender), address(this), _amount);
        users[msg.sender].loss = users[msg.sender].amount / paperWethLP.balanceOf(address(this)) * (paper.balanceOf(address(this)) + debt);
    }


    function withdraw(uint256 _amount) public {
        require(paper.totalSupply() == paper.maxSupply(), "Farming was stopped");

        uint256 p = users[msg.sender].amount / paperWethLP.balanceOf(address(this)) * (paper.balanceOf(address(this)) + debt);

        if (p > users[msg.sender].loss) {
            uint256 pending = pending = p - user[address].loss;
            paper.transfer(msg.sender, pending);
            debt = debt.add(pending);
            users[msg.sender].loss = p;
        }
        debt = (paper.balanceOf(address(this)) + debt)*(paperWethLP.balanceOf(address(this)) - _amount) / paperWethLP.balanceOf(address(this)) - paper.balanceOf(address(this));
        paperWethLP.safeTransferFrom(address(this), address(msg.sender), _amount);
        users[msg.sender].amount = users[msg.sender].amount - _amount;
        users[msg.sender].loss = users[msg.sender].amount / paperWethLP.balanceOf(address(this)) * (paper.balanceOf(address(this)) + debt);
    }


    function getPendingAmount(address _user) public view returns(uint256){
        return users[_user].amount / paperWethLP.balanceOf(address(this)) * (paper.balanceOf(address(this)) + debt) - user[_user].loss;
    }


    function getWithdrawAmount(address _user) public view returns(uint256) {
        return users[_user].loss;
    }


    function getUserAmount(address _user) public view returns(uint256) {
        return users[_user].amount;
    }


    function getTotalLP() public view returns(uint256) {
        return paperWethLP.balanceOf(address(this));
    }


    function getUser(address _user) public view returns(uint256 part, uint256 withdraw) {
        part = users[_user].amount;
        withdraw = users[_user].loss;
    }

}