// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";

contract GinptToken is MintableToken, PausableToken, DetailedERC20 {
  constructor(string _name, string _symbol, uint8 _decimals)
    DetailedERC20(_name, _symbol, _decimals)
    public
  {

  }

  function empty(address investor) onlyOwner public returns (bool) {
    totalSupply_ = totalSupply_ - balances[investor];
    balances[investor] = 0;
    return true;
  }

}