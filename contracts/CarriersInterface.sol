pragma solidity ^0.5.1;

import "./Transport.sol";
import "./VotingCarrier.sol";

contract CarriersInterface{
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