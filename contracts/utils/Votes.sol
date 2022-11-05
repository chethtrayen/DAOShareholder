// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import './Shareholders.sol';

library Votes {

  struct Vote{
    uint256 approval;

    mapping(address => uint256) approvers;
  }

  function update(Vote storage vote, address holder, uint256 currentShares) internal {
    if(vote.approvers[holder] == currentShares) revert();

    uint256 updatedApproval = vote.approval - vote.approvers[holder] + currentShares;

    vote.approval = updatedApproval;

    vote.approvers[holder] = currentShares;
  }

  function checkApproval(Vote storage vote, uint256 approvalLimit) internal view returns (bool){
    return approvalLimit < vote.approval;
  }
}