pragma solidity ^0.5.1;
//pragma experimental ABIEncoderV2;

import "./Transport.sol";
//import "./VotingCarrier.sol";
import "./CarriersInterface.sol";

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