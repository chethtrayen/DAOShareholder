// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "./utils/Votes.sol";
import "./utils/Requests.sol";
import "./utils/Shareholders.sol";

abstract contract DAOShareholder{
  using Votes for Votes.Vote;
  using Requests for Requests.Request;
  using Shareholders for Shareholders.Shareholder;

  uint16 constant BASE_TTL = 1000;

  address private immutable i_coordinator;

  Shareholders.Shareholder private s_shareholders;

  modifier shareholderAccess(){
    if(s_shareholders.shares[msg.sender] == 0) revert();
    _;
  }

  modifier hasShares(uint256 shares){
    if(s_shareholders.shares[msg.sender] < shares) revert();
    _;
  }

  uint256 private s_freeShares;
  uint256 private immutable i_maxShares;

  modifier validShares(uint256 requestedShares) {
    if(s_freeShares < requestedShares || requestedShares == 0) revert();
    _;
  }

  mapping(address => uint256) private s_requesterNonce; // shareholder => nonce
  mapping(bytes32 => Requests.Request) private s_requests; // requestId => request

  modifier requestAccess(bytes32 requestId){
    if(s_requests[requestId].requester != msg.sender) revert();
    _;
  }

  modifier validRequestShare(bytes32 requestId){
    if(s_requests[requestId].shares < s_freeShares) revert();
    _;
  }

  modifier requestExists(bytes32 requestId){
    if(s_requests[requestId].requester == address(0)) revert();
    _;
  }

  mapping(bytes32 => Votes.Vote) s_votes; 

  constructor(uint256 shares, uint256 deployerShares){
    if(shares < deployerShares) revert();

    i_coordinator = msg.sender;

    s_freeShares = shares - deployerShares;

    i_maxShares = shares;

    s_shareholders.addShares(msg.sender, deployerShares);
  }

  function approveRequest(bytes32 requestId) internal{
    

    address requester = s_requests[requestId].requester;

    uint256 shares = s_requests[requestId].shares;

    s_shareholders.addShares(requester, shares);
  }

  function createRequest(uint256 shares) external validShares(shares){
    s_requesterNonce[msg.sender] += 1;

    bytes32 requestId = keccak256(abi.encode(msg.sender, s_requesterNonce[msg.sender] , shares));

    uint256 lockTimer =  block.timestamp + BASE_TTL;

    uint256 upkeepTimer = lockTimer + 1000;

    s_requests[requestId] = Requests.Request(msg.sender, shares, upkeepTimer, lockTimer);
  }

  function editRequest(bytes32 requestId, uint256 shares) external validShares(shares) requestAccess(requestId) requestExists(requestId){
    s_requests[requestId].shares = shares;
  }

   function removeRequest(bytes32 requestId) external requestAccess(requestId)  requestExists(requestId){
    delete s_requests[requestId];
  }

  function updateVote(bytes32 requestId) external shareholderAccess validRequestShare(requestId){
    uint256 currentShares = s_shareholders.shares[msg.sender];

    s_votes[requestId].update(msg.sender, currentShares);
  }

  function removeVote(bytes32 requestId) external shareholderAccess validRequestShare(requestId){
    s_votes[requestId].update(msg.sender, 0);
  }
  
  function releaseShares() external shareholderAccess {
    s_shareholders.updateShares(msg.sender, 0);
  }

  function transferShares(address receiver, uint256 shares) external shareholderAccess hasShares(shares){
    if(s_shareholders.shares[receiver] == 0) revert();

    uint256 removedShares = s_shareholders.shares[msg.sender] - shares;

    s_shareholders.updateShares(msg.sender, removedShares);

    uint256 addedShares = s_shareholders.shares[receiver] + shares;

    s_shareholders.updateShares(msg.sender, addedShares);
  }

    function checkUpkeep(bytes32 requestId) internal view returns (bool, bool) {
    uint256 approvalNeeded = (i_maxShares - s_freeShares)/2;

    bool approved = s_votes[requestId].checkApproval(approvalNeeded);

    bool upkeep = s_requests[requestId].checkUpkeep();

    return (approved, upkeep);
  }

  function performAction(bytes32 requestId) external {
    (bool approved, bool upkeep) = checkUpkeep(requestId);

    if(!upkeep) revert();
    
    if(approved) approveRequest(requestId);
      
    delete s_requests[requestId];
  }
}