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

contract FarmContract is Ownable {
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
        harvest();

        if (paperWethLP.balanceOf(address(this)) > 0) {
            // (paperBalance + debt) * (totalLP + amount) / totalLP - paperBalance
            debt = paper.balanceOf(address(this)).add(debt).mul(paperWethLP.balanceOf(address(this)).add(_amount)).div(paperWethLP.balanceOf(address(this))).sub(paper.balanceOf(address(this)));
        } else {
            debt = 0;
        }

        paperWethLP.safeTransferFrom(address(msg.sender), address(this), _amount);
        users[msg.sender].amount = users[msg.sender].amount.add(_amount);

        if (paperWethLP.balanceOf(address(this)) > 0) {
            // (paperBalance + debt) * user.amount / totalLP
            users[msg.sender].loss = paper.balanceOf(address(this)).add(debt).mul(users[msg.sender].amount).div(paperWethLP.balanceOf(address(this)));
        } else {
            users[msg.sender].loss = 0;
        }
    }


    function withdraw(uint256 _amount) public {
        require(paper.totalSupply() == paper.maxSupply(), "Withdrawals will be available after PAPER max supply is reached");
        require(users[msg.sender].amount >= _amount, "You don't have enough LP tokens");
        require(paperWethLP.balanceOf(address(this))  > 0, "No tokens left");

        harvest();
        // (paperBlance + debt) * (totalLP - amount) / totalLP - paperBalance
        debt = paper.balanceOf(address(this)).add(debt).mul(paperWethLP.balanceOf(address(this)).sub(_amount)).div(paperWethLP.balanceOf(address(this)));

        if (debt > paper.balanceOf(address(this))) {
            debt = debt.sub(paper.balanceOf(address(this)));
        } else {
            debt = 0;
        }

        paperWethLP.safeTransfer(address(msg.sender), _amount);

        if (users[msg.sender].amount > _amount) {
            users[msg.sender].amount = users[msg.sender].amount.sub(_amount);
        } else {
            users[msg.sender].amount = 0;
        }

        if (paperWethLP.balanceOf(address(this)) > 0) {
            // (paperBalance + debt) * user.amount / totalLP
            users[msg.sender].loss = paper.balanceOf(address(this)).add(debt).mul(users[msg.sender].amount).div(paperWethLP.balanceOf(address(this)));
        } else {
            users[msg.sender].loss = 0;
        }
    }

    function harvest() public {
        if (!(users[msg.sender].amount > 0 && paperWethLP.balanceOf(address(this)) > 0)) {
            return;
        }
        // (paperBalance + debt) * user.balance / totalLPbalance
        uint256 p = paper.balanceOf(address(this)).add(debt).mul(users[msg.sender].amount).div(paperWethLP.balanceOf(address(this)));

        if (p > users[msg.sender].loss) {
            uint256 pending = p.sub(users[msg.sender].loss);
            paper.transfer(msg.sender, pending);
            debt = debt.add(pending);
            users[msg.sender].loss = p;
        }
    }


    function getPending(address _user) public view returns(uint256){
        if(users[_user].amount > 0 && paperWethLP.balanceOf(address(this)) > 0) {
            // (paperBalance + debt) * user.balance / totalLPbalance - user.loss
            return paper.balanceOf(address(this)).add(debt).mul(users[_user].amount).div(paperWethLP.balanceOf(address(this))).sub(users[_user].loss);
        }
        return 0;
    }


    function getTotalLP() public view returns(uint256) {
        return paperWethLP.balanceOf(address(this));
    }


    function getUser(address _user) public view returns(uint256 balance, uint256 loss) {
        balance = users[_user].amount;
        loss = users[_user].loss;
    }

}