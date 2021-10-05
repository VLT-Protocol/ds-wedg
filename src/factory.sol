pragma solidity >=0.4.23;

import "./wedg9.sol";

contract DSWedgFactory {
    event LogMake(address indexed creator, address token);

    function make() public returns (WEDG9_ result) {
        result = new WEDG9_();
        emit LogMake(msg.sender, address(result));
    }
}
