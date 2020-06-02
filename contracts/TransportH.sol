/*
* Project: FLOTEA - Decentralized passenger transport system
* Copyright (c) 2020 Flotea, All Rights Reserved
* For conditions of distribution and use, see copyright notice in LICENSE
*/

pragma solidity ^0.5.1;

import "./Trip.sol";
import "./VotingCarrier.sol";

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
