pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./Transport.sol";
import "./TransportH.sol";
import "./FloteaToken.sol";
import "./ERC223_receiving_contract.sol";

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