// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "./utils/Votes.sol";
import "./utils/Requests.sol";
import "./utils/Shareholders.sol";

abstract contract DAOShareholder{
  using Votes for Votes.Vote;
  using Votes for uint256;
  using Requests for Requests.Request;
  using Shareholders for Shareholders.Shareholder;

  uint16 constant BASE_TTL = 1000;

  Shareholders.Shareholder private s_shareholders;

  modifier shareholderAccess(){
    if(s_shareholders.shares[msg.sender] == 0) revert();
    _;
  }

  uint256 private s_freeShares;
  
  uint256 private immutable i_maxShares;

  mapping(address => uint256) private s_requesterNonce; // shareholder => nonce

  Requests.Request private s_request;

  event RequestShares(bytes32 indexed requestId, uint256 indexed shares);

  event CompleteRequest(bytes32 indexed requestId, bool indexed approved);

  modifier requestExists(bytes32 requestId){
    if(s_request.requestId == requestId) revert();
    _;
  }

  Votes.Vote private s_votes;

  constructor(uint256 shares, uint256 deployerShares){
    if(shares < deployerShares) revert();

    s_freeShares = shares - deployerShares;

    i_maxShares = shares;

    s_shareholders.addShares(msg.sender, deployerShares);
  }

  function cleanupRequestAndVotes() internal {
    delete s_request;
    delete s_votes;
  }

  function approveRequest() internal{
    s_shareholders.addShares(s_request.requester, s_request.shares);
    cleanupRequestAndVotes();
  }

  function rejectRequest() internal{
    cleanupRequestAndVotes();
  }

  function createRequest(uint256 shares) external{
    if(s_request.checkUpkeep() == false) revert();

    if(s_freeShares < shares || shares == 0) revert();

    s_requesterNonce[msg.sender] += 1;

    if(s_shareholders.holders.length == 1 && s_shareholders.holders[0] == msg.sender){
      approveRequest();
      return;
    }

    bytes32 requestId = keccak256(abi.encode(msg.sender, s_requesterNonce[msg.sender] , shares));

    uint256 upkeepTimer =  block.timestamp + BASE_TTL;

    s_request = Requests.Request(requestId, msg.sender, shares, upkeepTimer);

    emit RequestShares(requestId, shares);
  }

   function removeRequest(bytes32 requestId) external requestExists(requestId){
    if(s_request.requester != msg.sender) revert();

    rejectRequest();
  }

  function addVote(bool approved, bytes32 requestId) external shareholderAccess requestExists(requestId){
    if(s_request.requester == msg.sender) revert();

    s_votes.add(msg.sender, s_shareholders.shares[msg.sender], approved);
    
    uint256 sharesNeeded = (i_maxShares - s_freeShares)/2;

    if(approved){
      if(s_votes.approval.checkVotes(sharesNeeded)) approveRequest();
    }else{
      if(s_votes.rejection.checkVotes(sharesNeeded)) rejectRequest();
    }
  }
  
  function releaseShares() external shareholderAccess {
    s_shareholders.updateShares(msg.sender, 0);

    s_votes.updateShares(msg.sender, 0);
  }

  function transferShares(address receiver, uint256 shares) external shareholderAccess{
    if(s_shareholders.shares[receiver] == 0 && s_shareholders.shares[msg.sender] < shares) revert();

    uint256 removedShares = s_shareholders.shares[msg.sender] - shares;

    uint256 addedShares = s_shareholders.shares[receiver] + shares;

    s_shareholders.updateShares(msg.sender, removedShares);

    s_shareholders.updateShares(receiver, addedShares);

    s_votes.updateShares(msg.sender, removedShares);

    s_votes.updateShares(receiver, addedShares);
  }

  function getShares() external view returns (uint256){
    return s_shareholders.getShares(msg.sender);
  }

}