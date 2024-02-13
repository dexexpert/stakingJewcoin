pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Shekel is ERC20, Ownable {
    address public minter;
    modifier onlyMinter() {
        require(msg.sender == minter, "Only allowed minter can call this function");
        _;
    }

    constructor(address _minter) ERC20("shekel", "SHEKEL") {
        minter = _minter;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function burn(uint256 _amount) external {
        require(
            balanceOf(msg.sender) >= _amount,
            "You do not have enough balance to burn"
        );
        _burn(msg.sender, _amount);
    }

    function mint(address to, uint256 _amount) external onlyMinter{
        _mint(to, _amount);
    }
}
