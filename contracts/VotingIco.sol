/*
* Project: FLOTEA - Decentralized passenger transport system
* Copyright (c) 2020 Flotea, All Rights Reserved
* For conditions of distribution and use, see copyright notice in LICENSE
*/

pragma solidity ^0.5.1;

import "./SafeMath.sol";
import "./FloteaToken.sol";

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
