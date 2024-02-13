// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ShekelContract {
    function mint(address _to, uint256 _amount) external;
}

interface SkinContract {
    function mint(address _to, uint256 _amount) external;
}

contract JewNFT is ERC721, Ownable {
    address public jewAddress;
    address public shekelAddress;
    address public foreskinAddress;
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
    // mapping(address => SkinHolder) public skinHolder;
    mapping(address => uint256) private skinHolder;

    constructor(
        string memory strName,
        string memory strSymbol,
        address _jewAddress,
        address _shekelAddress,
        address _skinAddress
    ) ERC721(strName, strSymbol) {
        jewAddress = _jewAddress;
        shekelAddress = _shekelAddress;
        foreskinAddress = _skinAddress;
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
        if(stakeInfoData.lockDays > 30) {
            return stakeInfoData.amount * stakeInfoData.lockDays / 10;
        }else if (stakeInfoData.lockDays > 60 ){
            return stakeInfoData.amount * stakeInfoData.lockDays / 20;
        }else if (stakeInfoData.lockDays > 90 ){
            return stakeInfoData.amount * stakeInfoData.lockDays / 30;
        }else if (stakeInfoData.lockDays > 120 ){
            return stakeInfoData.amount * stakeInfoData.lockDays / 40;
        }else if (stakeInfoData.lockDays > 150){
            return stakeInfoData.amount * stakeInfoData.lockDays / 50;
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
}
