// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

library Votes {

  struct Vote{
    uint256 approval;

    mapping(address => uint256) approvers;
  }

  function update(Vote storage vote, address holder, uint256 shares) internal {
    if(vote.approvers[holder] == shares) revert();

    uint256 updatedApproval = vote.approval - vote.approvers[holder] + shares;

    vote.approval = updatedApproval;

    vote.approvers[holder] = shares;
  }

  function checkApproval(Vote storage vote, uint256 approvalNeeded) internal view returns (bool){
    return approvalNeeded <= vote.approval;
  }
}