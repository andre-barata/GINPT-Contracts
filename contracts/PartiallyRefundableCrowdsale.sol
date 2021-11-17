// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "openzeppelin-solidity/contracts/crowdsale/distribution/RefundableCrowdsale.sol";
import "./PartialRefundVault.sol";

contract PartiallyRefundableCrowdsale is RefundableCrowdsale {
  
  PartialRefundVault public vault;

  constructor(uint256 _goal) RefundableCrowdsale(_goal) public  {
    vault = new PartialRefundVault(wallet);
  }

  /**
   * @dev Investors can claim refunds here if crowdsale is unsuccessful
   */
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    require(GinptToken(token).empty(msg.sender));
    vault.refund(msg.sender);
  }

  function refundInvestor(address investor) onlyOwner public {
    require(isFinalized);
    require(!goalReached());

    require(GinptToken(token).empty(investor));
    vault.refund(investor);
  }

  /**
   * @dev Checks whether funding goal was reached.
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

  /**
   * @dev vault finalization task, called when owner calls finalize()
   */
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
   */
  function _forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

}
 