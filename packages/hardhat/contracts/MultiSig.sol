pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
// import "@openzeppelin/contracts/access/Ownable.sol"; 
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract MultiSig { 
  //events 
  event Deposit(address indexed sender, uint amount);
  event Submit(uint indexed txId);
  event Approve(address indexed owner, uint indexed txId);
  event Revoke(address indexed owner, uint indexed txId);
  event Execute(uint indexed txId);
  event OwnerAdded(address indexed owner, bool added);
  event OwnerRemoved(address indexed owner, bool removed);

  //struct
  struct Transaction {
    address to;
    uint value;
    bytes data;
    bool executed;
  }

  address[] public owners; // Mapping for owners who can execute transactions and sign them
  mapping(address => bool) public isOwnwer;
  uint public sigRequired;

  Transaction[] public transactions;
  mapping(uint => mapping(address => bool)) public isConfirmed; // Mapping for checking if a transaction is confirmed by an owner

  //modifiers
  modifier onlyOwner() {
    require(isOwnwer[msg.sender], "Not an owner");
    _;
  }

  modifier txExists(uint _txId) {
    require(_txId < transactions.length, "Transaction does not exist");
    _;
  }

  modifier notApproved(uint _txId) {
    require(!isConfirmed[_txId][msg.sender], "Transaction already approved");
    _;
  }

  modifier notExecuted(uint _txId) {
    require(!transactions[_txId].executed, "Transaction already executed");
    _;
  }

  modifier onlySelf() {
    require(msg.sender == address(this), "Only self");
    _;
  }

  constructor(address[] memory _owners, uint _required) payable {
    require(_required > 0 && _required <= _owners.length, "Number of owners and required signatures must be valid");
    require(_owners.length > 0 , "At least one owner is required");

    for (uint i = 0; i < _owners.length; i++) {
      address owner = _owners[i];
      require(owner != address(0), "Owner cannot be null");
      require(!isOwnwer[owner], "Owner cannot be duplicated");

      isOwnwer[owner] = true;
      owners.push(owner);
    }

    sigRequired = _required;
  }

  function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
    uint txId = transactions.length;
    transactions.push(Transaction({
      to: _to,
      value: _value,
      data: _data,
      executed: false
    }));

    emit Submit(txId);
  }

  function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
    isConfirmed[_txId][msg.sender] = true;
    emit Approve(msg.sender, _txId);
  }

  function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
    isConfirmed[_txId][msg.sender] = false;
    emit Revoke(msg.sender, _txId);
  }

  function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
    Transaction storage transaction = transactions[_txId];
    uint count = 0;
    for (uint i = 0; i < owners.length; i++) {
      if (isConfirmed[_txId][owners[i]]) {
        count += 1;
      }
    }

    require(count >= sigRequired, "Not enough signatures");

    (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
    require(success, "Transaction failed");
    transaction.executed = true;

    emit Execute(_txId);
  }

  function _addSigner(address _newOwner, uint _sigRequired) public onlySelf {
    owners.push(_newOwner);
    isOwnwer[_newOwner] = true;
    sigRequired = _sigRequired;
  }

  function encodeCallAddSigner(address _newOwner, uint _sigRequired) external view returns (bytes memory) {
    require(_sigRequired > 0 && _sigRequired <= owners.length+1, "Number of owners and required signatures must be valid");
    require(_newOwner != address(0), "Owner cannot be null");
    require(!isOwnwer[_newOwner], "Owner cannot be duplicated");
    // Typo and type errors will not compile
    return abi.encodeCall(this._addSigner, (_newOwner, _sigRequired));
  }

  // function removeSigner()

  function _removeSigner(address _removeOwner, uint _sigRequired) public onlySelf {
    for (uint i = 0; i < owners.length; i++) {
      if (owners[i] == _removeOwner) {
        owners[i] = owners[owners.length - 1]; // replace with last element
        owners.pop(); // remove last element
      }
    }
    isOwnwer[_removeOwner] = false;
    sigRequired = _sigRequired;
  }

  function encodeCallRemoveSigner(address _removeOwner, uint _sigRequired) external view returns (bytes memory) {
    require(_sigRequired > 0 && _sigRequired <= owners.length-1, "Number of owners and required signatures must be valid");
    require(_removeOwner != address(0), "Owner cannot be null");
    require(isOwnwer[_removeOwner], "Owner cannot be duplicated");
    // Typo and type errors will not compile
    return abi.encodeCall(this._removeSigner, (_removeOwner, _sigRequired));
  }

  // function updateSignaturesRequired()

  function _updateSignaturesRequired(uint _sigRequired) public onlySelf {
    sigRequired = _sigRequired;
  }

  function encodeCallUpdateSignaturesRequired(uint _sigRequired) external view returns (bytes memory) {
    require(_sigRequired > 0 && _sigRequired <= owners.length, "Number of owners and required signatures must be valid");
    // Typo and type errors will not compile
    return abi.encodeCall(this._updateSignaturesRequired, (_sigRequired));
  }

  

  // to support receiving ETH by default
  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }
  fallback() external payable {}
}
