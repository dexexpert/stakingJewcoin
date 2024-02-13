pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


interface ShekelContract {
    function mint(address _to, uint256 _amount) external;
}
contract JewSale is Ownable {
    AggregatorV3Interface internal priceFeed;
    uint256 public ethPrice;
    // The aggregator of the ETH/USD pair on the Goerli testnet
    address priceAggregatorAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;


    mapping(address => bool) public acceptedTokens;
    mapping(address => uint256) public pricePerTokens;
    // 15 cents till 1 million saved
    // 20 cents till 2 million saved
    // 25 cents till 3 million saved
    // 30 cents till 4 million saved
    // 35 cents till 5 million saved
    // 40 cents till 6 million saved
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public ETH;
    address public marketingWallet;
    address public JewAddress;
    address public ShekelAddress;

    constructor(address _jewAddress, address _shekelAddress) {
        acceptedTokens[USDT] = true;
        acceptedTokens[USDC] = true;
        pricePerTokens[USDT] = (2 * 10 ** 18) / 10 ** 6;
        pricePerTokens[USDC] = (2 * 10 ** 18) / 10 ** 6;
        marketingWallet = 0xe3FDc39e56578A24f24096dc9D56ae349664E921;
        JewAddress = _jewAddress;
        ShekelAddress = _shekelAddress;
        priceFeed = AggregatorV3Interface(priceAggregatorAddress);
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
        JewAddress = _newJewcoin;
    }

    function changeShekelAddress(address _newShekel) external onlyOwner {
        ShekelAddress = _newShekel;
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
        
        return ethPrice * _amount / getJewcoinPrice();
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
        
        ShekelContract(ShekelAddress).mint(msg.sender, calcAmountToBeReceived(_tokenAddr, _tokenAmount));
    }

    function buyTokenByETH(
        uint256 _nativeAmount
    ) external payable {

        payable(marketingWallet).transfer(_nativeAmount);

        ShekelContract(ShekelAddress).mint(msg.sender, calcAmountToBeReceivedETH(_nativeAmount));
    }

}
