// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../../src/Interfaces.sol";

contract Firepit is Test {
    address user = vm.envAddress("USER_ADDRESS");
    address constant UNI = 0x57FB37d035e6Ad0E687E0a50dC3F515691deB815;
    address constant USDT = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;

    function setUp() public {
        vm.createSelectFork(vm.envString("XLAYER_RPC_URL"), 68413600);
        vm.etch(0x4200000000000000000000000000000000000010, hex"60006000f3");
        deal(UNI, user, 2000e18);
    }

    function test_Solution() public {
        vm.startPrank(user);

        // your code

        vm.stopPrank();
        checkSolve();
    }

    function checkSolve() public view {
        require(IERC20(USDT).balanceOf(user) >= 45_000e6, "not enough USDT");
        console.log("Firepit solved. USDT: %6e", IERC20(USDT).balanceOf(user));
    }
}
