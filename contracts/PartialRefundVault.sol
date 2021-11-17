// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "openzeppelin-solidity/contracts/crowdsale/distribution/utils/RefundVault.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./GinptToken.sol";

contract PartialRefundVault is RefundVault {
  using SafeMath for uint256;

  constructor(address _wallet) RefundVault(_wallet) public {
    
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) onlyOwner public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    // transfer 80% back to investor and 10% to the wallet
    uint256 originalPurchase = depositedValue.mul(10).div(9); // 90% was deposited, calculate 100%
    investor.transfer(originalPurchase.mul(8).div(10)); // 80% of original purchase is refunded
    wallet.transfer(originalPurchase.div(10)); // 10% of original purchase is forwarded to wallet
    emit Refunded(investor, depositedValue);
  }

  function investorQuit(address investor) onlyOwner public {
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    // transfer 80% back to investor and 10% to the wallet
    uint256 originalPurchase = depositedValue.mul(10).div(9); // 90% was deposited, calculate 100%
    investor.transfer(originalPurchase.mul(8).div(10)); // 80% of original purchase is refunded
    wallet.transfer(originalPurchase.div(10)); // 10% of original purchase is forwarded to wallet
    emit Refunded(investor, depositedValue);
  }
}
 