var TestCrowdsale = artifacts.require("./TestCrowdsale.sol");
var TestToken = artifacts.require("./TestToken.sol");

module.exports = function(deployer) {
  	const startTime = Math.round((new Date(Date.now()).getTime())/1000);
  	const endTime = startTime + (86400 * 2); // 30 days;

  	deployer.deploy(TestToken).then(function() {
  		return deployer.deploy(TestCrowdsale,	
	  		startTime, 
		    endTime,
		    5, 
		    "0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE", 
		    500000000000000000000 , // 500 ETH
		    TestToken.address,
		    2000000000000000000 // 2 ETH
		);
	});
};

