// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title VestingSEVS
 * @dev This contract handles the vesting of SEVS tokens for given beneficiaries.
 * which will release the token to beneficiaries following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 * Don't send BNB and any tokens to this contract
 *
 * @custom:security-contact fuchengshun@gmail.com
 */
contract VestingSEVS is Context,Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    event Released(address indexed account, uint256 amount);
    event Locked(address indexed account, uint256 amount);

    EnumerableSet.AddressSet private _accounts;
    mapping(address => uint256[]) private _locked;
    mapping(address => uint256[]) private _released;
    IERC20 private immutable _token;
    mapping(address => uint64[])  _start;
    uint64 private  _duration;
    uint64 private  _cliff;

    /**
     * @dev Set the tokenAddress, start timestamp and vesting duration of the vesting wallet.
     */
    constructor(
        IERC20 tokenAddress,
//        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffSeconds
    ) {
//        require(block.timestamp < startTimestamp, "startTimestamp should be a time in the future");
        require(durationSeconds > cliffSeconds, "durationSeconds Should be greater than cliffSeconds");
        _token = tokenAddress;
//        _start = startTimestamp;
        _duration = durationSeconds;
        _cliff = cliffSeconds;
    }

    modifier onlyNotStart() {
        require(_accounts.length()==0, "vesting started");
        _;
    }

    /**
     * @dev Getter for the token.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @dev Setter for the start timestamp.
     */
//    function setStart(uint64 startTimestamp) public virtual onlyNotStart onlyOwner{
//        require(block.timestamp < startTimestamp, "startTimestamp should be a time in the future");
//        _start = startTimestamp;
//    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start(address account) public view virtual returns (uint64[] memory) {
        return _start[account];
    }

    /**
     * @dev Setter for the cliff.
     */
    function setCliff(uint64 cliffSeconds) public virtual onlyNotStart onlyOwner{
        require(cliffSeconds < _duration, "duration Should be greater than cliff");
        _cliff = cliffSeconds;
    }

    /**
     * @dev Getter for the cliff.
     */
    function cliff() public view virtual returns (uint256) {
        return _cliff;
    }

    /**
     * @dev Setter for the vesting duration.
     */
    function setDuration(uint64 durationSeconds) public virtual onlyNotStart onlyOwner{
        require(_cliff < durationSeconds, "duration Should be greater than cliff");
        _duration = durationSeconds;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of token already released
     */
    function released(address account) public view virtual returns (uint256) {
        uint256 ans=0;
        for(uint i=0;i<_released[account].length;i++){
            ans+=_released[account][i];
        }
        return ans;
    }

    /**
     * @dev Amount of token locked
     */
    function locked(address account) public view virtual returns (uint256) {
        uint256 ans=0;
        for(uint i=0;i<_locked[account].length;i++){
            ans+=_locked[account][i];
        }
        return ans;
    }

    /**
     * @dev Amount of token already released
     */
    function accounts() public view virtual returns (address[] memory) {
        return _accounts.values();
    }

    /**
     * @dev Lock a certain amount of token to an amount
     * Need to increase allowance of the contract first
     */
    function newLock(address account,uint256 amount,uint64 startTimestamp) public virtual{
        require(account != address(0), "account cannot be the zero address");
        require(block.timestamp < startTimestamp, "startTimestamp should be a time in the future");
        require(_start[account].length < 500, "up to 500");
        require(token().allowance(_msgSender(), address(this)) >= amount, "not enough balance");
        SafeERC20.safeTransferFrom(token(), _msgSender(), address(this), amount);
        _accounts.add(account);
        _start[account].push(startTimestamp);
        _locked[account].push(amount);
        _released[account].push(0);
        emit Locked(account, amount);
    }

    /**
     * @dev Release the token that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release(address account) public virtual {
        uint256 releasable =  0;
        uint256[] memory releasableArray=new uint256[](_start[account].length);
        for (uint256 i = 0; i < _start[account].length; ++i) {
            releasableArray[i]=vestedAmount(account, uint64(block.timestamp),i) - _released[account][i];
            releasable+=releasableArray[i];
        }
        require(releasable>0,"releasable should be greater than 0");
        for (uint256 i = 0; i < _start[account].length; ++i) {
            _released[account][i]+=releasableArray[i];
        }
        SafeERC20.safeTransfer(token(), account, releasable);
        emit Released(account, releasable);
    }

    /**
     * @dev Batch release the token that have already vested.
     */
    function batchRelease(address[] memory accountsArray) public virtual {
        for (uint256 i = 0; i < accountsArray.length; ++i) {
            release(accountsArray[i]);
        }
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address account, uint64 timestamp,uint  i) public view virtual returns (uint256) {
        return _vestingSchedule(_locked[account][i],_start[account][i], timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 start_,uint64 timestamp) internal view virtual returns (uint256) {
        if (timestamp < start_ + cliff()) {
            return 0;
        } else if (timestamp > start_ + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start_)) / duration();
        }
    }
}




