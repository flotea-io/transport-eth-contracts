pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import "./Trip.sol";
import "./TransportH.sol";
import "./CarriersInterface.sol";
import "./VotingCarrier.sol";
import "./FloteaToken.sol";

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