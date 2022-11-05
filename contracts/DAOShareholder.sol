// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

abstract contract DAOShareholder{
  
  address private immutable i_coordinator;

  modifier coordinatorAccess(){
    if(msg.sender != i_coordinator) revert();
    _;
  }

  struct Shareholder{
    mapping(address => uint256) shares;
    address[] holders;
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

  struct Vote{
    address[] approved;
    mapping(address => bool) voted;
  }

  mapping(bytes32 => Vote) s_votes; 

  modifier hasVoted(bytes32 _requestId) {
    if(s_votes[_requestId].voted[msg.sender]) revert();
    _;
  }

  constructor(uint256 _shares, uint256 _deployerShares){
    if(_shares < _deployerShares) revert();

    i_coordinator = msg.sender;

    s_freeShares = _shares - _deployerShares;
    i_maxShares = _shares;

    s_shareholders.shares[msg.sender] = _deployerShares;
    s_shareholders.holders.push(msg.sender);
  }

  function removeShareholder(address _shareholder) internal {
    uint256 lastIndex = s_shareholders.holders.length - 1;

    for(uint256 i = 0; i < s_shareholders.holders.length; i++){
      if(s_shareholders.holders[i] == _shareholder){
        address last = s_shareholders.holders[lastIndex];
        s_shareholders.holders[i] = last;

        s_shareholders.holders.pop();
        break;
      }
    }
  }

  function approveRequest(bytes32 _requestId) internal{
    address requester = s_requests[_requestId].requester;

    if(s_shareholders.shares[requester] == 0){
      s_shareholders.holders.push(msg.sender);
    }

    s_shareholders.shares[requester] += s_requests[_requestId].shares;
    delete s_requests[_requestId];
  }

  function requestShares(uint256 _requestedShares) external validShares(_requestedShares){
    s_requesterNonce[msg.sender] += 1;

    bytes32 requestId = keccak256(abi.encode(msg.sender, s_requesterNonce[msg.sender] , _requestedShares));
    s_requests[requestId] = Request(msg.sender, _requestedShares);
  }

  function editRequest(bytes32 _requestId, uint256 _shares) external validShares(_shares) requesterAccess(_requestId){
    s_requests[_requestId].shares = _shares;
  }

   function removeRequest(bytes32 _requestId) external requesterAccess(_requestId){
    delete s_requests[_requestId];
  }

  function approveVote(bytes32 _requestId) external shareholderAccess hasVoted(_requestId){
    s_votes[_requestId].voted[msg.sender] = true;
    s_votes[_requestId].approved.push(msg.sender);
  }

  function denyVote(bytes32 _requestId) external shareholderAccess hasVoted(_requestId){
    s_votes[_requestId].voted[msg.sender] = true;
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

  function determineRequestVote(bytes32 _requestId) internal coordinatorAccess pendingRequest(_requestId) validShares(s_requests[_requestId].shares){
    uint256 approval = 0;
    address[] memory approvedVotes = s_votes[_requestId].approved;

    for(uint256 i = 0; i < approvedVotes.length; i++){
      address voter = approvedVotes[i];
      approval += s_shareholders.shares[voter];
    }

    uint256 approvalLimit = i_maxShares/2;

    if(approval > approvalLimit){
      approveRequest(_requestId);
    }

    delete s_requests[_requestId];
    delete s_votes[_requestId];
  }

  function determineRequestVoteRaw(bytes32 _requestId) external coordinatorAccess{
    determineRequestVote(_requestId);
  }

  function calculateVotes(mapping(uint256 => address[]) storage _votes, uint256[] memory _ballots) internal view returns (uint256[] memory, uint256[] memory){
    uint256[] memory ballot;
    uint256[] memory values;

    for(uint256 i = 0; i < _ballots.length; i++){
      address[] memory voters = _votes[_ballots[i]];
      uint256 votedValue;

      for(uint256 j = 0; j < voters.length; j++){
        votedValue += s_shareholders.shares[voters[j]];
      }

      ballot[i] = _ballots[i];
      values[i] = votedValue;
    }

    return (ballot, values);
  }

}