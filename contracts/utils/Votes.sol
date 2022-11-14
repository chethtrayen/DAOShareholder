// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

library Votes {

  struct Voter {
    uint256 shares;
    bool approved;
  }

  struct Vote{
    uint256 approval;
    uint256 rejection;

    mapping(address => uint256) rejectors;
    mapping(address => uint256) approvers;

    mapping(address => Voter) voters;
  }

  function add(Vote storage votes, address holder, uint256 shares, bool approved) internal {  
    if(votes.voters[holder].shares > 0) revert();

    votes.voters[holder].shares = shares;
    votes.voters[holder].approved = approved;

    if(approved){
      votes.approval += shares;
    }
    else{
      votes.rejection += shares;
    }
  }

  function updateShares(Vote storage votes, address holder, uint256 shares) internal {  
    if(votes.voters[holder].shares == 0) return;

    if(votes.voters[holder].approved){
      votes.approval -= votes.voters[holder].shares + shares;
    }
    else{
      votes.rejection -=  votes.voters[holder].shares + shares;
    }

    if(shares == 0){
      delete votes.voters[holder];
    }
  }

  function updateVote(Vote storage votes, address holder, bool approved) internal {
    if(votes.voters[holder].approved == approved) revert();

    uint256 shares = votes.voters[holder].shares;
    
    if(approved){
      votes.approval += shares;
      votes.rejection -= shares;
    }
    else{
      votes.approval -= shares;
      votes.rejection += shares;
    }

    votes.voters[holder].approved = approved;
  }

  function checkVotes(uint256 shareAmount, uint256 sharesNeeded) internal pure returns (bool){
    return sharesNeeded <= shareAmount;
  }
}