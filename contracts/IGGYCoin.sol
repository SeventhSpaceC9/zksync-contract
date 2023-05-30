// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract IGGYCoin is ERC20, ERC20Burnable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    mapping(address => bool) public blacklists;
    address public taxAccount;
    uint256 public taxBasisPointsSell;
    uint256 public taxBasisPointsBuy;
    EnumerableSet.AddressSet private _taxFreeAccounts;
    EnumerableSet.AddressSet private _uniswapV2Pairs;

    constructor() ERC20("IGGYCoin", "IGGY") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )override internal virtual {
        uint256 tax=0;
        if (_uniswapV2Pairs.contains(sender)) {
            if(!_taxFreeAccounts.contains(recipient) && !isContract(recipient)){
                tax = (amount * taxBasisPointsBuy) / 10000;
            }
        } else if (_uniswapV2Pairs.contains(recipient)) {
            if(!_taxFreeAccounts.contains(sender) && !isContract(sender)){
                tax = (amount * taxBasisPointsSell) / 10000;
            }
        }

        if (tax > 0) {
            super._transfer(sender, taxAccount, tax);
        }

        if (_uniswapV2Pairs.contains(sender)) {
            super._transfer(sender, recipient, amount - tax);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function setRule(bool _limited, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function setTax(address _taxAccount, uint256 _taxBasisPointsBuy, uint256 _taxBasisPointsSell) external onlyOwner {
        require(_taxAccount != address(0), "zero address");
        require(_taxBasisPointsBuy >= 0 && _taxBasisPointsBuy <= 10000 && _taxBasisPointsSell >= 0 && _taxBasisPointsSell <= 10000, "out of range");
        taxAccount = _taxAccount;
        taxBasisPointsBuy = _taxBasisPointsBuy;
        taxBasisPointsSell = _taxBasisPointsSell;
    }

    function taxFreeAccounts() public view returns (address[] memory) {
        return _taxFreeAccounts.values();
    }

    function addTaxFreeAccount(address account) external onlyOwner {
        _taxFreeAccounts.add(account);
    }

    function removeTaxFreeAccount(address account) external onlyOwner {
        _taxFreeAccounts.remove(account);
    }

    function uniswapV2Pairs() public view returns (address[] memory) {
        return _uniswapV2Pairs.values();
    }

    function addUniswapV2Pair(address account) external onlyOwner {
        _uniswapV2Pairs.add(account);
    }

    function removeUniswapV2Pair(address account) external onlyOwner {
        _uniswapV2Pairs.remove(account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (_uniswapV2Pairs.length() == 0 || taxAccount == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && _uniswapV2Pairs.contains(from) && taxAccount != to) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
