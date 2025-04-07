 // SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import{Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 5e18;
    uint256 constant STARTING_BALANCE = 1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);

}


    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnnerIsMsgSender() public  {
        //console.log(fundMe.i_owner());
        //console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
    vm.expectRevert();
    fundMe.fund(); 
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: 5e18}();

        uint256 amountFunded =  fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value : SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;

    }

      function testOnlyOwnwerCanWithdraw() public{
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }


    function testWithDrawWithASingleFunder() public funded {

        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
            );
    } 

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint256 numberOfFunders = 10;
        uint256 startingFunderIndex =2;
        for (uint256 i = startingFunderIndex; i < numberOfFunders; i++){
            //vm.prank new address
            //vm.deal new address
            address funder = vm.addr(i);
            hoax(funder, SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
            fundMe.getOwner().balance
            );

    }

}

// us -> calling th e fundMe test