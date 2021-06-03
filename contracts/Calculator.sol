// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IToken.sol";

/**
 * @title A Calculator using TokenTest
 * @author Dzheremilz
 * @dev a simple calculator using an ERC20 TokenTest to make his functionality usable at a token cost
 * users must approve this calculator contract before they can use its functions
 */
contract Calculator {
    IToken private _token;
    address private _owner;
    uint256 private constant _PRICE = 1 ether;

    event Calculated(string calc, address indexed user, int256 nb1, int256 nb2, int256 result);

    /**
     * @dev set the tokenAddress and owner at deployment
     * tokenAddress is use to check users balance and transfer the price to the owner account
     * @param tokenAddress TokenTest ERC20 deployment address
     * @param owner_ Owner of calculator
     */
    constructor(address tokenAddress, address owner_) {
        _token = IToken(tokenAddress);
        _owner = owner_;
    }

    modifier paymentValue() {
        require(
            _token.balanceOf(msg.sender) >= 1 ether,
            "Calculator: you do not have enough token to use this function"
        );
        require(
            _token.allowance(msg.sender, address(this)) >= 1 ether,
            "Calculator: you need to approve this smart contract for at least 1 token before using it"
        );
        _;
    }

    /**
     * @dev Calculate a sum, transfer the price to the owner and emit an event
     * User need to possess at least one TokenTest and approve this contract to use this
     * @param nb1 a number
     * @param nb2 a number
     * @return The sum of the 2 params
     */
    function add(int256 nb1, int256 nb2) public returns (int256) {
        _token.transferFrom(msg.sender, _owner, _PRICE);
        emit Calculated("Addition", msg.sender, nb1, nb2, nb1 + nb2);
        return nb1 + nb2;
    }

    /**
     * @dev Calculate a substraction, transfer the price to the owner and emit an event
     * User need to possess at least one TokenTest and approve this contract to use this
     * @param nb1 a number
     * @param nb2 a number
     * @return The substraction of the 2 params
     */
    function sub(int256 nb1, int256 nb2) public paymentValue returns (int256) {
        _token.transferFrom(msg.sender, _owner, _PRICE);
        emit Calculated("Substraction", msg.sender, nb1, nb2, nb1 - nb2);
        return nb1 - nb2;
    }

    /**
     * @dev Calculate a multiplication, transfer the price to the owner and emit an event
     * User need to possess at least one TokenTest and approve this contract to use this
     * @param nb1 a number
     * @param nb2 a number
     * @return The multiplication of the 2 params
     */
    function mul(int256 nb1, int256 nb2) public paymentValue returns (int256) {
        _token.transferFrom(msg.sender, _owner, _PRICE);
        emit Calculated("Multiplication", msg.sender, nb1, nb2, nb1 * nb2);
        return nb1 * nb2;
    }

    /**
     * @dev Calculate a division, transfer the price to the owner and emit an event
     * User need to possess at least one TokenTest and approve this contract to use this
     * @param nb1 a number
     * @param nb2 a number
     * @return The division of the 2 params
     */
    function div(int256 nb1, int256 nb2) public paymentValue returns (int256) {
        require(nb2 != 0, "Calculator: can not divide by zero");
        _token.transferFrom(msg.sender, _owner, _PRICE);
        emit Calculated("Division", msg.sender, nb1, nb2, nb1 / nb2);
        return nb1 / nb2;
    }

    /**
     * @dev Calculate a modulo, transfer the price to the owner and emit an event
     * User need to possess at least one TokenTest and approve this contract to use this
     * @param nb1 a number
     * @param nb2 a number
     * @return The modulo of the 2 params
     */
    function mod(int256 nb1, int256 nb2) public paymentValue returns (int256) {
        require(nb2 != 0, "Calculator: can not modulus by zero");
        _token.transferFrom(msg.sender, _owner, _PRICE);
        emit Calculated("Modulus", msg.sender, nb1, nb2, nb1 % nb2);
        return nb1 % nb2;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the price to use calc functions.
     */
    function price() public pure returns (uint256) {
        return _PRICE;
    }
}
