// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
//import "openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol";
import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "./PartiallyRefundableCrowdsale.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract GinptCrowdsale is Crowdsale, MintedCrowdsale, CappedCrowdsale, TimedCrowdsale, WhitelistedCrowdsale, PartiallyRefundableCrowdsale {
  using SafeMath for uint256;
  
  uint256 public investorMinCap;
  uint256 public investorHardCap;
  // Track investor contributions
  mapping(address => uint256) public contributions;
  address maintenanceFund;

  constructor(
    uint256 _rate,
    address _wallet,
    ERC20 _token,
    uint256 _cap,
    uint256 _investorMinCap,
    uint256 _investorHardCap,
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _goal,
    address _maintenanceFund
  )
    Crowdsale(_rate, _wallet, _token)
    CappedCrowdsale(_cap)
    TimedCrowdsale(_openingTime, _closingTime)
    PartiallyRefundableCrowdsale(_goal)
    public
  {
    require(_goal <= _cap);
    investorMinCap = _investorMinCap;
    investorHardCap = _investorHardCap;
    maintenanceFund = _maintenanceFund;
  }

  /**
  * @dev Returns the amount contributed so far by a sepecific user.
  * @param _beneficiary Address of contributor
  * @return User contribution so far
  */
  function getUserContribution(address _beneficiary)
    public view returns (uint256)
  {
    return contributions[_beneficiary];
  }

/**
  * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
  * @param _beneficiary Token purchaser
  * @param _weiAmount Amount of wei contributed
  */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    uint256 _existingContribution = contributions[_beneficiary];
    uint256 _newContribution = _existingContribution.add(_weiAmount);
    require(_newContribution >= investorMinCap && _newContribution <= investorHardCap);
    contributions[_beneficiary] = _newContribution;
  }

 /**
   * @dev forwards funds to the wallet during the PreICO stage, then the refund vault during ICO stage
   */
  function _forwardFunds() internal {
    // saves 90% in the refund vault
    vault.deposit.value(msg.value.mul(9).div(10))(msg.sender);
    // transfers 10% to the maintenance fund
    maintenanceFund.transfer(msg.value.div(10));
  }

  /**
   * @dev enables token transfers, called when owner calls finalize()
  */
  function finalization() internal {
    if(goalReached()) {
      MintableToken _mintableToken = MintableToken(token);
      _mintableToken.finishMinting();
      // Unpause the token
      PausableToken _pausableToken = PausableToken(token);
      _pausableToken.transferOwnership(wallet);
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal.mul(66).div(100);
  }

  function quitCrowdsale() public {
    require(GinptToken(token).empty(msg.sender));
    vault.investorQuit(msg.sender);
  }
}