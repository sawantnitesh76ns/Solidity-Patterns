// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract BurgerShopAccessControll {
    //Convert ether into Wei
    uint256 public normalCost = 0.2 ether;
    uint256 public deluxCost = 0.4 ether;
    address public manager;
    address public owner;
    uint256 public startDate = block.timestamp + 30 seconds;
    mapping(address => uint256) public customers;
    mapping(address => uint256) public userRefund;

    constructor() {
        owner = msg.sender;
        manager = msg.sender;
    }
    
    //Creating mapping that will store customer address and total amount he spend till now
    
    

    event BoughtBurger(address indexed _from, uint256 cost);

    enum Stages {
        readyToOrder,
        makeBurger,
        deliverBurger
    }

    Stages public burgerShopStatge = Stages.readyToOrder;

    modifier onlyOwner() {
        require( msg.sender == owner, "Not the owner");
        _;
    }

    modifier shopOpened() {
        require( block.timestamp > startDate, "This is not opened yet!");
        _;
    }

    modifier shouldPay(uint256 _cost) {
        require(msg.value >= _cost, "The burger cost more" );
        _;
    }

    modifier isAtStage(Stages _stage) {
        require( burgerShopStatge == _stage, "Not At Correct Stage");
        _;
    }

    modifier refundAmount(address _to, uint256 _cost) {
        //Check the refund is initiated by manager only
        require(msg.sender == manager, "The rquest must be initiated by manager only");
        //Check the refund cost amount
        require(_cost == normalCost || _cost == deluxCost, "You are trying to refund werong amount");
        //Check the customer had purchase enough to refund his amount
        require(customers[_to] >= _cost, "The receiver dont have enough funds");

        _;
    }

    function buyBurger() payable public shouldPay(normalCost) isAtStage(Stages.readyToOrder) shopOpened {
        // require(msg.value >= cost, "The burger cost more" );
        if(customers[msg.sender] != 0){
            customers[msg.sender] = customers[msg.sender] + msg.value; 
        }
        else {
            customers[msg.sender] = msg.value; 
        }
        updateStage(Stages.makeBurger);
        emit BoughtBurger(msg.sender, normalCost);
    }

    function buyDeluxBurger() payable public shouldPay(deluxCost) isAtStage(Stages.readyToOrder) shopOpened {
        // require(msg.value >= cost, "The burger cost more" );
        if(customers[msg.sender] != 0){
            customers[msg.sender] = customers[msg.sender] + msg.value; 
        }
        else {
            customers[msg.sender] = msg.value; 
        }
        updateStage(Stages.makeBurger);
        emit BoughtBurger(msg.sender, normalCost);
    }

    function refund(address _to, uint256 _cost) payable public refundAmount(_to, _cost) onlyOwner{
        require(address(this).balance >= _cost, "Not Enough Funds");
        userRefund[_to] = _cost;
        // uint256 balanceBeforeTransfer = address(this).balance;
        // if(balanceBeforeTransfer >= _cost){
        //     (bool success, ) = payable(_to).call{value: _cost}("");
        //     require(success);
        // }
        // else {
        //     //Will not proceed any further and revert any changes if hapened
        //     revert("Not enough funds");
        // }

        // assert(address(this).balance == balanceBeforeTransfer - _cost);
        // customers[_to] = 0;
    }

    function claimRefund() payable public {
        uint256 value = customers[msg.sender];
        userRefund[msg.sender] = 0;
        customers[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: value}("");
        require(success);

    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function madeBurger() public isAtStage(Stages.makeBurger) shopOpened{
        updateStage(Stages.deliverBurger);
    }

    function pickupBurger() public isAtStage(Stages.deliverBurger) shopOpened{
            updateStage(Stages.readyToOrder);
    }

    function updateStage(Stages _stage) public {
        burgerShopStatge = _stage;
    }

    function getRandomNum(uint256 _seed) public view returns(uint256) {
        uint256 randNum = uint256(keccak256(abi.encodePacked(block.timestamp, _seed))) % 10 +1;
        return randNum;
    }
    

}