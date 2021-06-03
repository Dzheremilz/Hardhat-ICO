// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IToken.sol";

/**
 * @title An ICO on the chain
 * @author Dzheremilz
 * @notice This is an ICO for a TokenTest, people can buy TokenTest at a rate of 1 Token:1 Gwei.
 * @dev TokenTest is an ERC20 with an add 'owner' only to use as the original token possessor.
 * The ERC20 'owner' need to approve this ICO from Token contract.
 * ICO will last 2 weeks from his deployement, during this period, buyer could send ether using 2 functions :
 * the receive or buyTokens function which will transfer the amount of token bought on the TokenTest balance.
 * After the period, ICO Owner will be able to withdraw the ether sent by the buyers,
 * this will mark the end of this contract.
 */

contract ICO is Ownable {
    using Address for address payable;

    IToken private _token;
    uint256 private _dateEnd;

    event Bought(address indexed buyer, uint256 amount);
    event Withdrew(address indexed owner, uint256 amount);

    /**
     * @dev set the ERC20 address and start the 2 weeks timer.
     *
     * @param tokenAddress set the address of the ERC20 TokenTest.
     */
    constructor(address tokenAddress) {
        _token = IToken(tokenAddress);
        require(_token.balanceOf(_token.owner()) == 1000000 * 10**18, "ICO: owner must have token to exchange");
        _dateEnd = block.timestamp + 2 * 1 weeks;
    }

    /**
     * @dev use to receive ether directly from a transaction, See _buyTokens
     */
    receive() external payable {
        _buyTokens(msg.sender, msg.value);
    }

    /**
     * @dev use at the end of the ICO when date limit is reach, ICO owner can withdraw
     * all the ether sent by the buyers
     */
    function withdraw() public onlyOwner {
        require(block.timestamp >= _dateEnd, "ICO: you need to wait 2 weeks from the deployment of this contract");
        uint256 gain = address(this).balance;
        payable(msg.sender).sendValue(address(this).balance);
        emit Withdrew(msg.sender, gain);
    }

    /**
     * @dev use to buy erc20 TokenTest using ether, See _buyTokens
     */
    function buyTokens() public payable {
        _buyTokens(msg.sender, msg.value);
    }

    /**
     * @dev exchange rate
     * @param amount in ethers
     * @return value in TokenTest
     */
    function conversion(uint256 amount) public pure returns (uint256) {
        return amount * 10**9;
    }

    /**
     * @return number of token sold by this ICO, imprecise value (+- 1)
     */
    function tokenSold() public view returns (uint256) {
        return conversion(total()) / 10**18; //imprecise, 1 token = 10**18
    }

    /**
     * @return ether value on this contract
     */
    function total() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev second left to buy TokenTest or ICO already finished
     * @return time left in seconds before the end of the ICO
     */
    function timeLeft() public view returns (uint256) {
        require(block.timestamp < _dateEnd, "ICO: there is no time left");
        return _dateEnd - block.timestamp;
    }

    /**
     * @dev Give buyers the convert amount of TokenTest they bought.
     * One cannot buy before the TokenTest owner has approved this contract.
     * If the last buyer send more ethers than this contract can sell, he got the difference refund.
     * @param sender the buyer
     * @param amount in ether
     */
    function _buyTokens(address sender, uint256 amount) private {
        require(block.timestamp < _dateEnd, "ICO: 2 weeks have passed, you can no longer buy token");
        //edge case start: prople send eth before approve or all approve token are sold
        uint256 allowance = _token.allowance(_token.owner(), address(this));
        require(allowance > 0, "ICO: has not been approved yet or all token are already sold");
        // require(_token.balanceOf(_token.owner()) > 0, "ICO: there is no more token to buy"); => transferFrom got this check
        uint256 token = conversion(amount);
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
