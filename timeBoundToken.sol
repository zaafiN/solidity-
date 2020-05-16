
pragma solidity ^0.6.0;

import "./BCCToken.sol";

contract TokenTimelock {

  PIAICBCCToken public token;
  address public beneficiary;
  uint256 public releaseTime;

  constructor(
    PIAICBCCToken _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  function release() public {
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.transfer(beneficiary, amount);
  }
}
