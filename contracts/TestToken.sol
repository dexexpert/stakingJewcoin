pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JewCoin is ERC20, Ownable {
    constructor() ERC20("jewCoin", "JEC") {
        _mint(msg.sender, 6 * 1000000 * 10 ** 18);
    }

    function burn(uint256 _amount) external {
        require(
            balanceOf(msg.sender) >= _amount,
            "You do not have enough balance to burn"
        );
        _burn(msg.sender, _amount);
    }
}
