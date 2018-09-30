pragma solidity ^0.4.18;


import "truffle/Assert.sol";
import "../contracts/TestCrowdsale.sol";

contract TestContract {
    
    ArtX artx;

    function beforeEach() public {
        artx = new ArtX();
    }
    
    /************************************ Test Portion 1 ***********************************************/

    /**function testTime() public {
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
        Assert.equal(allocation, 1267, "should equal input");
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

    function testiWantXKeys() public{
        uint256 iWantXKeysNew = artx.iWantXKeysNew(10000000000000000000);
        Assert.equal(750007031250000, iWantXKeysNew, "should equal input");
    }

    function testcoreNew() public{
        uint available_limit = artx.coreNew(0x24c3db3D9f24C30f0B17faa9b3586ad6C1FBA0aE, 100000000000, 0xCf11cdB8c8c85403bcf2375688754f85bF618Ff3);
        Assert.equal(0, available_limit, "should equal input");
    }**/ 

    /************************************ Test Portion 2 ***********************************************/

    /**function testdistinternal() public{
        uint256 pot = artx.distributeInternalNew(0x24c3db3D9f24C30f0B17faa9b3586ad6C1FBA0aE, 1000000000000000000, 20);
        Assert.equal(600000000000100000000000000000000000, pot, "should equal input");
    }

    function testupdatemaskxaddr() public{
        uint256 gen = artx.updateMasksXAddr(0x24c3db3D9f24C30f0B17faa9b3586ad6C1FBA0aE, 10000000, 20);
        Assert.equal(0, gen, "should equal input");
    }    

    function testupdateGenVaultXAddr() public{
        uint test = artx.updateGenVaultXAddr(0x24c3db3D9f24C30f0B17faa9b3586ad6C1FBA0aE);
        Assert.equal(3000000, test, "should equal input");
    }

    function testwithdrawEarningsXAddr() public{
        uint test = artx.withdrawEarningsXAddr(0x24c3db3D9f24C30f0B17faa9b3586ad6C1FBA0aE);
        Assert.equal(3000000, test, "should equal input");
    }

    function testendRound() public{
        uint test = artx.endRound();
        //artx.ArtXdatasets.EventReturns memory _event_ = artx.endRound();
        Assert.equal(100000000000000000000000, test, "should equal input");
    }

    function testupdaterefermap() public{
        address testaddr = artx.updaterefermap("abcdefg", 0xCf11cdB8c8c85403bcf2375688754f85bF618Ff3);
        Assert.equal(0xCf11cdB8c8c85403bcf2375688754f85bF618Ff3, testaddr , "should equal input");
    }

    function testregisterIDFromDapp() public{
        var(test, addrtest) = artx.registerIDFromDapp("Clement", "abcdefg", "zywx");
        Assert.equal(true, test, "should equal input");
        Assert.equal(0xCf11cdB8c8c85403bcf2375688754f85bF618Ff3, addrtest, "should equal input");
        //address addrtest = artx.registerIDFromDapp("Clement", "abcdefg", "zywx");
        //Assert.equal(0x24c3db3D9f24C30f0B17faa9b3586ad6C1FBA0aE, addrtest, "should equal input");
    }**/

    /************************************ Test Portion 3 ***********************************************/

    function testcalcKeysReceivedNew() public{
        uint256 keys = artx.calcKeysReceivedNew(1000000000000000000);
        Assert.equal(13153133573264508115713, keys, "should equal input");
    }

    function testselectAddress() public{
        address[] memory addr = artx.selectAddress();
        //Assert.equal(0, addr, "should equal input");
    }

    function testgetWinner() public{
        address[] memory winaddr;
        winaddr = artx.getWinner();
        //Assert.equal(0, winaddr, "should equal input");
    }


}