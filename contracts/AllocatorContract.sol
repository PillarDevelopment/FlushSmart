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

    mapping (address => uint256) private userPart; // Paper/Weth
    mapping (address => uint256) private pendingAmount; // Paper
    mapping (address => uint256) private withdrawAmount; // Paper

    address [] private farmers;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);

    constructor(PaperToken _paper, IERC20 _paperLpToken) public {
        paper = _paper;
        paperWethLP = _paperLpToken;
    }


    function deposit(uint256 _amount) public {
        paperWethLP.safeTransferFrom(address(msg.sender), address(this), _amount);

        if(userPart[msg.sender] == 0) {
            farmers.push(msg.sender);
        }
        userPart[msg.sender] = userPart[msg.sender].add(_amount);
        updatePool();
        emit Deposit(msg.sender, _amount);
    }


    function updatePool() public {
        for(uint i = 0; i<farmers.length; i++) {
            pendingAmount[farmers[i]] = (userPart[farmers[i]].div(paperWethLP.balanceOf(address(this)))).mul(paper.balanceOf(address(this))); // сколько ожидается пейперов для каждого
        }
    }


    function harvest() public {
        uint256 paperReward = pendingAmount[msg.sender].sub(withdrawAmount[msg.sender]);
        paper.transfer(msg.sender, paperReward);
        withdrawAmount[msg.sender] = withdrawAmount[msg.sender].add(paperReward);
        emit Harvest(msg.sender, paperReward);
    }


    function safePaperTransfer(address _to, uint256 _amount) internal {
        uint256 paperBal = paper.balanceOf(address(this));
        if (_amount > paperBal) {
            paper.transfer(_to, paperBal);
        } else {
            paper.transfer(_to, _amount);
        }
    }


    function getWithdrawAmount(address _user) public view returns(uint256) {
        return withdrawAmount[_user];
    }

    function getPendingAmount(address _user) public view returns(uint256) {
        return pendingAmount[_user];
    }

    function getUserPartAmount(address _user) public view returns(uint256) {
        return userPart[_user];
    }


    function getPaperBalance() public view returns(uint256) {
        return paper.balanceOf(address(this));
    }


    function getPaperEthBalance() public view returns(uint256) {
        return paperWethLP.balanceOf(address(this));
    }


    function getFarmersCount() public view returns(uint256) {
        return farmers.length;
    }


    function getFarmerAddress(uint256 _farmerId) public view returns(address) {
        return farmers[_farmerId];
    }

}