// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract mockRETH is ERC20 {
    constructor() ERC20("RETH", "RETH")
    {
        _mint(msg.sender, 1000000*1e18);
    }

    function getExchangeRatio() external view returns (uint256) {
        return 1074993471797417217;
    }
}