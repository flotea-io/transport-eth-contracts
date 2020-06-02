/*
* Project: FLOTEA - Decentralized passenger transport system
* Copyright (c) 2020 Flotea, All Rights Reserved
* For conditions of distribution and use, see copyright notice in LICENSE
*/

pragma solidity ^0.5.1;

import "./SafeMath.sol";
import "./ERC20.sol";
import './ERC223Token.sol';


/**
 * @title Flotea Token
 * @dev Simple Token with standard token functions.
 */
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
