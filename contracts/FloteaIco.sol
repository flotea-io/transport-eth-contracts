pragma solidity ^0.5.1;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./FloteaToken.sol";
import "./VotingIco.sol";
import "./ERC223_receiving_contract.sol";

/**
 * @title FloteaICO
 * @dev FloteaICO contract is Ownable
 **/
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
