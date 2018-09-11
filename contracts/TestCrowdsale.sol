pragma experimental ABIEncoderV2;
pragma solidity ^0.4.24;

//==============================================================================
//     _    _  _ _|_ _  .
//    (/_\/(/_| | | _\  .
//==============================================================================
contract Devents {
    // fired whenever a player registers a name
    event onNewName
    (
        address indexed playerAddress,
        string playerName,
        bool isNewPlayer,
        address affiliateAddress,
        uint256 amountPaid,
        uint256 timeStamp
    );

    // fired at end of buy or reload
    event onEndTx
    (
        string playerName,
        address playerAddress,
        uint256 ethIn,
        uint256 keysBought,
        uint256 potAmount
    );

    // fired whenever theres a withdraw
    event onWithdraw
    (
        address playerAddress,
        string playerName,
        uint256 ethOut,
        uint256 timeStamp
    );

    // fired whenever a withdraw forces end round to be ran
    event onWithdrawAndDistribute
    (
        address playerAddress,
        string playerName,
        uint256 ethOut
    );

    // (fomo3d long only) fired whenever a player tries a buy after round timer
    // hit zero, and causes end round to be ran.
    event onBuyAndDistribute
    (
        address playerAddress,
        bytes32 playerName,
        uint256 ethIn,
        uint256 compressedData,
        uint256 compressedIDs,
        address winnerAddr,
        bytes32 winnerName,
        uint256 amountWon,
        uint256 newPot,
        uint256 P3DAmount,
        uint256 genAmount
    );

    // (fomo3d long only) fired whenever a player tries a reload after round timer
    // hit zero, and causes end round to be ran.
    event onReLoadEnd
    (
        address playerAddress,
        string playerName,
        uint256 amountWon,
        uint256 pot
    );

    // fired whenever an affiliate is paid
    event onAffiliatePayout
    (
        address affiliateAddress,
        string affiliateName,
        uint256 amount,
        uint256 timeStamp
    );

}

//*****************************************************************************//
//**************************** ArtX Contract **********************************//
//*****************************************************************************//

contract ArtX{

    //Use SafeMath For All the calculations
    using SafeMath for *;
    using NameFilter for string;
    using ArtxsharesCalcLong for uint256;

    struct WinnerGroup {
        uint256 price;
        string id;
        address[] addr;
    }

    // for Decentralism
    uint256 constant delay_ = 120 seconds;
    uint256 public startTime_;
    uint256 public initEth_ = 1000000;
    bool private start_ = false;
    bool private end_ = false;
    uint256 mask_ = 1000000;
    uint256 accDelay_ = 0;
    uint256 keys_ = 0;
    uint256 pot_ = 0;
    uint256 eth_ = 0;
    uint256 com_ = 0;
    address private win_;
    uint256 private totalBalance_;

    address[] public addressIndexes;

    mapping (address => ArtXdatasets.Player) public plyrs_;   // (pID => data) player data
    mapping (string => address) referMap_;
    mapping (address => bool) public winner_;

    WinnerGroup winnerGroup1_;
    WinnerGroup winnerGroup2_;
    WinnerGroup winnerGroup3_;
    address[] _result;


//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
//=================_|===========================================================
    string constant public name = "ArtX Official";
    string constant public symbol = "F3D";
    uint256 constant private rndInit_ = 1 hours;                // round timer starts at this
    uint256 constant private rndInc_ = 30 seconds;              // every full key purchased adds this much to the timer
    uint256 constant private rndMax_ = 24 hours;                // max length a round timer can be

//==============================================================================
//     _| _ _|_ _    _ _ _|_    _   .
//    (_|(_| | (_|  _\(/_ | |_||_)  .  (data used to store game info that changes)
//=============================|================================================
    uint256 public airDropPot_;             // person who gets the airdrop wins part of this pot
    uint256 public airDropTracker_ = 0;     // incremented each time a "qualified" tx occurs.  used to determine winning air drop
    uint256 public rID_;    // round id number / total rounds that have happened

//****************
// PLAYER DATA 
//****************
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (bytes32 => uint256) public pIDxName_;          // (name => pID) returns player id by name
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_; // (pID => name => bool) list of names a player owns.  (used so you can change your display name amongst any name you own)

//****************
// ROUND DATA 
//****************
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;      // (rID => tID => data) eth in per team, by round id and team id

//==============================================================================
//    (~ _  _    _._|_    .
//    _)(/_(_|_|| | | \/  .
//====================/=========================================================
    /** upon contract deploy, it will be deactivated.  this is a one time
     * use function that will activate the contract.  we do this so devs 
     * have time to set things up on the web end s**/
    
    bool public activated_ = false;
    
    //PlayerRounds setting
    ArtXdatasets.PlayerRounds PR;
    ArtXdatasets.Player plyr_;
    ArtXdatasets.Round round_;
    ArtXdatasets.Fee fees_;


    //Get Time Left
    function getTimeLeft()
    public
    view
    returns(uint256)
    {   
        // grab time
        uint256 _now = now;
        round_.strt = 0;
        round_.end = 100000000000;
        round_.plyr = 1;

        if (_now < round_.end)
            if (_now > round_.strt)
                return((round_.end).sub(_now));
            else
                return((round_.strt).sub(_now));
        else
            return(0);
    }

    //activate function
    function activate()
    public
    returns(bool)
    {

        // can only be ran once
        require(activated_ == false, "ArtX already activated");
        
        // activate the contract 
        activated_ = true;

        return true;
    }

    //Set PlayerRound Shares
    function setshares(uint256 _shares)
    public
    returns(uint256)
    {   
        PR.shares = _shares;
        return(PR.shares);
    }

    //Calculate Allocation
    function calculateAllocation()
    public
    returns(uint256)
    {

        //Setting Round
        uint256 Exp = 3;
        uint256 strt = 1000;
        uint256 token_const = 3;
        uint256 InitialAllocation = 60;

        round_.Exp = Exp;
        round_.strt = strt;
        round_.token_const = token_const;
        round_.InitialAllocation = InitialAllocation;

        // grab time
        uint256 _now = now;

        //Calcuate time differences
        uint256 timediff = _now.sub(round_.strt);

        //Decay Rate
        round_.token_decay = (timediff ** round_.Exp) / round_.token_const;

        //Calculate Cap_
        round_.allocation = (((1+timediff)*1000000000000000000000) / (1+timediff+round_.token_decay));

        return(round_.allocation);
    }

    /**
     * @dev calculate Cap Decay
     * @return Cap
     */

    function calculateCapDecay()
    public
    returns(uint256)
    {

        //Setting Round
        uint256 Exp_DR = 3;
        uint256 strt = 1;
        uint256 Cap_Const = 3;
        uint256 InitialCap = 100000;

        round_.Exp_DR = Exp_DR;
        round_.strt = strt;
        round_.Cap_Const = Cap_Const;
        round_.InitialCap = InitialCap;

        // grab time
        uint256 _now = now;

        //Calcuate time differences
        uint256 timediff = _now - round_.strt;

        //Decay Rate
        round_.DecayRate = (timediff ** round_.Exp_DR) / round_.Cap_Const;

        //Calculate Cap
        uint256 den = 1;
        uint256 num = 10;

        round_.Cap = (round_.InitialCap.mul(1+timediff)/(1+timediff.add(round_.DecayRate))).add((den)/(num));

        return(round_.DecayRate);
    }

    /*
     * @dev checks to make sure user picked a valid team.  if not sets team 
     * to default (sneks)
     */

    function verifyappraisal(uint256 _appraisal)
        public
        pure
        returns (uint256)
    {
        if (_appraisal < 0 || _appraisal > 3)
            return(2);
        else
            return(_appraisal);
    }

    /**
     * @dev calculates unmasked earnings (just calculates, does not update mask)
     * @return earnings in wei format
     */

    function calcUnMaskedEarnings()
        public
        view
        returns(uint)
    {   
        round_.mask = 100;
        PR.shares = 2;
        PR.mask = 10;

        return(round_.mask.mul(PR.shares).mul(5).mul(1000000000000000000)/(2000000000000000000));
    }

    /*
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateDividend(uint256 _pID)
        private 
    {
        uint256 _earnings = calcUnMaskedEarnings();

        if (_earnings > 0)
        {
            // put in gen vault
            plyr_.gen = _earnings + (plyr_.gen);
            // zero out their earnings by updating mask
            PR.mask = _earnings + (PR.mask);
        }
    }

    function getPlayerSharesHelper()
        public
        view
        returns(uint256)
    {

        round_.mask = 100;
        round_.pot = 10000;
        round_.shares = 1000;
        uint256 TotalPot_ = 1000000;
        PR.shares = 2;
        PR.mask = 10;

        return(  ((((round_.mask).add(((((round_.pot).mul(TotalPot_)) / 100).mul(1000000000000000000)) / (round_.shares))).mul(PR.shares)) / 1000000000000000000));
    }


//==============================================================================
//     _  _ _|__|_ _  _ _  .
//    (_|(/_ |  | (/_| _\  . (for UI & viewing things on etherscan)
//=====_|=======================================================================
    
    /**
     * @dev return the price buyer will pay for next 1 individual key.
     * -functionhash- 0x018a25e8
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
        
        round_.strt = 0;
        round_.end = 100000000000;
        round_.plyr = 1;

        // grab time
        uint256 _now = now;
        
        // are we in a round?
        if (_now > round_.strt && (_now <= round_.end || (_now > round_.end && round_.plyr == 0)))
            return ((round_.shares.add(1000000000000000000).ethRec(1000000000000000000)));
        else // rounds over.  need price for new round
            return (75000000000000); // init
    }

    //==============================================================================
    //     _ _ | _   | _ _|_ _  _ _  .
    //    (_(_||(_|_||(_| | (_)| _\  .
    //==============================================================================

    //Set Address
    function setaddress()
    public
    returns(uint256){
        plyr_.keys = 10;
        return(plyr_.keys);
    }

    /**
     * @dev calculates unmasked earnings (just calculates, does not update mask)
     * @return earnings in wei format
     */
    function calcUnMaskedEarningsXAddr(address _addr)
    public
    view
    returns(uint256)
    {   
        plyrs_[_addr].keys = 3000000000000000000;
        return((((mask_).mul(plyrs_[_addr].keys)) / (1000000000000000000)).sub(plyrs_[_addr].mask));
    }

    /**
     * @dev returns the amount of keys you would get given an amount of eth.
     * -functionhash- 0xce89c80c
     * @param _eth amount of eth sent in
     * @return keys received
     */
    function calcKeysReceivedNew(uint256 _eth)
    public
    view
    returns(uint256)
    {
        // grab time
        uint256 _now = now;

        uint256 _ethDec = calculateEndEth(_now);
        uint256 _ethInc = totalBalance_;

        // are we in a round?
        if (end_ == false && _ethDec > _ethInc)
            return ( (totalBalance_).keysRec(_eth) );
        else // rounds over.  need keys for new round
            return ( (_eth).keys() );
    }

    //CalculateEndEthereum
    function calculateEndEth(uint256 time) public view returns (uint256) {

        startTime_ = 0;

        uint256 T = time - startTime_;
        uint256 D;
        uint256 _now = now;
        uint _localAccDelay = accDelay_;
        if(_localAccDelay == 0) {
            D = 0; // now is larger than time of purchasing
        }else{
            D = (_localAccDelay.sub(_now.sub(time)))/2;
        }
        return (((initEth_).mul(1000000000000000000)).mul((T).add(1)))/(((T).add(D)).add(1));
    }

    // Get at lease three winners
    // So there might be more than three winners
    function getWinner() internal returns(address[]) {
        uint initiCount_ = 0;
        for(uint256 i = 0; i < addressIndexes.length; i++) {
            uint256 priceDiff_;
            address playerAddr_ = addressIndexes[i];
            Ddatasets.Player memory player_ = plyrs_[playerAddr_];

            for(uint j=0;j<player_.est.length;j++){

                if(totalBalance_ > player_.est[j]){
                    priceDiff_ = totalBalance_ - player_.est[j];
                }else{
                    priceDiff_ = player_.est[j] - totalBalance_;
                }

                if (initiCount_==0) {
                    winnerGroup3_.addr.push(player_.addr);
                    winnerGroup3_.price = priceDiff_;
                    initiCount_++;
                }else if (initiCount_==1) {
                    initiCount_++;
                    if(priceDiff_==winnerGroup3_.price){
                        winnerGroup3_.addr.push(player_.addr);
                    }else if(priceDiff_>winnerGroup3_.price){
                        //                        Ddatasets.WinnerGroup tempGroup_;
                        //                        tempGroup_.addr.push(player_.addr);
                        //                        tempGroup_.price = priceDiff_;
                        // not sure about object copy
                        winnerGroup2_.addr = winnerGroup3_.addr;
                        winnerGroup2_.price = winnerGroup3_.price;
                        winnerGroup3_.addr.length = 0;
                        winnerGroup3_.addr.push(player_.addr);
                        winnerGroup3_.price = priceDiff_;
                    }else{
                        winnerGroup2_.addr.push(player_.addr);
                        winnerGroup2_.price = priceDiff_;
                    }
                } else if (initiCount_==2) {
                    initiCount_++;
                    if(priceDiff_==winnerGroup3_.price){
                        winnerGroup3_.addr.push(player_.addr);
                    }else if(priceDiff_>winnerGroup3_.price){
                        //                        Ddatasets.WinnerGroup tempGroup_;
                        //                        tempGroup_.addr.push(player_.addr);
                        //                        tempGroup_.price = priceDiff_;
                        winnerGroup2_.addr = winnerGroup3_.addr;
                        winnerGroup2_.price = winnerGroup3_.price;
                        winnerGroup3_.addr.length = 0;
                        winnerGroup3_.addr.push(player_.addr);
                        winnerGroup3_.price = priceDiff_;
                    }else if(priceDiff_<winnerGroup3_.price && priceDiff_>winnerGroup2_.price){
                        //                        Ddatasets.WinnerGroup tempGroup_;
                        //                        tempGroup_.addr.push(player_.addr);
                        //                        tempGroup_.price = priceDiff_;
                        winnerGroup1_.addr = winnerGroup2_.addr;
                        winnerGroup1_.price = winnerGroup2_.price;
                        winnerGroup2_.addr.length = 0;
                        winnerGroup2_.addr.push(player_.addr);
                        winnerGroup2_.price = priceDiff_;
                    }else if(priceDiff_==winnerGroup2_.price){
                        winnerGroup2_.addr.push(player_.addr);
                    }else{
                        winnerGroup1_.addr.push(player_.addr);
                        winnerGroup1_.price = priceDiff_;
                    }
                } else {
                    if(priceDiff_==winnerGroup3_.price){
                        winnerGroup3_.addr.push(player_.addr);
                    }else if(priceDiff_<winnerGroup3_.price && priceDiff_>winnerGroup2_.price){
                        winnerGroup3_.addr.length = 0;
                        winnerGroup3_.addr.push(player_.addr);
                        winnerGroup3_.price = priceDiff_;
                    }else if(priceDiff_==winnerGroup2_.price){
                        winnerGroup2_.addr.push(player_.addr);
                    }else if(priceDiff_<winnerGroup2_.price && priceDiff_>winnerGroup1_.price){
                        winnerGroup3_.addr = winnerGroup2_.addr;
                        winnerGroup3_.price = winnerGroup2_.price;
                        winnerGroup2_.addr.length = 0;
                        winnerGroup2_.addr.push(player_.addr);
                        winnerGroup2_.price = priceDiff_;
                    }else if(priceDiff_==winnerGroup1_.price){
                        winnerGroup1_.addr.push(player_.addr);
                    }else{
                        winnerGroup3_.addr = winnerGroup2_.addr;
                        winnerGroup3_.price = winnerGroup2_.price;
                        winnerGroup2_.addr = winnerGroup1_.addr;
                        winnerGroup2_.price = winnerGroup1_.price;
                        winnerGroup1_.addr.length = 0;
                        winnerGroup1_.addr.push(player_.addr);
                        winnerGroup1_.price = priceDiff_;
                    }
                }
            }
        }

        return (selectAddress());

    }


    /*************************************************************************************************************************/
    /**************************************** Core Function Testing **********************************************************/
    /*************************************************************************************************************************/

    /**
    * @Test and Evaluation of core business
    */

    //function core(uint256 _pID, uint256 _eth, uint256 _affID, uint256 _appraisal, ArtXdatasets.EventReturns memory _eventData_)
    //    public
    //    {
    //    // if player is new to round
    //    if (PR.shares == 0)
    //        _eventData_ = managePlayer(_pID, _eventData_);
        
    //    // early round eth limiter 
    //    if (round_.eth < 100000000000000000000 && PR.eth.add(_eth) > 1000000000000000000)
    //    {
    //        uint256 _availableLimit = (1000000000000000000).sub(PR.eth);
    //        uint256 _refund = _eth.sub(_availableLimit);
    //        plyr_.gen = plyr_.gen.add(_refund);
    //        _eth = _availableLimit;
    //    }
        
        // if eth left is greater than min eth allowed (sorry no pocket lint)
    //    if (_eth > 1000000000) 
    //    {
            
            // mint the new artxshares
    //        uint256 _artxshares = (round_.eth).artxsharesRec(_eth);
            
            // if they bought at least 1 whole key
    //        if (_artxshares >= 1000000000000000000)
    //        {
    //        updateTimer(_artxshares);
           
            // set the new leader bool to true
    //        _eventData_.compressedData = _eventData_.compressedData + 100;

    //        }
    //    }
              
            // update player 
    //        plyr_.artxshares = _artxshares.add(plyr_.artxshares);
    //        plyr_.eth = _eth.add(plyr_.eth);
            
            // update round
    //        round_.artxshares = _artxshares.add(round_.artxshares);
    //        round_.eth = _eth.add(round_.eth);
    
            // distribute eth
    //        _eventData_ = distributeshares(_pID, _eth, _artxshares, _eventData_);
            
            // call end tx function to fire end tx event.
    //        endTx(_pID, _eth, _artxshares, _eventData_);
    //}


    /**
     * @dev updates round timer based on number of whole artxshares bought.
     */

    function updateTimer(uint256 _artxshares)
        public
        returns(uint256)
    {   

        round_.end = 0;

        // grab time
        uint256 _now = now;
        
        // calculate time based on number of artxshares bought
        uint256 _newTime;

        if (_now > round_.end && round_.plyr == 0)
            _newTime = (((_artxshares) / (1000000000000000000)).mul(rndInc_)).add(_now);
        else
            _newTime = (((_artxshares) / (1000000000000000000)).mul(rndInc_)).add(round_.end);
        
        // compare to max and set new end time
        if (_newTime < (rndMax_).add(_now))
            round_.end = _newTime;
        else
            round_.end = rndMax_.add(_now);

        return(round_.end);
    }

    /**
     * @dev decides if round end needs to be run & new round started.  and if 
     * player unmasked earnings from previously played rounds need to be moved.
     */

    //function managePlayer(uint256 _pID, ArtXdatasets.EventReturns memory _eventData_)
    //    public
    //    returns (ArtXdatasets.EventReturns)
    //{
        // if player has played a previous round, move their unmasked earnings
        // from that round to gen vault.
    //    if (plyr_.lrnd != 0)
    //        updateGenVault(_pID, plyr_.lrnd);
            
        // update player's last round played
    //    plyr_.lrnd = rID_;
            
        // set the joined round bool to true
    //    _eventData_.compressedData = _eventData_.compressedData + 10;
        
    //    return(_eventData_);
    //}

    /**
     * @dev moves any unmasked earnings to gen vault.  updates earnings mask
     */
    function updateGenVault(uint256 _pID, uint256 _rIDlast)
        public 
    {   
        uint256 _earnings = calcUnMaskedEarnings();

        if (_earnings > 0)
        {
            // put in gen vault
            plyr_.gen = _earnings.add(plyr_.gen);
            // zero out their earnings by updating mask
            PR.mask = _earnings.add(PR.mask);
        }
    }

    /**
     * @dev distributes eth based on fees to gen and pot
     */
    function distributeshares(uint256 _pID, uint256 _eth, uint256 _artxshares) //, ArtXdatasets.EventReturns memory _eventData_)
        private
        returns(ArtXdatasets.EventReturns)
    {
        // calculate gen share
        uint256 _gen = (_eth.mul(fees_.gen)) / 100;
        
        // toss 50% into pot 
        uint256 _pot = (_eth / 2);
        uint256 TotalPot_ = TotalPot_.add(_pot);
        
        // update eth balance adding 
        _eth = _eth.add(_pot);
        
        // calculate pot 
        _pot = _eth.sub(_gen);
        
        // distribute gen share (thats what updateMasks() does) and adjust
        // balances for dust.
        uint256 _dust = updateMasks(_pID, _gen, _artxshares);
        if (_dust > 0)
            _gen = _gen.sub(_dust);
        
        // add eth to pot
        round_.pot = _pot.add(_dust).add(round_.pot);
        
        // set up event data
        //_eventData_.genAmount = _gen.add(_eventData_.genAmount);
        //_eventData_.potAmount = _pot;
        
        //return(_eventData_);
    }

    /**
     * @dev prepares compression data and fires event for buy or reload tx's
     */
    //function endTx(uint256 _pID, uint256 _eth, uint256 _artxshares, ArtXdatasets.EventReturns memory _eventData_)
    //    private
    //{
        //_eventData_.compressedData = _eventData_.compressedData + (now * 1000000000000000000) + (1 * 100000000000000000000000000000);
        //_eventData_.compressedIDs = _eventData_.compressedIDs + _pID + (1 * 10000000000000000000000000000000000000000000000000000);
        
        //emit F3Devents.onEndTx
        //(
        //    _eventData_.compressedData,
        //    _eventData_.compressedIDs,
        //    plyr_[_pID].name,
        //    msg.sender,
        //    _eth,
        //    _artxshares,
        //    _eventData_.winnerAddr,
        //    _eventData_.winnerName,
        //    _eventData_.amountWon,
        //    _eventData_.newPot,
        //    _eventData_.P3DAmount,
        //    _eventData_.genAmount,
        //    _eventData_.potAmount,
        //    airDropPot_
        //);
    //}


    /**
     * @dev updates masks for round and player when artxshares are bought
     * @return dust left over 
     */
    function updateMasks(uint256 _pID, uint256 _gen, uint256 _artxshares)
        public
        returns(uint256)
    {
        /* MASKING NOTES
            earnings masks are a tricky thing for people to wrap their minds around.
            the basic thing to understand here.  is were going to have a global
            tracker based on profit per share for each round, that increases in
            relevant proportion to the increase in share supply.
            
            the player will have an additional mask that basically says "based
            on the rounds mask, my shares, and how much i've already withdrawn,
            how much is still owed to me?"
        */
        
        round_.mask = 100;
        _artxshares = 10;

        // calc profit per key & round mask based on this buy:  (dust goes to pot)
        uint256 _ppt = (_gen.mul(1000000000000000000)) / (_artxshares);
        round_.mask = _ppt.add(round_.mask);
            
        // calculate player earning from their own buy (only based on the artxshares
        // they just bought).  & update player earnings mask
        uint256 _pearn = (_ppt.mul(_artxshares)) / (1000000000000000000);
        PR.mask = (((round_.mask.mul(_artxshares)) / (1000000000000000000)).sub(_pearn)).add(PR.mask);
        
        // calculate & return dust
        return((_ppt.mul(_artxshares)) / (1000000000000000000));
    }

}


//==============================================================================
//  |  _      _ _ | _  .
//  |<(/_\/  (_(_||(_  .
//=======/======================================================================

library ArtxsharesCalcLong {
    using SafeMath for *;
    /**
     * @dev calculates number of artxshares received given X eth 
     * @param _curEth current amount of eth in contract 
     * @param _newEth eth being spent
     * @return amount of ticket purchased
     */
    function artxsharesRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(artxshares((_curEth).add(_newEth)).sub(artxshares(_curEth)));
    }
    
    /**
     * @dev calculates amount of eth received if you sold X artxshares 
     * @param _curartxshares current amount of artxshares that exist 
     * @param _sellartxshares amount of artxshares you wish to sell
     * @return amount of eth received
     */
    function ethRec(uint256 _curartxshares, uint256 _sellartxshares)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curartxshares)).sub(eth(_curartxshares.sub(_sellartxshares))));
    }

    /**
     * @dev calculates how many artxshares would exist with given an amount of eth
     * @param _eth eth "in contract"
     * @return number of artxshares that would exist
     */
    function artxshares(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sq()).sub(74999921875000000000000000000000)) / (156250000);
    }
    
    /**
     * @dev calculates how much eth would be in contract given a number of artxshares
     * @param _artxshares number of artxshares "in contract" 
     * @return eth that would exists
     */
    function eth(uint256 _artxshares) 
        internal
        pure
        returns(uint256)  
    {
        return ((78125000).mul(_artxshares.sq()).add(((149999843750000).mul(_artxshares.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}


//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================

library ArtXdatasets {
    
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
        bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot
    }

    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 aff;    // affiliate vault
        uint256 lrnd;   // last round played
        uint256 laff;   // last affiliate id used
        uint256 mask;
        uint256 keys;
        uint256[] est;
        string referCode; // player's refer code that sent to other players
        uint256 artxshares; // Player's artxshares
        uint256 eth; //Player's Total Ethereum
    }

    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 shares; // shares
        uint256 mask;   // player mask 
        uint256 ico;    // ICO phase investment
    }

    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 team;   // tID of team in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 shares; // shares
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
        uint256 ico;    // total eth sent in during ICO phase
        uint256 icoGen; // total eth for gen during ICO phase
        uint256 icoAvg; // average key price for ICO phase

        uint256 artxshares; //Round's artxshares

        //Allocation Elements
        uint256 Exp; //Exponential Decay
        uint256 token_const; //Token Constant
        uint256 InitialAllocation; //Initial Allocation
        uint256 allocation; //Allocation
        uint256 token_decay; //Token Decay

        //Decay Rates
        uint256 Exp_DR; //Exponential Decay
        uint256 DecayRate; //Decay Rate
        uint256 InitialCap; //Initial Cap
        uint256 Cap_Const; //Cap Constant
        uint256 Cap; //Cap
    }

    struct Fee {
        uint256 gen;    // % of buy in thats paid to key holders of current round
    }
}

library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
    internal
    pure
    returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                // require character is a space
                    _temp[i] == 0x20 ||
                // OR lowercase a-z
                (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                // or 0-9
                (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
 
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}