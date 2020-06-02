/*
* Project: FLOTEA - Decentralized passenger transport system
* Copyright (c) 2020 Flotea, All Rights Reserved
* For conditions of distribution and use, see copyright notice in LICENSE
*/

pragma solidity ^0.5.1;
//pragma experimental ABIEncoderV2;
import "./SafeMath.sol";
import "./Transport.sol";
import "./CarriersInterface.sol";

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
