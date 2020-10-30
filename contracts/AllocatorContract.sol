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

    mapping (address => uint256) public userPart;
    mapping (address => uint256) public withdrawAmount;
    address [] private farmers;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);

    constructor(PaperToken _paper, IERC20 _paperLpToken) public {
        paper = _paper;
        paperWethLP = _paperLpToken;
    }

    function deposit(uint256 _amount) public {
        paperWethLP.safeTransferFrom(address(msg.sender), address(this), _amount);
        updatePool();

        if (userPart[msg.sender] > 0) {
            uint256 pending = user.amount.mul(pool.accPaperPerShare).div(1e12).sub(user.rewardDebt);
            safePaperTransfer(msg.sender, pending);
        }

        if (userPart[msg.sender]==0) {
            farmers.push(msg.sender);
        }

        userPart[msg.sender] = userPart[msg.sender].add(_amount);
        emit Deposit(msg.sender, _amount);
    }


    function harvest(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accPaperPerShare).div(1e12).sub(user.rewardDebt);
        safePaperTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accPaperPerShare).div(1e12);
        // pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

     function pendingPaper( address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][_user];
        uint256 accPaperPerShare = pool.accPaperPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 paperReward = multiplier.mul(paperPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPaperPerShare = accPaperPerShare.add(paperReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accPaperPerShare).div(1e12).sub(user.rewardDebt);
    }

     function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
         uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
         uint256 paperReward = multiplier.mul(paperPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
         paper.mint(address(this), paperReward);
         pool.accPaperPerShare = pool.accPaperPerShare.add(paperReward.mul(1e12).div(lpSupply));
         pool.lastRewardBlock = block.number;
    }

     function safePaperTransfer(address _to, uint256 _amount) internal {
        uint256 paperBal = paper.balanceOf(address(this));
        if (_amount > paperBal) {
            paper.transfer(_to, paperBal);
        } else {
            paper.transfer(_to, _amount);
        }
    }

}