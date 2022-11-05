// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "../DAOShareholder.sol";
contract DAOTester is DAOShareholder{

  constructor(uint256 shares, uint256 deployerShares) DAOShareholder(shares, deployerShares){}
}