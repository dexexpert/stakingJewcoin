// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


interface ShekelContract {
    function mint(address _to, uint256 _amount) external;
}

interface SkinContract {
    function mint(address _to, uint256 _amount) external;
}

contract JewNFT is ERC721, Ownable {
     AggregatorV3Interface internal priceFeed;
    uint256 public ethPrice;
    // The aggregator of the ETH/USD pair on the Goerli testnet
    address priceAggregatorAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    
    address public jewAddress;
    address public shekelAddress;
    address public foreskinAddress;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public ETH;
    address public marketingWallet;
    string strBaseURI;
    bool burnFinished = false;

    struct TierInfo {
        uint256 maxSupply;
        uint256 startValue;
        uint256 cnt;
    }

    struct StakeInfo {
        bool isStaked;
        uint256 amount;
        uint256 lockDays;
        uint256 _epoch;
    }

    mapping(uint256 => TierInfo) public tierInfo;
    mapping(address => StakeInfo) public stakeInfo;
    mapping(address => uint256) private skinHolder;
    mapping(address => bool) public acceptedTokens;
    mapping(address => uint256) public pricePerTokens;

    constructor(
        string memory strName,
        string memory strSymbol,
        address _jewAddress,
        address _shekelAddress,
        address _skinAddress
    ) ERC721(strName, strSymbol) {
        acceptedTokens[USDT] = true;
        acceptedTokens[USDC] = true;
        pricePerTokens[USDT] = (2 * 10 ** 18) / 10 ** 6;
        pricePerTokens[USDC] = (2 * 10 ** 18) / 10 ** 6;
        marketingWallet = 0xe3FDc39e56578A24f24096dc9D56ae349664E921;
        jewAddress = _jewAddress;
        shekelAddress = _shekelAddress;
        foreskinAddress = _skinAddress;
    }

    function updateEthPrice() public {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Chainlink returns price with 8 decimals, so multiply by 10^10 to get the price in USD with 18 decimals
        ethPrice = uint256(price);
    }

    function changePriceAggregatorAddress(address _newAddress) external onlyOwner {
        priceAggregatorAddress = _newAddress;
    }

    function changeMarketingWallet(address _newWallet) external onlyOwner {
        marketingWallet = _newWallet;
    }

    function changeJewAddress(address _newJewcoin) external onlyOwner {
        jewAddress = _newJewcoin;
    }

    function changeShekelAddress(address _newShekel) external onlyOwner {
        shekelAddress = _newShekel;
    }

    function setAcceptedTokens(
        address _addr,
        bool _accept,
        uint256 _price
    ) external onlyOwner {
        acceptedTokens[_addr] = _accept;
        pricePerTokens[_addr] = _price; // how much to be accepted - e.g. 0.5$ -> 2 * 10 ** 18 / 10 **6
    }

    function getJewcoinPrice() public view returns (uint256) {
        return ((1 / pricePerTokens[USDT]) * 10 ** 18) / 10 ** 6;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        strBaseURI = _newBaseURI;
    }

    function burnState(bool _burnState) external onlyOwner {
        burnFinished = _burnState;
    }

    function _baseURI() internal view override returns (string memory) {
        return strBaseURI;
    }
    
    function mintedSupply(uint256 _amount) public view returns (uint256) {
        TierInfo storage tierInfoData = tierInfo[_amount];
        return tierInfoData.cnt;
    }

    function WithdrawJew(uint256 _amount) external onlyOwner {
        ERC20(jewAddress).transfer(msg.sender, _amount);
    }

    function WithdrawShekel(uint256 _amount) external onlyOwner {
        ERC20(shekelAddress).transfer(msg.sender, _amount);
    }

    function setTierInfo(
        uint256 _tier,
        uint256 _maxSupply,
        uint256 _startvalue
    ) external onlyOwner {
        require(tierInfo[_tier].maxSupply == 0,"Amount used already in past!");
        tierInfo[_tier].maxSupply = _maxSupply;
        tierInfo[_tier].startValue = _startvalue;
    }
/////////////////// staking requirements part ////////////////////////////
    function stake(uint256 _amount, uint256 _lockDays) external {
        StakeInfo storage stakeInfoData = stakeInfo[msg.sender];
        require(
            stakeInfoData.lockDays == 0,
            "Staking amount is not precise, please check again"
        );
        require(
            stakeInfoData.amount == 0,
            "Already staked, please wait or unstake"
        );
        ERC20(jewAddress).transferFrom(msg.sender, address(this), _amount);
        stakeInfoData.isStaked = true;
        stakeInfoData.amount = _amount;
        stakeInfoData.lockDays = _lockDays;
        stakeInfoData._epoch = block.timestamp;
    }

    function unstake() external {
        require(stakeInfo[msg.sender].amount != 0, "No stake found");
        stakeInfo[msg.sender]._epoch = 0;
        ERC20(jewAddress).transfer(msg.sender, stakeInfo[msg.sender].amount);
        stakeInfo[msg.sender].isStaked = false;
        stakeInfo[msg.sender].amount = 0;
        stakeInfo[msg.sender].lockDays = 0;
    }

    function isClaimableShekel(address _addr) public view returns (bool) {
        StakeInfo memory stakeInfoData = stakeInfo[_addr];
        return
            stakeInfoData.amount != 0 &&
            stakeInfoData._epoch + stakeInfoData.lockDays * 1 days >
            block.timestamp;
    }

     function calcAmount(
        address to
    ) public view returns (uint256) {
        StakeInfo memory stakeInfoData = stakeInfo[to];
        if(stakeInfoData.lockDays > 0 && stakeInfoData.lockDays < 31)  {
            return stakeInfoData.amount * stakeInfoData.lockDays / 10;
        }else if (stakeInfoData.lockDays > 31 && stakeInfoData.lockDays < 61){
            return stakeInfoData.amount / 20;
        }else if (stakeInfoData.lockDays > 61 && stakeInfoData.lockDays < 92 ){
            return stakeInfoData.amount  / 30;
        }else if (stakeInfoData.lockDays > 92 && stakeInfoData.lockDays < 123 ){
            return stakeInfoData.amount / 40;
        }else if (stakeInfoData.lockDays > 123 && stakeInfoData.lockDays < 152){
            return stakeInfoData.amount / 50;
        }
    }
    function claim() external {
        StakeInfo storage stakeInfoData = stakeInfo[msg.sender];
        require(stakeInfoData.amount != 0, "No stake found");
        require(
            stakeInfoData._epoch + stakeInfoData.lockDays * 1 days >
                block.timestamp,
            "Wait for lock period"
        );
        ERC20(shekelAddress).transfer(msg.sender, calcAmount(msg.sender));
        if(stakeInfoData.amount > 1000){
            skinHolder[msg.sender] = stakeInfoData.amount;
        }
        stakeInfoData._epoch = 0;
        stakeInfoData.amount = 0;
        stakeInfoData.lockDays = 0;
    }
/////////////////////////////foreskin part/////////////////////////////
    function isClaimableSkin() public view returns (bool) {
        // SkinHolder memory skinHolderData = skinHolder[_addr];
        if(skinHolder[msg.sender] >= 1000 && burnFinished == true){
            return true;
        }else return false;
    }

    function claimSkin() external {
        // SkinHolder storage skinHolderData = skinHolder[msg.sender];
        require(burnFinished == true, "burn finished already ");
        require(skinHolder[msg.sender] > 1000, "Amount must be more than 1000");
        
        SkinContract(foreskinAddress).mint(msg.sender, skinHolder[msg.sender] / 1000);
    }  
//////////////////////////// NFT Mint part ////////////////////////////
    function buyNFT(uint256 _amount) external {
        TierInfo storage tierInfoData = tierInfo[_amount];
        require(
            tierInfoData.maxSupply != 0 && ERC20(shekelAddress).balanceOf(msg.sender) >= _amount,
            "amount for buy is invalid, please check again"
        );
         ERC20(shekelAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 _mintId = tierInfoData.startValue + tierInfoData.cnt;
        _safeMint(msg.sender, _mintId);
        tierInfoData.cnt++;
    }

//////////////////////////// Sale Jewcoin part //////////////////////////
    function calcAmountToBeReceived(
        address _tokenAddress,
        uint256 _amount
    ) public view returns (uint256) {
        if (
            acceptedTokens[_tokenAddress] == false ||
            pricePerTokens[_tokenAddress] == 0
        ) return 0;
        return _amount * pricePerTokens[_tokenAddress];
    }

    function calcAmountToBeReceivedETH(
        uint256 _amount
    ) public view returns (uint256) {
        
        return (ethPrice / 10 ** 8) * _amount / getJewcoinPrice();
    }

    function buyTokenByStable(
        address _tokenAddr,
        uint256 _tokenAmount
    ) external {
        require(acceptedTokens[_tokenAddr] == true, "Token not accepted");
        require(pricePerTokens[_tokenAddr] != 0, "Token not accepted");
        ERC20(_tokenAddr).transferFrom(
            msg.sender,
            marketingWallet,
            _tokenAmount
        );
        
        ShekelContract(shekelAddress).mint(msg.sender, calcAmountToBeReceived(_tokenAddr, _tokenAmount));
    }

    function buyTokenByETH(
        uint256 _nativeAmount
    ) external payable {

        payable(marketingWallet).transfer(_nativeAmount);

        ShekelContract(shekelAddress).mint(msg.sender, calcAmountToBeReceivedETH(_nativeAmount));
    }
}
