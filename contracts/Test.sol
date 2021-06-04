// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Calculator.sol";
import "./IToken.sol";

contract Test {
    Calculator private _calc;
    IToken private _token;
    int256 private _result;

    constructor(address calcAddress, address tokenAddress) {
        _calc = Calculator(calcAddress);
        _token = IToken(tokenAddress);
    }

    function test(int256 nb1, int256 nb2) public returns (int256) {
        _result = _calc.add(nb1, nb2);
        return _result;
    }

    function approveCalc(address calc, uint256 amount) public {
        _token.approve(calc, amount);
    }

    function result() public view returns (int256) {
        return _result;
    }
}
