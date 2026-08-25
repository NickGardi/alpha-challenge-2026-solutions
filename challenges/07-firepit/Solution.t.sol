// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../../src/Interfaces.sol";

interface IReleaser {
    function release(uint256 _nonce, address[] calldata assets, address recipient) external;
    function nonce() external view returns (uint256);
    function threshold() external view returns (uint256);
}

interface IV3OpenFeeAdapter {
    struct CollectParams {
        address pool;
        uint128 amount0Requested;
        uint128 amount1Requested;
    }

    struct Collected {
        uint128 amount0Collected;
        uint128 amount1Collected;
    }

    function collect(CollectParams[] calldata collectParams)
        external
        returns (Collected[] memory amountsCollected);
}

interface IUniswapV3PoolMinimal {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

contract Firepit is Test {
    address user = vm.envAddress("USER_ADDRESS");
    address constant UNI = 0x57FB37d035e6Ad0E687E0a50dC3F515691deB815;
    address constant USDT = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736;

    address constant TOKEN_JAR = 0x8Dd8B6D56e4a4A158EDbBfE7f2f703B8FFC1a754;
    address constant RELEASER = 0xe122E231cb52aea99690963Fd73E91e33E97468f;
    address constant FEE_ADAPTER = 0x6A88EF2e6511CAFfE2D006e260e7A5d1E7D4d7D7;

    address constant WOKB = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;
    address constant USDC = 0x74b7F16337b8972027F6196A17a631aC6dE26d22;
    address constant XBTC = 0xb7C00000bcDEeF966b20B3D884B98E64d2b06b4f;
    address constant XETH = 0xE7B000003A45145decf8a28FC755aD5eC5EA025A;
    address constant USDG = 0x4ae46a509F6b1D9056937BA4500cb143933D2dc8;
    address constant XSOL = 0x505000008DE8748DBd4422ff4687a4FC9bEba15b;
    address constant XBETH = 0xAFeab3B85B6A56cF5F02317F0f7A23340eb983D7;
    address constant XOKSOL = 0x14a686103854DAB7b8801E31979CAA595835B25d;

    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint160 constant MIN_SQRT_RATIO = 4295128739;

    function setUp() public {
        vm.createSelectFork(vm.envString("XLAYER_RPC_URL"), 68413600);
        vm.etch(0x4200000000000000000000000000000000000010, hex"60006000f3");
        deal(UNI, user, 2000e18);
    }

    function test_Solution() public {
        vm.startPrank(user);

        address[22] memory pools = [
            0x9e485CC2Ec10E87A9B6e58602889Df392B7F6453,
            0xe3BE6A0137f1b0602Fc1a4841686f43B340a5082,
            0x63d62734847E55A266FCa4219A9aD0a02D5F6e02,
            0xb864F203Fc61AceA1F4c98cf80a6E59132e079AF,
            0x6D8CBF53b42195c2e924087cA1Ac9BBD2eca6042,
            0xA10F7cE05b9149A3c91261D4dbb13FBF8F632a0f,
            0x6CF6A073dDdd6fdD74b1b9f149621E85f01AACb9,
            0x5fcFb33C9AB1665FeE892eB2aF163e863a874D73,
            0x77ef18adF35f62B2Ad442e4370cDbC7fe78B7dcC,
            0x0cBe0dBE1400e57f371a38BD3b9bC80F7C3676dA,
            0x4651300221f345a4c6F566079BD1DDC291049c7d,
            0x3c2a3E37A6A905b3308861222a92fF2bE2d6DA62,
            0x92Ae4136f5F141F9d20eAa0c3533f48c21Fa8580,
            0x01Cd955cba093127A5f6f8c7DED4fB773e150761,
            0x5d7E3Ad08B0C52e460787677B0632Cd024Df437C,
            0x84d4DbEebFf5F77c63F36bD0dCb18121Aa9aC8fc,
            0xf845C41c0683cE99B8c1F36c46B2D93E1533470c,
            0x520F8c07A529FFb5230e76bCb8EA553D664e5b76,
            0x6E18CEbFb9C5BBcf127b97a6daB026E941FfF6D5,
            0xc1382e9eb8F3Df11D348D1DCcA34e246690122A2,
            0x1284d2df2bF7DaC317D219d055Bd16F8259E06Df,
            0x97Bb2A4EA57B1A20D3b237B2325f56EFe25e4cE0
        ];

        IV3OpenFeeAdapter.CollectParams[] memory params =
            new IV3OpenFeeAdapter.CollectParams[](pools.length);
        for (uint256 i; i < pools.length; i++) {
            params[i] = IV3OpenFeeAdapter.CollectParams({
                pool: pools[i],
                amount0Requested: type(uint128).max,
                amount1Requested: type(uint128).max
            });
        }
        IV3OpenFeeAdapter(FEE_ADAPTER).collect(params);

        IERC20(UNI).approve(RELEASER, 2000e18);
        address[] memory assets = new address[](9);
        assets[0] = USDT;
        assets[1] = WOKB;
        assets[2] = USDC;
        assets[3] = XBTC;
        assets[4] = XETH;
        assets[5] = USDG;
        assets[6] = XSOL;
        assets[7] = XBETH;
        assets[8] = XOKSOL;
        IReleaser(RELEASER).release(0, assets, user);

        IERC20(WOKB).approve(address(this), IERC20(WOKB).balanceOf(user));
        IERC20(USDC).approve(address(this), IERC20(USDC).balanceOf(user));
        IERC20(XBTC).approve(address(this), IERC20(XBTC).balanceOf(user));
        IERC20(XETH).approve(address(this), IERC20(XETH).balanceOf(user));
        IERC20(USDG).approve(address(this), type(uint256).max);
        vm.stopPrank();

        _swapToUSDT(0x9e485CC2Ec10E87A9B6e58602889Df392B7F6453, WOKB);
        _swapToUSDT(0x6CF6A073dDdd6fdD74b1b9f149621E85f01AACb9, XBTC);
        _swapToUSDT(0xb864F203Fc61AceA1F4c98cf80a6E59132e079AF, USDC);
        _swap(0x6E18CEbFb9C5BBcf127b97a6daB026E941FfF6D5, XETH, USDG);
        _swapToUSDT(0x0cBe0dBE1400e57f371a38BD3b9bC80F7C3676dA, USDG);

        checkSolve();
    }

    function _swapToUSDT(address pool, address tokenIn) internal {
        _swap(pool, tokenIn, USDT);
    }

    function _swap(address pool, address tokenIn, address tokenOut) internal {
        uint256 amountIn = IERC20(tokenIn).balanceOf(user);
        if (amountIn == 0) return;

        bool zeroForOne = IUniswapV3PoolMinimal(pool).token0() == tokenIn;
        require(
            zeroForOne
                ? IUniswapV3PoolMinimal(pool).token1() == tokenOut
                : IUniswapV3PoolMinimal(pool).token0() == tokenOut,
            "bad pool"
        );
        uint160 sqrtPriceLimitX96 = zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1;

        IUniswapV3PoolMinimal(pool).swap(
            user, zeroForOne, int256(amountIn), sqrtPriceLimitX96, abi.encode(tokenIn)
        );
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data)
        external
    {
        address tokenIn = abi.decode(data, (address));
        uint256 owed = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
        IERC20(tokenIn).transferFrom(user, msg.sender, owed);
    }

    function checkSolve() public view {
        require(IERC20(USDT).balanceOf(user) >= 45_000e6, "not enough USDT");
        console.log("Firepit solved. USDT: %6e", IERC20(USDT).balanceOf(user));
    }
}
