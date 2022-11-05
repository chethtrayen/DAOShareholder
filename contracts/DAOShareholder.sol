// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

abstract contract DAOShareholder{
  uint8 constant BASE_TTL = 7;

  address private immutable i_coordinator;

  modifier coordinatorAccess(){
    if(msg.sender != i_coordinator) revert();
    _;
  }

  struct Shareholder{
    mapping(address => uint256) shares;
    address[] holders;
    mapping(address => uint256) keys;
  }

  Shareholder private s_shareholders;

  modifier fullAccess() {
    if(msg.sender != i_coordinator || s_shareholders.shares[msg.sender] == 0) revert();
    _;
  }

  modifier shareholderAccess(){
    if(s_shareholders.shares[msg.sender] == 0) revert();
    _;
  }

  modifier hasShares(uint256 _shares){
    if(s_shareholders.shares[msg.sender] < _shares) revert();
    _;
  }

  uint256 private s_freeShares;
  uint256 private immutable i_maxShares;

  modifier validShares (uint256 _requestedShares) {
    if(s_freeShares < _requestedShares || _requestedShares == 0) revert();
    _;
  }

  struct Request{
    address requester;
    uint256 shares;
    uint256 upkeepTime;
    uint256 lock;
  }

  mapping(address => uint256) private s_requesterNonce; // shareholder => nonce
  mapping(bytes32 => Request) private s_requests; // requestId => requester

  modifier pendingRequest(bytes32 _requestId){
    if(s_requests[_requestId].requester == address(0)) revert();
    _;
  }

  modifier requesterAccess(bytes32 _requestId){
    if(s_requests[_requestId].requester != msg.sender) revert();
    _;
  }

  modifier requestExpires(bytes32 _requestId){
    if(block.timestamp > s_requests[_requestId].lock) revert();
    _;
  }

  modifier validRequestShare(bytes32 _requestId){
    if(s_requests[_requestId].shares < s_freeShares) revert();
    _;
  }

  struct Vote{
    uint256 approvalAmount;
    mapping(address => uint256) approvers;
  }

  mapping(bytes32 => Vote) s_votes; 

  constructor(uint256 _shares, uint256 _deployerShares){
    if(_shares < _deployerShares) revert();

    i_coordinator = msg.sender;

    s_freeShares = _shares - _deployerShares;
    i_maxShares = _shares;

    s_shareholders.shares[msg.sender] = _deployerShares;
    s_shareholders.holders.push(msg.sender);
    s_shareholders.keys[msg.sender] = 1;
  }

  function removeShareholder(address _shareholder) internal {
    uint256 last = s_shareholders.holders.length - 1;
    address lastHolder = s_shareholders.holders[last];
    uint256 removeHolderKey = s_shareholders.keys[_shareholder] - 1;

    s_shareholders.holders[removeHolderKey] = lastHolder;
    s_shareholders.keys[lastHolder] = removeHolderKey;
    
    s_shareholders.holders.pop();
    delete s_shareholders.keys[_shareholder];
  }

  function approveRequest(bytes32 _requestId) internal{
    address requester = s_requests[_requestId].requester;

    if(s_shareholders.shares[requester] == 0){
      s_shareholders.holders.push(requester);
      s_shareholders.keys[requester] = s_shareholders.holders.length;
    }

    s_shareholders.shares[requester] += s_requests[_requestId].shares;
  }

  function createRequest(uint256 _requestedShares) external validShares(_requestedShares){
    s_requesterNonce[msg.sender] += 1;

    bytes32 requestId = keccak256(abi.encode(msg.sender, s_requesterNonce[msg.sender] , _requestedShares));
    uint256 lockTimer =  block.timestamp + BASE_TTL;
    uint256 upkeepTimer = lockTimer + 1000;
    s_requests[requestId] = Request(msg.sender, _requestedShares, upkeepTimer, lockTimer);
  }

  function editRequest(bytes32 _requestId, uint256 _shares) external validShares(_shares) requesterAccess(_requestId){
    s_requests[_requestId].shares = _shares;
  }

   function removeRequest(bytes32 _requestId) external requesterAccess(_requestId){
    delete s_requests[_requestId];
  }

  function approvingRequest(bytes32 _requestId) external shareholderAccess validRequestShare(_requestId){
    if(s_votes[_requestId].approvers[msg.sender] == s_shareholders.shares[msg.sender]) revert();

    uint256 votedShares = s_votes[_requestId].approvers[msg.sender];
    uint256 currentShares = s_shareholders.shares[msg.sender];

    s_votes[_requestId].approvalAmount  = s_votes[_requestId].approvalAmount - votedShares + currentShares;
    s_votes[_requestId].approvers[msg.sender] = currentShares; 
  }


  function checkUpkeep(bytes32 _requestId) internal view returns (bool, bool) {
    uint256 votedShares = s_votes[_requestId].approvers[msg.sender];
    uint256 currentShares = s_shareholders.shares[msg.sender];


    uint256 approvalLimit = (i_maxShares - s_freeShares)/2;
    uint256 newApprovalAmount = s_votes[_requestId].approvalAmount - votedShares + currentShares;

    bool approved = newApprovalAmount >= approvalLimit;
    bool upkeep = block.timestamp > s_requests[_requestId].upkeepTime;

    return (approved, upkeep);
  }

  function performAction(bytes32 _requestId) external {

    (bool approved, bool upkeep) = checkUpkeep(_requestId);

    if(upkeep){
      if(approved){
        approveRequest(_requestId);
      }

      delete s_requests[_requestId];
    }else{
      revert();
    }
  
  }

  function releaseShares() public shareholderAccess {
    s_freeShares += s_shareholders.shares[msg.sender];
    s_shareholders.shares[msg.sender] = 0;

    removeShareholder(msg.sender);
  }

  function transferShares(address _receiver, uint256 _shares) public shareholderAccess hasShares(_shares){
    if(s_shareholders.shares[_receiver] == 0){
      revert();
    }

    s_shareholders.shares[msg.sender] -= _shares;
    s_shareholders.shares[_receiver] += _shares;

    if(s_shareholders.shares[msg.sender] == 0){
      removeShareholder(msg.sender);
    }
  }

}