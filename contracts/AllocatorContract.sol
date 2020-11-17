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
        uint256 lp;
        uint256 pending;
        uint256 lost;
    }

    mapping (address => Farmer) public users;

    uint256 public debt;
    uint256 public totalLP;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);


    constructor(PaperToken _paper, IERC20 _paperLpToken) public {
        paper = _paper;
        paperWethLP = _paperLpToken;
    }


    function deposit(uint256 _amount) public {
        paperWethLP.safeTransferFrom(address(msg.sender), address(this), _amount);

        totalLP = totalLP + _amount;
        users[msg.sender].lp = users[msg.sender].lp + _amount;

        uint256 p = (users[msg.sender].lp * (paper.balanceOf(address(this)) + debt)) / totalLP;

        if (p > users[msg.sender].lost) {
            users[msg.sender].pending = p - users[msg.sender].lost;

            paper.transfer(msg.sender, users[msg.sender].pending);

            debt = debt + users[msg.sender].pending;
            users[msg.sender].lost = p;
        }
        debt = (paper.balanceOf(address(this)) + debt)*(totalLP + _amount)/totalLP - paper.balanceOf(address(this));
        users[msg.sender].lost = users[msg.sender].lp / totalLP * (paper.balanceOf(address(this)) + debt);
    }


    function harvest(uint256 _amount) public {
        require(paper.totalSupply() == paper.maxSupply());  // todo WTF

        uint256 p = users[msg.sender].lp / totalLP * (paper.balanceOf(address(this)) + debt);

        if (p > users[msg.sender].lost) {
            users[msg.sender].pending = p - users[msg.sender].lost;
            paperWethLP.safeTransferFrom(address(this), address(msg.sender), users[msg.sender].pending);
            debt += users[msg.sender].pending;
            users[msg.sender].lost = p;
        }

        debt = (paper.balanceOf(address(this)) + debt)*(totalLP - _amount)/totalLP - paper.balanceOf(address(this));
        totalLP = totalLP - _amount;
        users[msg.sender].lost = users[msg.sender].lp / totalLP * (paper.balanceOf(address(this)) + debt);
    }


    function getWithdrawAmount(address _user) public view returns(uint256) {
        return  users[_user].lp / totalLP * (paper.balanceOf(address(this)) + debt);
    }


    function getPendingAmount(address _user) public view returns(uint256) {
        uint256 p = (users[_user].lp * (paper.balanceOf(address(this)) + debt)) / totalLP;

        if (p > users[_user].lost) {
            p =  p - users[_user].lost;
        }
        return p;
    }


    function getUserPartAmount(address _user) public view returns(uint256) {
        return users[_user].lp;
    }


    function getPaperEthBalance() public view returns(uint256) {
        return paperWethLP.balanceOf(address(this));
    }


    function getUser(address _user) public view returns(uint256 part, uint256 pemding, uint256 withdraw) {
        part = users[_user].lp;
        pemding = users[_user].pending;
        withdraw = users[_user].lost;
    }

}