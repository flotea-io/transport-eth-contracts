/*
* Project: FLOTEA - Decentralized passenger transport system
* Copyright (c) 2020 Flotea, All Rights Reserved
* For conditions of distribution and use, see copyright notice in LICENSE
*/

pragma solidity ^0.5.1;


library SafeMath {
  /**
   * SafeMath mul function
   * @dev function for safe multiply
   **/
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  /**
   * SafeMath div funciotn
   * @dev function for safe devide
   **/
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  /**
   * SafeMath sub function
   * @dev function for safe subtraction
   **/
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
   * SafeMath add fuction
   * @dev function for safe addition
   **/
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) public allowed;
  mapping(address => uint256) public balances;
  uint256 public totalSupply;

  event Transfer(address indexed _from, address indexed _to, uint256 value);
  event Approval(address indexed _owner, address indexed _spender, uint256 value);

  /**
   * Token transfer function
   * @dev transfer token for a specified address
   * @param _to address to transfer to.
   * @param _value amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public {
    //Safemath fnctions will throw if value is invalid
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

  /**
   * Token transferFrom function
   * @dev Transfer tokens from one address to another
   * @param _from address to send tokens from
   * @param _to address to transfer to
   * @param _value amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public {
    uint256 _allowance = allowed[_from][msg.sender];
    // Safe math functions will throw if value invalid
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
  }

  /**
   * Token balanceOf function
   * @dev Gets the balance of the specified address.
   * @param _owner address to get balance of.
   * @return uint256 amount owned by the address.
   */
  function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
  }

  /**
   * Token approve function
   * @dev Aprove address to spend amount of tokens
   * @param _spender address to spend the funds.
   * @param _value amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public {
    // To change the approve amount you first have to reduce the addresses`
    // allowance to zero by calling `approve(_spender, 0)` if it is not
    // already 0 to mitigate the race condition described here:
    // @notice https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  /**
   * Token allowance method
   * @dev Ckeck that owners tokens is allowed to send to spender
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract ERC223ReceivingContract {
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes memory _data) public;
}

contract ERC223Token is ERC20{
    using SafeMath for uint;
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    mapping(address => uint) balances; // List of user balances.

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes memory _data) public {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value, _data);
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn't contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) public {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
    }


    /**
     * @dev Returns balance of the `_owner`.
     *
     * @param _owner   The address whose balance will be returned.
     * @return balance Balance of the `_owner`.
     */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
}

contract FloteaToken is ERC223Token {
  string public constant NAME = "Flotea Token";
  string public constant SYMBOL = "FLT";
  uint8 public constant DECIMALS = 3;
  uint256 public constant INITIAL_SUPPLY = 100 * 10**6 * 10**3; // 100 milions and 3 decimals

  /**
   * Flotea Token Constructor
   * @dev Create and issue tokens to msg.sender.
   */
  constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}

contract Ownable {
  address payable public owner;

  /**
   * Ownable
   * @dev Ownable constructor sets the `owner` of the contract to sender
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * ownerOnly
   * @dev Throws an error if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * transferOwnership
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract VotingIco {
    FloteaToken token;
    address transportAddress;
    event Vote(bytes32 description, uint proposalIndex, address addr, uint8 vote);
    event FinishVoting(bytes32 description, bool result, uint proposalIndex);
    event ProposalCreated(bytes32 description, uint endTime, ActionType actionType, address actionAddress, bytes32 name, uint amount, uint proposalIndex);

    enum ActionType {add_voter, remove_voter, transfer_eth, transfer_flt}

    struct VoteStatus {
        bool voted;
        uint8 vote; // 0 no 1 yes 2 resignation
    }

    struct Proposal {
        bytes32 description;
        uint endTime;
        uint8 result; // 0 no 1 yes 2 notFinished
        ActionType actionType; // 0 add 1 remove participant 2 transfer ETH 3 transfer FLT
        address payable actionAddress; // Add/Remove participant or transfer address
        bytes32 name;  // name of added participant
        uint256 amount; // amount of transfered Wei
        mapping(address => VoteStatus) status;
    }

    struct Participant {
        bytes32 name;
        address addr;
    }

    struct ParticipantVote {
        bytes32 name;
        address addr;
        uint8 vote;
    }

    address payable public owner;
    Participant[] public participants;
    Proposal[] public proposals;

    /*
    constructor(address[] memory _participates, bytes32[] memory names) public {

        require(_participates.length == names.length, "Count of participates and names must be same");
        require(_participates.length > 2, "Count of participates must be more than 2");

        for(uint i = 0; _participates.length > i; i++){
            participants.push(Participant( names[i], _participates[i] ));
        }
        participants.length = _participates.length;
    }
    */

    function beforeCreateProposal(ActionType _actionType, address payable _actionAddress, address _senderAddress) public view returns(bool, string memory) {
        uint index = findParticipantIndex(_actionAddress);
        if(findParticipantIndex(_senderAddress) == 0)
            return(true, "You are not in participant");
        if(_actionType == ActionType.add_voter && index != 0)
            return(true, "This participant already exist");
        if(_actionType == ActionType.remove_voter && index == 0)
            return(true, "This is not participant address");
        if(_actionType == ActionType.remove_voter && participants.length <= 2)
            return(true, "Minimal count of participants is 2");
        return(false, "ok");
    }

    function createProposal( bytes32 _description, uint _durationHours, ActionType _actionType, address payable _actionAddress, bytes32 _name, uint _amount) public {
        (bool error, string memory message) = beforeCreateProposal(_actionType, _actionAddress, msg.sender);
        require (!error, message);

        uint time = now + (_durationHours * 1 hours);
        proposals.push(
            Proposal(_description, time, 2,  _actionType, _actionAddress, _name, _amount)
        );
        emit ProposalCreated(_description, time, _actionType, _actionAddress, _name, _amount, proposals.length-1);
    }

    function beforeVoteInProposal (uint proposalIndex, address senderAddress) public view returns(bool, string memory) {
        uint index = findParticipantIndex(senderAddress);
        if(index == 0)
            return(true, "You are not in participant");
        if(proposals.length <= proposalIndex)
            return(true, "Proposal not exist");
        if(proposals[proposalIndex].result != 2)
            return(true, "Proposal finished");
        if(now >= proposals[proposalIndex].endTime)
            return(true, "Time for voting is out");
        if(proposals[proposalIndex].status[senderAddress].voted)
            return(true, "You are already voted");
        return(false, "ok");
    }

    function voteInProposal (uint proposalIndex, uint8 vote) public{
        (bool error, string memory message) = beforeVoteInProposal(proposalIndex, msg.sender);
        require (!error, message);
        proposals[proposalIndex].status[msg.sender].voted = true;
        proposals[proposalIndex].status[msg.sender].vote = vote;
        emit Vote(proposals[proposalIndex].description, proposalIndex, msg.sender, vote);
    }

    function beforeFinishProposal (uint proposalIndex, address senderAddress) public view
    returns(bool error, string memory message, uint votedYes, uint votedNo) {
        uint index = findParticipantIndex(senderAddress);
        uint _votedYes = 0;
        uint _votedNo = 0;
        uint _voted = 0;
        uint _carrierVotersLength = participants.length;

        for(uint i = 0; _carrierVotersLength > i; i++){
            if( proposals[proposalIndex].status[participants[i].addr].voted ){
                _voted++;
                if(proposals[proposalIndex].status[participants[i].addr].vote == 1)
                    _votedYes++;
                if(proposals[proposalIndex].status[participants[i].addr].vote == 0)
                    _votedNo++;
            }
        }

        if(index == 0)
            return(true, "You are not in participant", _votedYes, _votedNo);
        if(proposals.length <= proposalIndex)
            return(true, "Proposal does not exist", _votedYes, _votedNo);
        if(proposals[proposalIndex].result != 2)
            return(true, "Voting has finished", _votedYes, _votedNo);
        if(now <= proposals[proposalIndex].endTime && _carrierVotersLength != _voted)
            return(true, "Voting is not finished", _votedYes, _votedNo);
        if(proposals[proposalIndex].actionType == ActionType.transfer_eth && address(this).balance < proposals[proposalIndex].amount)
            return(true, "Low ETH balance", _votedYes, _votedNo);
        if(proposals[proposalIndex].actionType == ActionType.transfer_flt && token.balanceOf(transportAddress) < proposals[proposalIndex].amount)
            return(true, "Low FLT balance", _votedYes, _votedNo);
        if(proposals[proposalIndex].actionType == ActionType.remove_voter && _carrierVotersLength == 2)
            return(true, "Minimal count of voted participants is 2", _votedYes, _votedNo);
        if(_voted <= participants.length - _voted) // Minimum participants on proposal
            return(true, "Count of voted participants must be more than 50%", _votedYes, _votedNo);
        return(false, "ok", _votedYes, _votedNo);
    }

    function finishProposal(uint proposalIndex) public {
        (bool error, string memory message, uint votedYes, uint votedNo) = beforeFinishProposal(proposalIndex, msg.sender);
        require (!error, message);

        proposals[proposalIndex].result = votedYes > votedNo? 1 : 0;

        if(votedYes > votedNo){
            if(proposals[proposalIndex].actionType == ActionType.add_voter){ // Add participant
                require(findParticipantIndex(proposals[proposalIndex].actionAddress) == 0, "This participant already exist");
                participants.push( Participant(proposals[proposalIndex].name, proposals[proposalIndex].actionAddress));
            }
            else if (proposals[proposalIndex].actionType == ActionType.remove_voter) { // Remove participant
                uint index = findParticipantIndex(proposals[proposalIndex].actionAddress) - 1;
                participants[index] = participants[participants.length-1]; // Copy last item on removed position and
                participants.length--; // decrease length
            }
            else if (proposals[proposalIndex].actionType == ActionType.transfer_eth) { // Transfer ETH
                proposals[proposalIndex].actionAddress.transfer(proposals[proposalIndex].amount);
            }
            else if (proposals[proposalIndex].actionType == ActionType.transfer_flt) { // Transfer FLT
                token.transferFrom(transportAddress, proposals[proposalIndex].actionAddress, proposals[proposalIndex].amount);
            }
        }
        emit FinishVoting(proposals[proposalIndex].description, votedYes > votedNo, proposalIndex);
    }

    function statusOfProposal (uint index) public view returns (address[] memory, bytes32[] memory, uint8[] memory) {
        require(proposals.length > index, "Proposal not exist");

        address[] memory addr = new address[](participants.length);
        bytes32[] memory name = new bytes32[](participants.length);
        uint8[] memory vote = new uint8[](participants.length);
        uint pom = 0;
        for(uint i = 0; participants.length > i; i++){
            if(proposals[index].status[participants[i].addr].voted){
                addr[pom] = participants[i].addr;
                name[pom] = participants[i].name;
                vote[pom] = proposals[index].status[participants[i].addr].vote;
                pom++;
            }
        }

        return (addr, name, vote);
    }

    function proposalsLength () public view returns (uint) {
        return proposals.length;
    }

    function participantsLength () public view returns (uint) {
        return participants.length;
    }

    function findParticipantIndex(address addr) private view returns (uint) {
        for(uint i = 0; participants.length > i; i++){
            if(participants[i].addr == addr)
            return i+1;
        }
        return 0;
    }

}

contract FloteaICO is Ownable, VotingIco, ERC223ReceivingContract {
  using SafeMath for uint256;

  uint256 public constant initialTokens = 72 * 10**6 * 10**3;

  uint public phase = 0;
  uint256[2][7] public phaseInfo;


  bool public initialized = false;
  bool public enabled = false;
  uint256 public startTime = 0;
  uint256 public raisedAmount = 0;
  /**
   * BoughtTokens
   * @dev Log tokens bought onto the blockchain
   */
  event BoughtTokens(address indexed to, uint256 value);

  /**
   * whenSaleIsActive
   * @dev ensures that the contract is still active
   **/
  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }

  /**
   * FloteaICO
   * @dev FloteaICO constructor
   **/
  constructor(address _tokenAddr, address[] memory _participates, bytes32[] memory names) public {
      token = FloteaToken(_tokenAddr);

      require(_participates.length == names.length, "Count of participates and names must be same");
      require(_participates.length > 2, "Count of participates must be more than 2");

      for(uint i = 0; _participates.length > i; i++){
          participants.push(Participant( names[i], _participates[i] ));
      }
      participants.length = _participates.length;

      phaseInfo[0] = [104700000000 * 1 , 5 * 10**6 * 1000];
      phaseInfo[1] = [104700000000 * 2 , 3 * 10**6 * 1000];
      phaseInfo[2] = [104700000000 * 3 , 1 * 10**6 * 1000];
      phaseInfo[3] = [104700000000 * 4 , 1 * 10**6 * 1000];
      phaseInfo[4] = [104700000000 * 5 , 1 * 10**6 * 1000];
      phaseInfo[5] = [104700000000 * 6 , 1 * 10**6 * 1000];
      phaseInfo[6] = [104700000000 * 10 , 60 * 10**6 * 1000];
  }

  /**
   * initialize
   * @dev Initialize the contract
   **/
  function initialize(address transport) public onlyOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() >= initialTokens); // Must have enough tokens allocated
      transportAddress = transport;
      initialized = true;
      enabled = true;
      startTime = now;
  }

  /**
   * isActive
   * @dev Determins if the contract is still active
   **/
  function isActive() public view returns (bool) {
    return (
        initialized == true &&
        enabled == true &&
        goalReached() == false // Goal must not already be reached
    );
  }


  function info() public view returns (uint, uint, uint, uint, bool, bool, uint[] memory, uint[] memory, uint ){
  uint[] memory prices = new uint[](phaseInfo.length);
  uint[] memory tokens = new uint[](phaseInfo.length);

  for (uint i = 0; i < phaseInfo.length; i++) {
    prices[i] = phaseInfo[i][0];
    tokens[i] = phaseInfo[i][1];
  }
  return (
      initialTokens,
      tokensAvailable(),
      phase,
      leftInActualPhase(),
      initialized,
      enabled,
      prices,
      tokens,
      address(this).balance
    );
  }

  /**
   * goalReached
   * @dev Function to determin is goal has been reached
   **/
  function goalReached() public view returns (bool) {
    return !(tokensAvailable() > 0);
  }

  /**
   * @dev Fallback function if ether is sent to address insted of buyTokens function
   **/
  function () external payable{
    buyTokens();
  }

  function setEnabled(bool _enabled) onlyOwner public returns (bool){
    enabled = _enabled;
    return enabled;
  }

  function getPhase() public view returns (uint res) {
    if(initialized == false)
      return 0;
    uint buyedTokens = initialTokens - tokensAvailable();
    uint p = phase;
    while (phaseInfo.length -1 > p) {
      if(phaseInfo[p][1] >= buyedTokens){
        return p;
      }
      else {
        buyedTokens -= phaseInfo[p][1];
        p++;
      }
    }
    return phaseInfo.length - 1;
  }

  function leftInActualPhase() public view returns (uint res) {
    if(initialized == false)
      return 0;
    uint buyedTokens = initialTokens - tokensAvailable();
    uint p = 0;
    while (phaseInfo.length -1 > p) {
      if(phaseInfo[p][1] >= buyedTokens){
        return phaseInfo[p][1] - buyedTokens;
      }
      else {
        buyedTokens -= phaseInfo[p][1];
        p++;
      }
    }
    return 0;
  }


  function getPrice(uint amount) public view returns (uint){
    if(initialized == false)
      revert("Token is not initialized");
    if(amount > tokensAvailable())
      revert("Error, we have a few tokens");
    uint buyedTokens = initialTokens - tokensAvailable();
    uint p = phase;
    uint price = 0;
    uint freeTokensInPhase = 0;

    while (amount != 0) {
      freeTokensInPhase = phaseInfo[p][1] - buyedTokens;
      if(freeTokensInPhase > 0){
        if(freeTokensInPhase >= amount){
          return (price + amount * phaseInfo[p][0]);
        }
        else{
          price += freeTokensInPhase * phaseInfo[p][0];
          amount -= freeTokensInPhase;
          buyedTokens = 0;
          p++;
        }
      }
      else {
        buyedTokens -= phaseInfo[p][1];
        p++;
      }
    }
    revert("Error in method getPrice");
  }

  function getTokensForWei(uint weiAmount) public view returns(uint) {
    if(initialized == false)
      revert("Token is not initialized");
    if(weiAmount < 1030195016000)
      revert("min wei is 1030195016000");
    uint amount = weiAmount;
    uint buyedTokens = initialTokens - tokensAvailable();
    uint p = phase;
    uint tokens = 0;
    uint freeTokensInPhase = 0;
    while (amount > 0) {
      freeTokensInPhase = phaseInfo[p][1] - buyedTokens;
      if(freeTokensInPhase > 0){
        if(freeTokensInPhase * phaseInfo[p][0] >= amount){
          return tokens + amount / phaseInfo[p][0];
        } else {
          tokens += freeTokensInPhase;
          amount -= freeTokensInPhase * phaseInfo[p][0];
          buyedTokens = 0;
          p++;
        }
      }
      else {
        buyedTokens -= phaseInfo[p][1];
        p++;
      }
      if(p >= phaseInfo.length)
        revert("Error, we have a few tokens");
    }
    revert("Error in method getTokensForWei");
  }

  function buyOverBackend(address buyer, uint tokens) public onlyOwner returns(bool res) {
    if(tokensAvailable() <= tokens)
      revert("Error, we have a few tokens");
    token.transfer(buyer, tokens);
    emit BoughtTokens(msg.sender, tokens);
    phase = getPhase();
    return true;
  }


  // je potřeba aby se tal token koupit přes ETH i přes Backend přes vlastníka


  /**
   * buyTokens
   * @dev function that sells available tokens
   **/

  function buyTokens() public payable whenSaleIsActive {

    uint tokens = getTokensForWei(msg.value);
    if(tokens < 1)
      revert("Error, too little amount of ethereum");

    raisedAmount = raisedAmount.add(msg.value); // Increment raised amount

    if(tokens > 0)
      token.transfer(msg.sender, tokens); // Send tokens to buyer
    else
      msg.sender.transfer(msg.value);


    emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain*/
    //owner.transfer(msg.value);// Send money to owner

    phase = getPhase();
  }

  /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to this contract
   **/
  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function tokenFallback(address _from, uint _value, bytes memory _data) public {
  }

  function weiAvailable() public view returns (uint256) {
      return address(this).balance;
  }
}

contract CarriersInterface {
	function init() public;
	function updateCarrier(bytes32 _company, bytes32 _web) public;
	function carrierLength() public view returns(uint length);
	function getCarrierId(address _companyWallet) public view returns(uint carrierId);
	function carrierExist (address payable addr) public view returns(bool exist, uint carrierId);
	function getCarrierData(address _companyWallet) public view returns(bool exist, uint id, bytes32 company, bytes32 web);
	function getCarrierAddress(uint _carrierId) public view returns(address payable carrier);
	function testCarrier (address _companyWallet) public view returns(bool, string memory, uint);
	function addCarrier( bytes32 _company, bytes32 _web, address payable _companyWallet ) public;
	function setBanCarrier(address _companyWallet, bool _ban) public;
	function addTrip(uint _carrierId, address _tripAddress) public;
}

contract VotingCarrier {

    event VoteCarrier(uint proposalIndex, address addr, uint8 vote);
    event FinishVotingCarrier(bool result, uint proposalIndex, uint votedYes, uint votedNo, uint resigned, uint totalVoters);
    event CarrierProposalCreated(bytes32 name, bytes32 web, uint endTime, uint8 actionType, address actionAddress, uint proposalIndex);

    struct VoteCarrierStatus {
        bool voted;
        uint8 vote; // 0 no 1 yes 2 resigned
    }

    struct CarrierProposal {
        bytes32 name;  // name of added carrier
        bytes32 web;
        uint endTime;
        uint8 result; // 0 no 1 yes 2 notFinished
        uint8 actionType; // 0 add 1 remove carrier
        address payable actionAddress; // Add/Remove carrier or transfer address
        mapping(address => VoteCarrierStatus) status;
    }

    struct CarrierVoter {
        address payable addr;
        bool enabled;
    }

    struct CarrierVoterVote {
        bytes32 name;
        address addr;
        uint8 vote;
    }

    CarriersInterface carriers;
    address payable public owner;
    CarrierVoter[] public carrierVoters;
    CarrierProposal[] public carrierProposals;

    constructor(address payable firstVoter, address payable secondVoter) public {
        carrierVoters.push(CarrierVoter( firstVoter, true ));
        carrierVoters.push(CarrierVoter( secondVoter, true ));
        carrierVoters.length = 2;
    }

    function init(address _carriersAddress) public {
        require(address(carriers) == address(0), "Contract is already initialized");
        carriers = CarriersInterface(_carriersAddress);
    }


    function beforeCreateCarrierProposal(uint8 _actionType, address payable _actionAddress) public view returns(bool, string memory) {
        uint index = findCarrierVoterIndex(_actionAddress);
        if(_actionType == 0 && index != 0 && carrierVoters[index-1].enabled)
            return(true, "This carrier is already enabled");
        if(_actionType == 1 && index == 0)
            return(true, "This carrier not exist");
        if(_actionType == 1 && carrierVoters.length <= 2)
            return(true, "Minimal count of participants is 2");
        return(false, "ok");
    }

    function createCarrierProposal( bytes32 _name, bytes32 _web, uint8 _actionType, address payable _actionAddress) public{

        (bool error, string memory message) = beforeCreateCarrierProposal(_actionType, _actionAddress);
        require (!error, message);

        /* for production 14 days */
        uint time = now + 1 hours;
        carrierProposals.push(
            CarrierProposal(_name, _web , time, 2,  _actionType, _actionAddress)
        );
        emit CarrierProposalCreated(_name, _web, time, _actionType, _actionAddress, carrierProposals.length-1);
    }

    function beforeVoteInCarrierProposal (uint proposalIndex, address senderAddress) public view returns(bool, string memory) {
        uint index = findCarrierVoterIndex(senderAddress);
        if(index == 0)
            return(true, "You are not in voters");
        if(!carrierVoters[index-1].enabled)
            return(true, "You are banned");
        if(carrierProposals.length <= proposalIndex)
            return(true, "Proposal not exist");
        if(carrierProposals[proposalIndex].result != 2)
            return(true, "CarrierProposal finished");
        if(now >= carrierProposals[proposalIndex].endTime)
            return(true, "Time for voting is out");
        if(carrierProposals[proposalIndex].status[senderAddress].voted)
            return(true, "You are already voted");
        return(false, "ok");
    }

    function voteInCarrierProposal (uint proposalIndex, uint8 vote) public {
        (bool error, string memory message) = beforeVoteInCarrierProposal(proposalIndex, msg.sender);
        require (!error, message);
        carrierProposals[proposalIndex].status[msg.sender].voted = true;
        carrierProposals[proposalIndex].status[msg.sender].vote = vote;
        emit VoteCarrier(proposalIndex, msg.sender, vote);
    }

    function beforeFinishCarrierProposal (uint proposalIndex) public view
    returns(bool error, string memory message, uint votedYes, uint votedNo, uint resigned) {
        uint _votedYes = 0;
        uint _votedNo = 0;
        uint _resigned = 0;
        uint _voted = 0;
        uint _carrierVotersLength = carrierVoters.length;

        if(carrierProposals.length <= proposalIndex)
            return(true, "Proposal not exist", _votedYes, _votedNo, _resigned);

        for(uint i = 0; _carrierVotersLength > i; i++){
            if( carrierProposals[proposalIndex].status[carrierVoters[i].addr].voted ){
                _voted++;
                if(carrierProposals[proposalIndex].status[carrierVoters[i].addr].vote == 2)
                    _resigned++;
                if(carrierProposals[proposalIndex].status[carrierVoters[i].addr].vote == 1)
                    _votedYes++;
                if(carrierProposals[proposalIndex].status[carrierVoters[i].addr].vote == 0)
                    _votedNo++;
            }
        }

        if(carrierProposals[proposalIndex].result != 2)
            return(true, "Proposal has finished", _votedYes, _votedNo, _resigned);
        if(now <= carrierProposals[proposalIndex].endTime && _carrierVotersLength != _voted)
            return(true, "Voting is not finished", _votedYes, _votedNo, _resigned);
        if(carrierProposals[proposalIndex].actionType == 1 && _carrierVotersLength == 2)
            return(true, "Minimal count of participants is 2", _votedYes, _votedNo, _resigned);
        return(false, "ok", _votedYes, _votedNo, _resigned);
    }


    function finishCarrierProposal(uint proposalIndex) public{
        (bool error, string memory message, uint votedYes, uint votedNo, uint resigned) = beforeFinishCarrierProposal(proposalIndex);
        require (!error, message);

        carrierProposals[proposalIndex].result = votedYes > votedNo? 1 : 0;
        uint carrierVotersLength = carrierVoters.length;
        address payable actionAddress = carrierProposals[proposalIndex].actionAddress;
        uint carrierId = findCarrierVoterIndex(actionAddress);

        if(votedYes > votedNo){
            if(carrierProposals[proposalIndex].actionType == 0 && (carrierId == 0 || (carrierId != 0 && !carrierVoters[carrierId-1].enabled))){ // Add Voter
                if(carrierId == 0){
                    carrierVoters.push( CarrierVoter(actionAddress, true));
                    carriers.addCarrier(carrierProposals[proposalIndex].name, carrierProposals[proposalIndex].web, actionAddress);
                } else {
                    carrierVoters[carrierId-1].enabled = true;
                    carriers.setBanCarrier(actionAddress ,false);
                }
            }
            if (carrierProposals[proposalIndex].actionType == 1 && (carrierId != 0 && carrierVoters[carrierId-1].enabled) && carrierVotersLength > 2) { // Remove Voter
                carrierVoters[carrierId-1] = carrierVoters[carrierVotersLength-1]; // Copy last item on removed position and
                carrierVoters.length--; // decrease length
                (bool exist, ) = carriers.carrierExist(actionAddress);
                if(exist) // For init voters
                    carriers.setBanCarrier(actionAddress ,true);
            }
        }
        emit FinishVotingCarrier(votedYes > votedNo, proposalIndex, votedYes, votedNo, resigned, carrierVotersLength);
    }

    function statusOfCarrierProposal (uint index) public view returns (address[] memory, uint8[] memory) {
        require(carrierProposals.length > index, "Carrier proposal not exist");

        address[] memory addr = new address[](carrierVoters.length);
        uint8[] memory vote = new uint8[](carrierVoters.length);
        uint pom = 0;
        for(uint i = 0; carrierVoters.length > i; i++){
            if(carrierProposals[index].status[carrierVoters[i].addr].voted){
                addr[pom] = carrierVoters[i].addr;
                vote[pom] = carrierProposals[index].status[carrierVoters[i].addr].vote;
                pom++;
            }
        }

        return (addr, vote);
    }

    function proposalsLength () public view returns (uint) {
        return carrierProposals.length;
    }

    function VotersLength () public view returns (uint) {
        return carrierVoters.length;
    }

    function findCarrierVoterIndex(address addr) private view returns (uint) {
        for(uint i = 0; carrierVoters.length > i; i++){
            if(carrierVoters[i].addr == addr)
            return i+1;
        }
        return 0;
    }

}

contract TransportH {


    struct TripStruct {
        address addr;
        bool enabled;
        bool exist;
    }

    enum RouteType {tram,metro,rail,bus,ferry,cablecar,gondola,funicular,railway_service,high_speed_rail_service,long_distance_trains,inter_regional_rail_service,car_transport_rail_service,sleeper_rail_service,regional_rail_service,tourist_railway_service,rail_shuttle_within_complex,suburban_railway,replacement_rail_service,special_rail_service,lorry_transport_rail_service,all_rail_services,cross_country_rail_service,vehicle_transport_rail_service,rack_and_pinion_railway,additional_rail_service,coach_service,international_coach_service,national_coach_service,shuttle_coach_service,regional_coach_service,special_coach_service,sightseeing_coach_service,tourist_coach_service,commuter_coach_service,all_coach_services,suburban_railway_service,urban_railway_service,metro_service,underground_service,all_urban_railway_services,monorail,bus_service,regional_bus_service,express_bus_service,stopping_bus_service,local_bus_service,night_bus_service,post_bus_service,special_needs_bus,mobility_bus_service,mobility_bus_for_registered_disabled,sightseeing_bus,shuttle_bus,school_bus,school_and_public_service_bus,rail_replacement_bus_service,demand_and_response_bus_service,all_bus_services,trolleybus_service,tram_service,city_tram_service,local_tram_service,regional_tram_service,sightseeing_tram_service,shuttle_tram_service,all_tram_services,water_transport_service,international_car_ferry_service,national_car_ferry_service,regional_car_ferry_service,local_car_ferry_service,international_passenger_ferry_service,national_passenger_ferry_service,regional_passenger_ferry_service,local_passenger_ferry_service,post_boat_service,train_ferry_service,road_link_ferry_service,airport_link_ferry_service,car_high_speed_ferry_service,passenger_high_speed_ferry_service,sightseeing_boat_service,school_boat,cable_drawn_boat_service,river_bus_service,scheduled_ferry_service,shuttle_ferry_service,all_water_transport_services,air_service,international_air_service,domestic_air_service,intercontinental_air_service,domestic_scheduled_air_service,shuttle_air_service,intercontinental_charter_air_service,international_charter_air_service,round_trip_charter_air_service,sightseeing_air_service,helicopter_air_service,domestic_charter_air_service,schengen_area_air_service,airship_service,all_air_services,ferry_service,telecabin_service,cable_car_service,elevator_service,chair_lift_service,drag_lift_service,small_telecabin_service,all_telecabin_services,funicular_service,all_funicular_service,taxi_service,communal_taxi_service,water_taxi_service,rail_taxi_service,bike_taxi_service,licensed_taxi_service,private_hire_service_vehicle,all_taxi_services,self_drive,hire_car,hire_van,hire_motorbike,hire_cycle,miscellaneous_service,cable_car,horse_drawn_carriage} // https://transit.land/documentation/datastore/routes-and-route-stop-patterns.html#vehicle_types

    modifier onlyTrip() {
        uint index = tripsId[msg.sender];
        require(index > 0 || trips[0].addr == msg.sender , "Trip not exist");
        _;
    }

    event TransportInitialized(address votingCarrier, address carriers);

    event NewCarrier(address _companyWallet, bytes32 _company, bytes32 _web, uint _index);
    event CarrierUpdated(address _companyWallet, bytes32 _company, bytes32 _web, uint _index);

    event TripEvent(address _trip, uint _tripId, string _eventType);

    event PurchasedTickets(address _trip, uint _tripId, uint _tickets, address _buyerAddr, uint _price, uint _time);
    event RefundedTickets(address _trip, uint _tripId, uint _tickets, address _buyerAddr);


    mapping(address => uint) public tripsId;
    address public tokenAddress;
    address public floteaIcoAddress;
    VotingCarrier votingCarrier;
    TripStruct[] public trips;

    function emitTripUpdateEvent(uint _tripId, string memory updateType) public onlyTrip{
        emit TripEvent(msg.sender, _tripId, updateType);
    }

    function emitPurchasedTicket (uint _tripId, uint _tickets, address _buyerAddr, uint _price, uint _time) public onlyTrip{
        emit PurchasedTickets(msg.sender, _tripId, _tickets, _buyerAddr, _price, _time);
    }

    function emitRefundedTickets (uint _tripId, uint _tickets, address _buyerAddr) public onlyTrip{
        emit RefundedTickets(msg.sender, _tripId, _tickets, _buyerAddr);
    }

}

contract Trip is Ownable, ERC223ReceivingContract{

    struct TripLoc {
        bytes10 fromLat;
        bytes11 fromLng;
        bytes10 toLat;
        bytes11 toLng;
    }

    struct Ticket {
        address buyer;
        address agency;
        uint time;
        bool purchased;
        bool refunded;
    }

    struct TicketInTime {
        uint16 tickets;
        uint[] indexes;
    }

    event Charged(address carrierAddress, uint amount, address tripContract);

    FloteaToken token;
    Transport transport;
    uint carrierId;
    uint tripId;
    TripLoc tripLoc;
    uint price;
    bytes[] schedule;
    uint16 places;
    bytes description;
    TransportH.RouteType routeType;
    bool enabled;
    Ticket[] tickets;
    mapping (uint => TicketInTime) purchasedTicketInTime;

    modifier onlyTripOwner() {
        require(msg.sender == transport.getCarriers().getCarrierAddress(carrierId));
        _;
    }

    constructor (uint _carrierId, uint _tripId, TripLoc memory _tripLoc, uint _price,
        bytes[] memory _schedule, uint16 _places, bytes memory _description,
        TransportH.RouteType _routeType, bool _enabled) public {
        transport = Transport(msg.sender);
        token = FloteaToken(transport.tokenAddress());
        carrierId = _carrierId;
        tripId = _tripId;
        tripLoc = _tripLoc;
        price = _price;
        schedule = _schedule;
        places = _places;
        description = _description;
        routeType = _routeType;
        enabled = _enabled;
    }

    function setArribute(TripLoc memory _tripLoc, uint _price,
        bytes[] memory _schedule, uint16 _places, bytes memory _description) public onlyTripOwner {
        tripLoc = _tripLoc;

        if(_price != 0)
        price = _price;
        if(_schedule[0][0] != 0)
        schedule = _schedule;
        if(_places > 0)
        places = _places;
        if(_description[0] != 0)
        description = _description;
        transport.emitTripUpdateEvent(tripId, "setArribute");
    }

    function setVehicle(TransportH.RouteType _routeType) public onlyTripOwner{
        routeType = _routeType;
        transport.emitTripUpdateEvent(tripId, "setVehicle");
    }

    function setEnabled(bool _enabled) public onlyTripOwner{
        enabled = _enabled;
        transport.setEnabled(_enabled);
        transport.emitTripUpdateEvent(tripId, "setEnabled");
    }

    function info() public view returns(address carrierAddress, uint _carrierId, TripLoc memory _tripLoc,
        uint _price, bytes[] memory _schedule, uint16 _places, bytes memory _description, bool _enabled, address _token, TransportH.RouteType _routeType){
        return(transport.getCarriers().getCarrierAddress(carrierId), carrierId, tripLoc, price, schedule, places, description, enabled, address(token), routeType);
    }

    function getCarrierAddress () public view returns(address) {
        return transport.getCarriers().getCarrierAddress(carrierId);
    }

    function getCarrierId () public view returns(uint) {
        return carrierId;
    }

    function getTripId () public view returns(uint) {
        return tripId;
    }

    function refund(address _buyer, uint _time, uint _count) public onlyTripOwner {
        uint founded = 0;
        TicketInTime memory purchasedTicket = purchasedTicketInTime[_time]; // Tickets in time
        for(uint i = 0; purchasedTicket.indexes.length > i; i++) {
            if(tickets[ purchasedTicket.indexes[i] ].buyer == _buyer && !tickets[ purchasedTicket.indexes[i] ].refunded && founded <= _count){ // Find first founded ticket from buyer
                founded++;
                tickets[ purchasedTicket.indexes[i] ].refunded = true;
                purchasedTicket.tickets--; // Decrease buyed tickets
            }
        }
        if(founded > 0){
            transport.emitRefundedTickets ( tripId, founded, _buyer);
            token.transfer(_buyer, price*founded); // Refund tokens
            return;
        }
        require (false, "Ticket not found");
    }

    function getTickets() public view returns(address[] memory addresses, uint[] memory times){
        address[] memory tempAddreses = new address[](tickets.length);
        uint[] memory tempTimes = new uint[](tickets.length);

        for(uint i = 0; tickets.length > i; i++){
            if(!tickets[i].refunded){
                tempAddreses[i] = tickets[i].buyer;
                tempTimes[i] = tickets[i].time;
            }
        }
        return (tempAddreses, tempTimes);
    }

    function getTickets(uint _time) public view returns(uint16 ticketsArray, uint[] memory indexesArray){
        return (purchasedTicketInTime[_time].tickets, purchasedTicketInTime[_time].indexes);
    }

    function getIndex(address[] memory agencies, address search) private pure returns(uint index){
        for(uint i = 0; i < agencies.length; i++){
            if(agencies[i] == search)
            return i+1;
        }
        return 0;
    }

    function charge(address _to) public onlyTripOwner {
        address[] memory agencies;
        uint[] memory tocharge;
        uint al = 0;
        uint carrier = 0;
        uint toContract = 0;
        for(uint i = 0; tickets.length > i; i++) {
            if(!tickets[i].purchased && !tickets[i].refunded && tickets[i].time < now){
                if(tickets[i].agency != address(0)){
                    uint index = getIndex(agencies, tickets[i].agency);
                    if(index == 0){
                        agencies[al] = tickets[i].agency; // Add to array of agencies for charge
                        tocharge[al] += price / 10; // 10%
                        al++;
                    } else {
                        tocharge[index-1] += price / 10; // 10%
                    }
                    carrier += price - price * 101 / 1000; // price - 0,1% - 10%
                } else {
                    carrier += price - price / 1000; // price - 0,1%
                }
                toContract += price / 1000; // 0,1%
                tickets[i].purchased = true;
            }
        }
        if(_to == address(0)){
            _to = transport.getCarriers().getCarrierAddress(carrierId);
        }
        emit Charged(_to, carrier, address(this));
        token.transfer(_to, carrier); // Transfer to carrier
        token.transfer(address(transport), toContract); // Transfer to toContract company
        for(uint i = 0; i < al; i++){
             token.transfer(agencies[i], tocharge[i]); // Transfer to agency
        }
    }

    function beforeBuy (uint _value, bytes memory _data) public view returns(bool, string memory){
        // check if user have enough tokens
        if(token.balanceOf(msg.sender) < _value)
        return ( true, "You do not have enough FLT tokens");
        if(!enabled)
        return( true, "Trip is disabled");
        (uint count, uint time,) = decodeBytes(_data);
        if(_value != price*count)
        return( true, "Wrong price");
        if(time <= now)
        return( true, "The trip at this time is over");
        TicketInTime memory purchasedTicket = purchasedTicketInTime[time];
        if (places - purchasedTicket.tickets < count)
        return( true, "Not enough tickets");
        return(false, "ok");
    }


    // Buing ticket
    function tokenFallback(address _from, uint _value, bytes memory _data) public {
        require(msg.sender == address(token), "This funcion must be called from Flotea Token");
        require(enabled, "Trip is disabled");
        (uint count, uint time, address agency) = decodeBytes(_data);
        require(_value == price*count, "Wrong price");
        require(time > now, "The trip at this time is over");
        TicketInTime memory purchasedTicket = purchasedTicketInTime[time];
        require (places - purchasedTicket.tickets >= count , "Not enough tickets");

        transport.emitPurchasedTicket(tripId, count, _from, price, time);

        for(uint i=0; i < count; i++){
            purchasedTicketInTime[time].tickets++;
            purchasedTicketInTime[time].indexes.push(tickets.length);
            tickets.push( Ticket(_from, agency, time, false, false) );
        }
    }

    //
    function decodeBytes(bytes memory b) private pure returns (uint, uint, address){
        address agency;
        uint pos = 0;
        if(b.length>20){
            assembly {
                agency := mload(add(b,20))
            }
            pos = 20;
        }
        uint count;
        uint time;
        int p = -1;
        for(uint i=pos;i<pos+2;i++){
            if(b[i] != 0 && p == -1){
                p = int(i);
            }
            if(p!=-1){
                count = count + uint8(b[i])*(2**(8*(2-(i+1-pos))));
            }
        }
        for(uint i=pos+2;i<b.length;i++){
            time = time + uint8(b[i])*(2**(8*(b.length -(i+1))));
        }
        return (count, time, agency);
    }
}

contract Transport is TransportH{
    CarriersInterface carriers;

    constructor(address _tokenAddress, address _votingCarrierAddress, address _carriersAddress, address _floteaIcoAddress) public {
        tokenAddress = _tokenAddress;
        floteaIcoAddress = _floteaIcoAddress;

        VotingCarrier votingCarrier = VotingCarrier(_votingCarrierAddress);
        carriers = CarriersInterface(_carriersAddress);
        carriers.init();
        votingCarrier.init(address(carriers));
    }

    function approve() public {
        FloteaToken(tokenAddress).approve(floteaIcoAddress, 10**11); // Approve to transfer tokens from Transport
    }


    function tripsLength() public view returns(uint length){
        return trips.length;
    }

    function getCarriers() public view returns(CarriersInterface) {
        return carriers;
    }

    function setEnabled(bool _enabled) public {
        require(trips.length > 0 && trips[tripsId[msg.sender]].addr == msg.sender, "Only contract Trip can call this method");
        trips[tripsId[msg.sender]].enabled = _enabled;
    }

    function emitCarrier(bool isNew, address _companyWallet, bytes32 _company, bytes32 _web, uint _index) public{
        require(address(carriers) == msg.sender, "Only contract Carriers can call this method");
        if(isNew)
            emit NewCarrier(_companyWallet, _company, _web, _index);
        else
            emit CarrierUpdated(_companyWallet, _company, _web, _index);
    }

    function createTrip (Trip.TripLoc memory _tripLoc, uint _price,
    bytes[] memory _schedule, uint16 _places, bytes memory _description,
    RouteType _routeType, bool _enabled) public {
        (bool error, string memory message, uint carrierId) = carriers.testCarrier(msg.sender);
        require (!error, message);

        Trip newTrip = new Trip(
            carrierId, trips.length,
            _tripLoc,
            _price, _schedule, _places,
            _description, _routeType, _enabled
        );
        carriers.addTrip(carrierId, address(newTrip));
        tripsId[address(newTrip)] = trips.length;
        emit TripEvent(address(newTrip), trips.length, "new");
        trips.push( TripStruct(address(newTrip), true, true) );
    }
}

contract Carriers is CarriersInterface{

	struct Carrier {
        address payable companyWallet;
        bytes32 company;
        bytes32 web;
        bool enabled;
        address[] trips;
        bool exist;
    }

    Carrier[] public carriers;
    mapping(address => uint) public carriersId;
	Transport transport;
	address votingCarrierAddress;

	constructor(address _votingCarrierAddress) public {
        votingCarrierAddress = _votingCarrierAddress;
    }

    function init() public {
        require(address(transport) == address(0), "Contract is already initialized");
        transport = Transport(msg.sender);
    }

    function updateCarrier(bytes32 _company, bytes32 _web) public {
        uint index = carriersId[msg.sender];
        require(carriers[index].exist , "Carrier not exist");
        if(_company != 0x00)
            carriers[index].company = _company;
        else _company = carriers[index].company;
        if(_web != 0x00)
            carriers[index].web = _web;
        else _web = carriers[index].web;

        transport.emitCarrier(false, msg.sender, _company, _web, index);
    }

    function carrierLength() public view returns(uint length){
        return carriers.length;
    }

    function getCarrierId(address _companyWallet) public view returns(uint carrierId){
        uint _carrierId = carriersId[_companyWallet];
        require(_carrierId < carriers.length && carriers[_carrierId].exist, "Carrier not exist");
        return _carrierId;
    }

    function carrierExist(address payable _companyWallet) public view returns(bool exist, uint carrierId) {
        uint id = carriersId[_companyWallet];
        return (carriers[id].companyWallet == _companyWallet, id);
    }

    function getCarrierData(address _companyWallet) public view returns(bool exist, uint id, bytes32 company, bytes32 web){
        uint _id = carriersId[_companyWallet];
        if(_id == carriers.length || carriers[_id].companyWallet != _companyWallet)
            return (false, _id, "", "");
        else
            return (true, _id, carriers[_id].company, carriers[_id].web);
    }

    function getCarrierAddress(uint _carrierId) public view returns(address payable carrier){
        require(_carrierId < carriers.length, "Wrong carrier ID");
        return carriers[_carrierId].companyWallet;
    }

    function testCarrier(address _companyWallet) public view returns(bool banned, string memory errorText, uint carrierId) {
        uint _carrierId = carriersId[_companyWallet];
        if(_carrierId == carriers.length || carriers[_carrierId].companyWallet != _companyWallet)
            return(true, "You are not in carriers", _carrierId);
        else if(carriers[_carrierId].enabled)
            return(false, "", _carrierId);
        else
            return(true, "You are banned", _carrierId);
    }

    function addCarrier( bytes32 _company, bytes32 _web, address payable _companyWallet ) public {
        require(msg.sender == votingCarrierAddress, "Only contract VotingCarrier can call this method");
        address[] memory _trips;
        transport.emitCarrier(true, _companyWallet, _company, _web, carriers.length);

        carriersId[_companyWallet] = carriers.length;
        carriers.push(Carrier(_companyWallet, _company, _web, true, _trips, true));
    }

    function setBanCarrier(address _companyWallet, bool _ban) public{
        require(msg.sender == votingCarrierAddress, "Only contract VotingCarrier can call this method");
        uint _carrierId = getCarrierId(_companyWallet);
        require(carriers[_carrierId].exist, "Carrier not exist");
        carriers[_carrierId].enabled = !_ban;
    }


    function addTrip(uint _carrierId, address _tripAddress) public{
        require(msg.sender == address(transport), "Only contract VotingCarrier can call this method");
    	carriers[_carrierId].trips.push(_tripAddress);
    }

}
