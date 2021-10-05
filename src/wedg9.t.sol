pragma solidity >=0.4.23;

import "ds-test/test.sol";

import "./wedg.sol";
import "./wedg9.sol";

contract WEDG9 is WEDG9_ {
    function join() public payable {
        deposit();
    }
    function exit(uint wad) public {
        withdraw(wad);
    }
}

contract WEDG9Test is DSTest, WEDGEvents {
    WEDG9  wedg;
    Guy   a;
    Guy   b;
    Guy   c;

    function setUp() public {
        wedg  = this.newWEDG();
        a     = this.newGuy();
        b     = this.newGuy();
        c     = this.newGuy();
    }

    function newWEDG() public returns (WEDG9) {
        return new WEDG9();
    }

    function newGuy() public returns (Guy) {
        return new Guy(wedg);
    }

    function test_initial_state() public {
        assert_edg_balance   (a, 0 finney);
        assert_wedg_balance  (a, 0 finney);
        assert_edg_balance   (b, 0 finney);
        assert_wedg_balance  (b, 0 finney);
        assert_edg_balance   (c, 0 finney);
        assert_wedg_balance  (c, 0 finney);

        assert_wedg_supply   (0 finney);
    }

    function test_join() public {
        expectEventsExact    (address(wedg));

        perform_join         (a, 3 finney);
        assert_wedg_balance  (a, 3 finney);
        assert_wedg_balance  (b, 0 finney);
        assert_edg_balance   (a, 0 finney);
        assert_wedg_supply   (3 finney);

        perform_join         (a, 4 finney);
        assert_wedg_balance  (a, 7 finney);
        assert_wedg_balance  (b, 0 finney);
        assert_edg_balance   (a, 0 finney);
        assert_wedg_supply   (7 finney);

        perform_join         (b, 5 finney);
        assert_wedg_balance  (b, 5 finney);
        assert_wedg_balance  (a, 7 finney);
        assert_wedg_supply   (12 finney);
    }

    function testFail_exital_1() public {
        perform_exit         (a, 1 wei);
    }

    function testFail_exit_2() public {
        perform_join         (a, 1 finney);
        perform_exit         (b, 1 wei);
    }

    function testFail_exit_3() public {
        perform_join         (a, 1 finney);
        perform_join         (b, 1 finney);
        perform_exit         (b, 1 finney);
        perform_exit         (b, 1 wei);
    }

    function test_exit() public {
        expectEventsExact    (address(wedg));

        perform_join         (a, 7 finney);
        assert_wedg_balance  (a, 7 finney);
        assert_edg_balance   (a, 0 finney);

        perform_exit         (a, 3 finney);
        assert_wedg_balance  (a, 4 finney);
        assert_edg_balance   (a, 3 finney);

        perform_exit         (a, 4 finney);
        assert_wedg_balance  (a, 0 finney);
        assert_edg_balance   (a, 7 finney);
    }

    function testFail_transfer_1() public {
        perform_transfer     (a, 1 wei, b);
    }

    function testFail_transfer_2() public {
        perform_join         (a, 1 finney);
        perform_exit         (a, 1 finney);
        perform_transfer     (a, 1 wei, b);
    }

    function test_transfer() public {
        expectEventsExact    (address(wedg));

        perform_join         (a, 7 finney);
        perform_transfer     (a, 3 finney, b);
        assert_wedg_balance  (a, 4 finney);
        assert_wedg_balance  (b, 3 finney);
        assert_wedg_supply   (7 finney);
    }

    function testFail_transferFrom_1() public {
        perform_transfer     (a,  1 wei, b, c);
    }

    function testFail_transferFrom_2() public {
        perform_join         (a, 7 finney);
        perform_approval     (a, 3 finney, b);
        perform_transfer     (b, 4 finney, a, c);
    }

    function test_transferFrom() public {
        expectEventsExact    (address(this));

        perform_join         (a, 7 finney);
        perform_approval     (a, 5 finney, b);
        assert_wedg_balance  (a, 7 finney);
        assert_allowance     (b, 5 finney, a);
        assert_wedg_supply   (7 finney);

        perform_transfer     (b, 3 finney, a, c);
        assert_wedg_balance  (a, 4 finney);
        assert_wedg_balance  (b, 0 finney);
        assert_wedg_balance  (c, 3 finney);
        assert_allowance     (b, 2 finney, a);
        assert_wedg_supply   (7 finney);

        perform_transfer     (b, 2 finney, a, c);
        assert_wedg_balance  (a, 2 finney);
        assert_wedg_balance  (b, 0 finney);
        assert_wedg_balance  (c, 5 finney);
        assert_allowance     (b, 0 finney, a);
        assert_wedg_supply   (7 finney);
    }

    //------------------------------------------------------------------
    // Helper functions
    //------------------------------------------------------------------

    function assert_edg_balance(Guy guy, uint balance) public {
        assertEq(address(guy).balance, balance);
    }

    function assert_wedg_balance(Guy guy, uint balance) public {
        assertEq(wedg.balanceOf(address(guy)), balance);
    }

    function assert_wedg_supply(uint supply) public {
        assertEq(wedg.totalSupply(), supply);
    }

    function perform_join(Guy guy, uint wad) public {
        emit Join(address(guy), wad);
        guy.join.value(wad)();
    }

    function perform_exit(Guy guy, uint wad) public {
        emit Exit(address(guy), wad);
        guy.exit(wad);
    }

    function perform_transfer(
        Guy src, uint wad, Guy dst
    ) public {
        emit Transfer(address(src), address(dst), wad);
        src.transfer(dst, wad);
    }

    function perform_approval(
        Guy src, uint wad, Guy guy
    ) public {
        emit Approval(address(src), address(guy), wad);
        src.approve(guy, wad);
    }

    function assert_allowance(
        Guy guy, uint wad, Guy src
    ) public {
        assertEq(wedg.allowance(address(src), address(guy)), wad);
    }

    function perform_transfer(
        Guy guy, uint wad, Guy src, Guy dst
    ) public {
        emit Transfer(address(src), address(dst), wad);
        guy.transfer(src, dst, wad);
    }
}

contract Guy {
    WEDG9 wedg;

    constructor(WEDG9 _wedg) public {
        wedg = _wedg;
    }

    function join() payable public {
        wedg.join.value(msg.value)();
    }

    function exit(uint wad) public {
        wedg.exit(wad);
    }

    function () external payable {
    }

    function transfer(Guy dst, uint wad) public {
        require(wedg.transfer(address(dst), wad));
    }

    function approve(Guy guy, uint wad) public {
        require(wedg.approve(address(guy), wad));
    }

    function transfer(Guy src, Guy dst, uint wad) public {
        require(wedg.transferFrom(address(src), address(dst), wad));
    }
}
