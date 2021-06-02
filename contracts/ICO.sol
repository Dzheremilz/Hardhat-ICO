// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IToken.sol";

contract ICO is Ownable {
    using Address for address payable;

    IToken private _token;
    uint256 private _dateEnd;

    event Bought(address indexed buyer, uint256 amount);
    event Withdrew(address indexed owner, uint256 amount);

    constructor(address tokenAddress) {
        _token = IToken(tokenAddress);
        require(_token.balanceOf(_token.owner()) == 1000000 * 10**18, "ICO: owner must have token to exchange");
        _dateEnd = block.timestamp + 2 * 1 weeks;
    }

    receive() external payable {
        _buyTokens(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        require(block.timestamp >= _dateEnd, "ICO: you need to wait 2 weeks from the deployment of this contract");
        uint256 gain = address(this).balance;
        payable(msg.sender).sendValue(address(this).balance);
        emit Withdrew(msg.sender, gain);
    }

    function buyTokens() public payable {
        _buyTokens(msg.sender, msg.value);
    }

    function conversion(uint256 amount) public pure returns (uint256) {
        return amount * 10**9;
    }

    function tokenSold() public view returns (uint256) {
        return conversion(total()) / 10**18; //imprecise, 1 token = 10**18
    }

    function total() public view returns (uint256) {
        return address(this).balance;
    }

    function timeLeft() public view returns (uint256) {
        require(block.timestamp < _dateEnd, "ICO: there is no time left");
        return _dateEnd - block.timestamp;
    }

    function _buyTokens(address sender, uint256 amount) private {
        require(block.timestamp < _dateEnd, "ICO: 2 weeks have passed, you can no longer buy token");
        //edge case start: prople send eth before approve or all approve token are sold
        require(
            _token.allowance(_token.owner(), address(this)) > 0,
            "ICO: has not been approved yet or all token are already sold"
        );
        // require(_token.balanceOf(_token.owner()) > 0, "ICO: there is no more token to buy"); => transferFrom got this check
        uint256 token = conversion(amount);
        uint256 allowance = _token.allowance(_token.owner(), address(this));
        //edge case end: last token
        if (token > allowance) {
            uint256 rest = token - allowance;
            token -= rest;
            payable(sender).sendValue(rest / 10**9);
        }
        _token.transferFrom(_token.owner(), sender, token);
        emit Bought(sender, amount);
    }
}
