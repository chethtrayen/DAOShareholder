// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

library Requests {
  struct Request{
    bytes32 requestId;
    address requester;
    uint256 shares;
    uint256 upkeepTime;
  }

  function checkUpkeep (Request storage request) internal view returns (bool){
    return block.timestamp > request.upkeepTime;
  }
}