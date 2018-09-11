pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "../contracts/TestCrowdsale.sol";

contract TestContract {
    
    Decentralism DC;

    //function beforeEach() public {
    //    DC = new Decentralism();
    //}

    //event test_value(bool value1);
    
    //function checksetrefcode() public {
    //    DC.setReferCode(0x24c3db3D9f24C30f0B17faa9b3586ad6C1FBA0aE, 'xy123ox');
    //    bool decision = DC.hashCompareWithLengthCheck(DC.getReferCode(0x24c3db3D9f24C30f0B17faa9b3586ad6C1FBA0aE), 'xy123ox');
        //test_value(decision);
        //Assert.equal(true, decision, "should equal input");
    //}

    //Test calculateEndEth
    function testsetaddress() public{
        uint256 test = DC.setaddress();
        Assert.equal(10, test, "should equal input");
    }

}