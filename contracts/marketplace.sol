//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

//TODO
//finish dispute system
//mods vote, buyer is or isn't refunded
//do larger stakes through windows i.e any position 1-100 belongs to 0xanon etc

contract marketplace {

struct listing {
    string details;
    uint price;
    uint quantity;
    uint sales;
    address seller;
}

struct order {
    uint listing;
    uint price;
    uint EscrowTimeOut;
    address buyer;
}

struct dispute {
   bool isOrder;
   uint id;
   mapping(uint => address) mods;
   uint modAmount;
   int vote;
}

struct mod{
    address modAddress;
    mapping (uint => uint) activeDisputes;
    uint disputeCount;
}

mapping (uint => dispute) public disputes;
mapping (uint => order) public orders;
mapping(uint => listing) public listings;
mapping(uint => address) public modList;
mapping(address => mod) public mods;
uint listingcounter;
uint disputecounter;
uint modcounter;
uint ordercounter;

    function list(string memory details, uint price) public returns(uint) {
        listingcounter++;
        listing storage listing_ = listings[listingcounter];
        listing_.details=details;
        listing_.price=price;
        listing_.seller=msg.sender;
        return listingcounter;
    } 

    function buy (uint listingID) public payable {
    
     listing storage listing_ = listings[listingID];
     require (msg.value == listing_.price && listing_.quantity > 0);
     listing_.quantity--;
     ordercounter++;
     order storage order_ = orders[ordercounter];
     order_.EscrowTimeOut=block.timestamp+1204800;
     order_.buyer=msg.sender;
     order_.price=listing_.price;
     order_.listing=listingID;
    }

    function orderDispute(uint id) public {
        order storage order_ = orders[id];
        require (order_.buyer==msg.sender);
        disputecounter++;
        dispute storage dispute_=disputes[disputecounter];
        dispute_.id=id;
        dispute_.modAmount=1;
        uint rand= uint(blockhash(block.number - 1));
        rand=rand%modcounter;
        dispute_.mods[1]=modList[rand];
    }
    function disputeDispute(uint id) public{
       address buyer = findBuyer(id);
       require (msg.sender==buyer);
        dispute storage dispute_=disputes[disputecounter];
        dispute_.id=id;
        dispute_.modAmount=(disputes[id].modAmount*2);
    }

    function findBuyer(uint id) public returns(address){
        dispute storage dispute_=disputes[id];
        if(dispute_.isOrder==true){
        order storage order_ = orders[dispute_.id];
        return order_.buyer;
        }
        else{
            return findBuyer(dispute_.id);
        }

    }

    function vote(bool agree, uint id) public {
        dispute storage dispute_=disputes[id];
        uint i;
        for(i=0; i<=dispute_.modAmount; i++){
        if (dispute_.mods[i]==msg.sender){
            if (agree==true){
                dispute_.vote++;
            }
            else{
                dispute_.vote--;
            }
        }
        }
            
    }
    function checkdispute(uint id)public{
        dispute storage dispute_=disputes[id];
        if (dispute_.isOrder==true){
            if (uint(dispute_.vote)==dispute_.modAmount){
            order storage order_ = orders[dispute_.id];
            address payable buyer =payable(order_.buyer);
            (buyer).transfer(order_.price-((order_.price/(10/dispute_.modAmount))));
            }
           
        }

    }

    function becomeMod () public payable{
        require(msg.value==1000000000000000000);
        if (modcounter<1){
            modcounter++;
        }
        modList[modcounter] = msg.sender;
        modcounter++;
    }

    function withdraw (uint listingID, address payable receiver) public {
        listing storage listing_ = listings[listingID];
        require (listing_.seller==msg.sender);
        (receiver).transfer(listing_.price);
    }




}