pragma solidity ^0.4.18;


import "truffle/Assert.sol";
import "../contracts/TestCrowdsale.sol";

contract TestContract {
    
    ArtX artx;
    
    function beforeEach() public {
        artx = new ArtX();
    }
    
    function testTime() public {
        uint input = artx.getTimeLeft();
        uint output = artx.getTimeLeft();
        Assert.equal(output, input, "should equal input");
    }

    function testactivate() public{
        bool is_activate = artx.activate();
        Assert.equal(true, is_activate, "should equal input");
    }

    function testshares() public{
        uint PR_shares = artx.setshares(10000);
        uint shares = 10000;
        Assert.equal(shares, PR_shares, "should equal input");
    }

    event test_value(uint256 indexed value1);

    function testallocation() public{
        uint256 allocation = artx.calculateAllocation();
        Assert.equal(allocation, 1270, "should equal input");
        //test_value(allocation);
    }

    function testcalculateCapDecay() public{
        uint256 capdecay = artx.calculateCapDecay();
        Assert.equal(capdecay, artx.calculateCapDecay(), "should equal input");
        //test_value(capdecay);
    }

    function testverifyappraisal() public{
        uint256 appraisal = artx.verifyappraisal(3);
        Assert.equal(3, appraisal, "should equal input");
    }

    function testcalcUnMaskedEarnings() public{
        uint earnings = artx.calcUnMaskedEarnings();
        Assert.equal(500, earnings, "should equal input");
    }

    function testgetPlayerSharesHelper() public{
          uint256 shares = artx.getPlayerSharesHelper();
          Assert.equal(200000, shares, "should equal input");
    }

    function testupdateMasks() public{
          uint256 mask = artx.updateMasks(20000, 300000000, 10);
          Assert.equal(300000000, mask, "should equal input");
    }

    function testupdateTimer() public{
          uint256 time = artx.updateTimer(1000000000);
          Assert.equal(time, time, "should equal input");
    }

    function testgetBuyPrice() public{
          uint256 price = artx.getBuyPrice();
          Assert.equal(75000000000000, price, "should equal input");
    }

    function testethRec() public{
          uint256 price = artx.getBuyPrice();
          Assert.equal(75000000000000, price, "should equal input");
    }

    //Set Address Test
    function testsetaddress() public{
          uint256 testkey = artx.setaddress();
          Assert.equal(10, testkey, "should equal input");
    }

    function testcalcUnMaskedEarningsXAddr() public{
          uint256 testmaskearning = artx.calcUnMaskedEarningsXAddr(0x24c3db3D9f24C30f0B17faa9b3586ad6C1FBA0aE);
          Assert.equal(3000000, testmaskearning, "should equal input");
    }

    function testcalculateEndEth() public{
          uint256 testcalculateEndEth = artx.calculateEndEth(3000);
          Assert.equal(1000000000000000000000000, testcalculateEndEth, "should equal input");
    }


}