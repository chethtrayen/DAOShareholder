// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

library Requests {
  
  struct Request{
    address requester;
    uint256 shares;
    uint256 upkeepTime;
    uint256 lock;
  }


  function checkUpkeep (Request storage request) internal view returns (bool){
    return block.timestamp > request.upkeepTime;
  }

  function checkLock (Request storage request) internal view returns (bool){
    return block.timestamp > request.lock;
  }

}