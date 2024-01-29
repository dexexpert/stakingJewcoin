// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStaking is ERC721, Ownable {
    address public jewAddress;
    string strBaseURI;

    struct TierInfo {
        uint256 lockDays;
        uint256 maxSupply;
        uint256 startValue;
        uint256 cnt;
        uint256 queuedCnt;
    }

    struct DepositInfo {
        uint256 tier;
        uint256 _epoch;
    }

    mapping(uint256 => TierInfo) public tierInfo;
    mapping(address => DepositInfo) public userDeposit;

    constructor(
        string memory strName,
        string memory strSymbol,
        address _jewAddress
    ) ERC721(strName, strSymbol) {
        jewAddress = _jewAddress;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        strBaseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return strBaseURI;
    }

    function stake(uint256 _amount) external {
        TierInfo storage tierInfoData = tierInfo[_amount];
        require(
            tierInfoData.queuedCnt < tierInfoData.maxSupply,
            "It's full at the moment, you can try later"
        );
        require(
            tierInfoData.lockDays != 0,
            "Staking amount is not precise, please check again"
        );
        require(
            userDeposit[msg.sender].tier == 0,
            "Already staked, please wait or unstake"
        );
        ERC20(jewAddress).transferFrom(msg.sender, address(this), _amount);
        userDeposit[msg.sender].tier = _amount;
        userDeposit[msg.sender]._epoch = block.timestamp;
        tierInfoData.queuedCnt++;
    }

    function unstake() external {
        require(userDeposit[msg.sender].tier != 0, "No stake found");
        userDeposit[msg.sender]._epoch = 0;
        ERC20(jewAddress).transfer(msg.sender, userDeposit[msg.sender].tier);
        TierInfo storage tierInfoData = tierInfo[userDeposit[msg.sender].tier];
        userDeposit[msg.sender].tier = 0;
        tierInfoData.queuedCnt--;
    }

    function claim() external {
        DepositInfo storage _deposit = userDeposit[msg.sender];
        require(_deposit.tier != 0, "No stake found");
        require(
            _deposit._epoch + tierInfo[_deposit.tier].lockDays >
                block.timestamp,
            "Wait for lock period"
        );
        TierInfo storage _tierInfo = tierInfo[_deposit.tier];
        uint256 _mintId = _tierInfo.startValue + _tierInfo.cnt;

        _deposit._epoch = 0;
        _deposit.tier = 0;
        _safeMint(msg.sender, _mintId);
        _tierInfo.cnt++;
    }

    function isClaimable(address _addr) public view returns (bool) {
        DepositInfo memory _deposit = userDeposit[_addr];
        return
            _deposit.tier != 0 &&
            _deposit._epoch + tierInfo[_deposit.tier].lockDays >
            block.timestamp;
    }

    function mintedSupply(uint256 _amount) public view returns (uint256) {
        TierInfo storage tierInfoData = tierInfo[_amount];
        return tierInfoData.cnt;
    }

    function progressingSupply(uint256 _amount) public view returns (uint256) {
        TierInfo storage tierInfoData = tierInfo[_amount];
        return tierInfoData.queuedCnt;
    }

    function rewardWithdraw(uint256 amount) external onlyOwner {
        ERC20(jewAddress).transfer(msg.sender, amount);
    }

    function setTierInfo(
        uint256 _tier,
        uint256 _lockdays,
        uint256 _maxSupply,
        uint256 _startvalue
    ) external onlyOwner {
        tierInfo[_tier].lockDays = _lockdays;
        tierInfo[_tier].maxSupply = _maxSupply;
        tierInfo[_tier].startValue = _startvalue;
    }
}
