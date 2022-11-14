// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

library Shareholders {
  struct Shareholder{
    mapping(address => uint256) shares;
    address[] holders;
    mapping(address => uint256) keys;
  }

  function addShares(Shareholder storage shareholder, address holder, uint256 shares) internal{
    if(shareholder.shares[holder] == 0){
      shareholder.holders.push(holder);

      shareholder.keys[holder] = shareholder.holders.length;
    }

    shareholder.shares[holder] += shares;
  }

  function remove(Shareholder storage shareholder, address holder) internal {
    uint256 last = shareholder.holders.length - 1;

    address lastHolder = shareholder.holders[last];

    uint256 removeHolderKey = shareholder.keys[holder] - 1;

    shareholder.holders[removeHolderKey] = lastHolder;

    shareholder.keys[lastHolder] = removeHolderKey;
    
    shareholder.holders.pop();
    
    delete shareholder.keys[holder];
  }

  function updateShares(Shareholder storage shareholder, address holder, uint256 shares) internal{
    if(shares == 0){
      remove(shareholder, holder);
    }else{
      shareholder.shares[holder] = shares;
    }
  }

  function getShares(Shareholder storage shareholder, address holder) internal view returns (uint256){
    return shareholder.shares[holder];
  }
}