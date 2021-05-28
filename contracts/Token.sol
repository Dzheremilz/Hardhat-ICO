// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    address private _owner;

    constructor(address owner_) ERC20("TokenTest", "TKT") {
        _owner = owner_;
        _mint(owner_, 1000000 * 10**decimals());
    }

    function owner() public view returns (address) {
        return _owner;
    }
}
