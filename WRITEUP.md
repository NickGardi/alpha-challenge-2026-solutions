Wintermute Alpha Challenge

00 — Warmup

Goal: fork ETH at block 21895252, start with 10 ETH, end holding at least 1 WETH.

WETH is the usual mainnet address from Constants.sol. Wrapping is 1:1 — call deposit and send ETH along with it.

Walkthrough:
- setUp already forks and vm.deal(user, 10 ether).
- In test_Solution, vm.startBroadcast(user).
- IWETH(WETH).deposit{value: 1 ether}().
- stopBroadcast, checkSolve.

That’s it. Confirms forge + ETH_RPC_URL + .env are wired. check 00 passed.


01 — Out of Nowhere

Goal: the Ethereum tx 0xe7b8d46c3f3e5f727cb42c9dfe7fc36855ab5092cf160e4c8812a2a27a84350b is the destination side of a ~$1.5M bridge withdrawal. Find the source-chain origin_tx that set it in motion.

Walkthrough:
- Open the tx on Etherscan. It looks like a big USDC credit, but the to-address is Allbridge Classic’s unlock / bridge contract (0xBBbD1BbB4f9b936C3604906D7592A644071dE884 area). So this is the end of a bridge, not the start.
- Decode the unlock call. You get a lockId and a lockSource / source-chain tag. Decoded to be STKZ, which is Stacks chain.
- Allbridge’s bridge contract on Stacks is SP3Y2ZSH8P7D50B0VBTSX11S7XSG24M1VB9YFQA4K.bridge. Use the Hiro API (contract calls / tx history) and search for a lock with the same lock-id. We wrote a little script that pages the contract txs and matches the lock-id.
- Match: same lock id, same recipient on ETH, same ~1.5M aeUSDC locked, about 20–25 minutes earlier. That Stacks lock is the origin.

origin_tx = 0x36f2d5c245d08de980d0d23e4bd23b088312ce9e4b9845b4fd71930f52aab8fc


02 — Falling Dutchman

Goal: fork ETH at 9462777, start with 0.1 ETH, end with ≥ 4 ETH using DutchX (0xb9812E2fA995EC53B5b6DF34d21f9304762C5497).

DutchX runs ~24h Dutch auctions: sell token is what the auction is selling, buy token is what you bid with. Price decays toward zero over the day. At this fork there is a WETH/GNT auction (sell WETH, buy with GNT) that has been running basically the full day with no real bids, so the clearing price is in the floor.

What worked for me was the dead WETH/GNT auction.

Walkthrough:
- Fork, deal 0.1 ETH to user.
- auctionIndex = dutchX.getAuctionIndex(WETH, GNT); auctionStart = getAuctionStart(WETH, GNT).
- vm.warp(auctionStart + 24 hours - 1) so you’re at the end of the decay, still inside the auction.
- You need GNT balance inside DutchX to bid. Old GNT (0xa74476443119A942dE498590Fe1f2454d7D4aC0d) is painful — no normal approve/transferFrom path that plays nice here. In the fork test I used forge-std stdstore to write balances(GNT, user) on DutchX to 1 ether. That’s a test cheat for the broken ERC20, not part of the economic idea.
- As user: postBuyOrder(WETH, GNT, auctionIndex, 1 ether) — you’re buying the cheap WETH with that GNT credit.
- claimBuyerFunds(WETH, GNT, user, auctionIndex).
- withdraw(WETH, balances(WETH, user)).
- IWETH.withdraw to native ETH.

Ended a bit over 5 ETH. check 02 passed.

You’re taking the other side of an auction whose price schedule has decayed far below spot because nobody bid.


03 — Too Big To Fail

Goal: fork May 19 2021 crash block 12465029, liquidate the giant Liquity trove that later rebalanced, end with ≥ 2500 ETH. You start with 0.1 ETH.

Walkthrough:
- README links the later rebalance tx. Sender of that tx is the whale: 0x903d12bf2c57A29f32365917c706ce0e1a84Cce3.
- Liquity V1 TroveManager: 0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2.
- As user, one call: ITroveManager(TROVE_MANAGER).liquidate(WHALE).
- Liquidator gets the gas compensation slice of collateral (~0.5%). On this trove that’s about 2504 ETH.

Why bots missed it: if you only trust Liquity’s stored lastGoodPrice, the trove can look fine. With a fresh oracle price at that block the system is in Recovery Mode, and Recovery Mode liquidations hit troves that aren’t under the normal 110% ICR line. Price-blind / Recovery-Mode-blind liquidators leave money on the table.


04 — First Blood

Solana, Official TRUMP. Need two signatures in answer.txt:
- first_snipe — first attempt to snipe
- trading_possible — what actually made trading possible

Useful addresses:
- Mint: 6p6xgHyF7AeE6TZkSmFsko444wqoP15icUSqi2jfGiPN
- Main Meteora TRUMP/USDC pool: 3C5YE97HADPDxZehYq9Cis8AXr9aNyrUsczKzE1nDbW9
- Deployer / creator spam wallet: 8tKLhRgsY4xb… (shows up on almost every early pool setup tx)

Dexscreener’s ~09:11 UTC “pair created” time. I burned a lot of time hunting the first Jupiter swap in that flood. Wrong window. The pool was created and seeded earlier, then disabled, then re-enabled. “Pair created” ≠ trading open.

Walkthrough for trading_possible:
- Use the pool page on Solscan, not the mint page.
- Use the filters to find the first successful swap on that pool (~02:01:33 UTC Jan 18, 2025).
- Look at the transaction immediately before it. That’s a Meteora TogglePairStatus that re-enables the pair (02:01:32). That enable is what made trading possible.

trading_possible = 4SMUTho76nrPXxGNdDBNdBNbtbSC48oDDkivVKSdWUJR8KZGQwv1tEwJnHFXmpFDFkkLRupzzW28e6HHpv49afQt

Walkthrough for first_snipe:
- Still on the pool page, oldest-first, before the enable time.
- You’ll see a wall of initializeBinArray / position / liquidity txs. Almost all are the deployer setting up.
- Exclude every row from the creator address. The first non-creator tx (~22:05 UTC Jan 17) is a bot attempting to snipe.

first_snipe = 41h3CuLHamSdfsmgWC887eoyvrTiUcGjhLZpKMeqE9Rg9ZkP42C2gBr5PrQM9D25jRFwwQYPfBUJYCEUXC1qAxcv


05 — Smart Money

Four addresses to investigate. Nansen pro solved this one for me.

- protocol_one — raise wallet 0xAf0970A06BD17AD57f63d633be7f7039EB69Dc95
- investor_one — 0xC29Af06142138F893e3f1C1D11Aa98C3313B8C1f
- protocol_two — 0xe53ec250fDF41e52d22fEF1f76DeE92A9377AC8f
- company — 0x4c2c0F0bB2631B02aC9299C59690914ee7A200B8

protocol_one = C3 Protocol
investor_one = Node Capital
protocol_two = Aligned Layer
company = Bridge


06 — Cold Start

On Robinhood Chain, get USER_ADDRESS holding ≥ 1,000,000 CASHCAT. You cannot send an L2 tx yourself in the story, only the Delayed Inbox on Ethereum is reachable. The test forks L1 at 25347213 and L2 at 120000, then relays whatever you posted.

Constants:
- INBOX = 0x1A07cc4BD17E0118BdB54D70990D2158AbAD7a2D
- CASHCAT = 0x020bfC650A365f8BB26819deAAbF3E21291018b4
- L2 WETH = 0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73
- SwapRouter02 = 0xCaf681a66D020601342297493863E78C959E5cb2
- pool fee = 10000 (1%)

How the harness works:
- You call the L1 inbox (after setUp disables the allowlist via the rollup).
- vm.recordLogs captures the inbox message.
- _relay (do not edit) decodes it, switches to the L2 fork, and executes the call as your L2 alias: user + 0x1111…1111. That stands in for the sequencer.

Discovery:
- CASHCAT has a Uniswap v3-style pool vs WETH (liquidity pool from the token / factory).
- Pool.swap needs a contract callback. Your aliased address is still an EOA in the relay, so calling the pool directly fails.
- Scan past Swap events on the pool for a prior sender that is a contract. That’s SwapRouter02, it already implements the callback.

Walkthrough:
- Build SwapRouter02 exactInputSingle calldata (no deadline in this router ABI): tokenIn = WETH, tokenOut = CASHCAT, fee = 10000, recipient = user (NOT the alias, checkSolve reads balanceOf(user)), amountIn = 2 ether, amountOutMinimum = 1_000_000e18, sqrtPriceLimitX96 = 0.
- On L1 as user, createRetryableTicket{value: l2CallValue + maxSubmissionCost + gasLimit * maxFeePerGas}(to = SWAP_ROUTER, l2CallValue = 2 ether, maxSubmissionCost = 1 ether, excessFeeRefundAddress = user, callValueRefundAddress = user, gasLimit = 1_000_000, maxFeePerGas = 0.1 gwei, data = swapCalldata).
- Router receives the ETH value on L2 and wraps/pays WETH for the swap (periphery pay path).
- _relay runs it; CASHCAT lands on user.

Ended ~11.2M CASHCAT.


07 — Firepit

Fork X Layer at 68413600, you are dealt 2,000 UNI, end with ≥ 45,000 USDT (USD₮0).

Context: Uniswap “UNIfication” protocol fees. Anyone can burn enough UNI to release accumulated fees from a jar to themselves. X Layer had a jar worth more than the burn.

Addresses on X Layer:
- UNI = 0x57FB37d035e6Ad0E687E0a50dC3F515691deB815
- USDT = 0x779Ded0c9e1022225f8E0630b35a9b54bE713736
- TOKEN_JAR = 0x8Dd8B6D56e4a4A158EDbBfE7f2f703B8FFC1a754
- RELEASER = 0xe122E231cb52aea99690963Fd73E91e33E97468f
- FEE_ADAPTER = 0x6A88EF2e6511CAFfE2D006e260e7A5d1E7D4d7D7

Other assets that showed up in the jar: WOKB, USDC, XBTC, XETH, USDG, XSOL, XBETH, XOKSOL.

Walkthrough:
- Find Uniswap v3 pools on the chain that have accrued protocol fees. I used 22 pools and called the fee adapter in one batch: collect([{pool, amount0Requested: max, amount1Requested: max}, ...]) That sweeps fees into the jar.
- approve RELEASER for 2000e18 UNI.
- release(0, assets, user) with the list of jar tokens you care about (USDT + the others). Burns the UNI threshold and pays the jar balances to you.
- Convert non-USDT into USDT via pool.swap (test contract implements uniswapV3SwapCallback and pulls from user via transferFrom).

Direct USDT pools I used:
- WOKB → USDT on 0x9e485CC2Ec10E87A9B6e58602889Df392B7F6453
- XBTC → USDT on 0x6CF6A073dDdd6fdD74b1b9f149621E85f01AACb9
- USDC → USDT on 0xb864F203Fc61AceA1F4c98cf80a6E59132e079AF

Two-hop for XETH (thin direct pool):
- XETH → USDG on 0x6E18CEbFb9C5BBcf127b97a6daB026E941FfF6D5
- USDG → USDT on 0x0cBe0dBE1400e57f371a38BD3b9bC80F7C3676dA

The pool tier that earned the fee is not always the one with sell liquidity. Route through whatever pool is deep enough.

Final ~50,650 USDT.


08 — First Move

Two hypothetical FaultDisputeGames (Ink + Optimism) created in L1 block 25785479, gameType 8, rootClaim = 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef. For each, find the honest bytes32 claim for the first root attack:

attack(rootClaim, 0, claim)

These txs are not real; the README gives the creation params and the game reads right after creation.

Shared:
- l1Head = 0xd74f339891bc1c4af93bf4bb55c03fc3feb62da272a1f7aa3eabb9e2410126f4
- l2BlockNumber / extraData = 0x6a84f493 = 1787098259 (garbage / far-future block number)
- splitDepth = 30

Ink: factory/to 0x10d7B35078d3baabB96Dd45a9143B94be65b12CD, startingBlockNumber = 52959235
OP: factory/to 0xe5965Ab5962eDc7477C8520243A95517CD252fA9, startingBlockNumber = 155446493

What gameType 8 is: plain block-based FaultDisputeGame (v2.4.2 style), not a Super/interop game. Same impl can serve multiple chains via clone args.

Claim math (op-challenger outputs/provider.go idea):
- ClaimedBlockNumber(pos) = min(pos.TraceIndex(SPLIT_DEPTH) + startingBlockNumber + 1, l2BlockNumber)
- HonestBlockNumber(pos) = min(ClaimedBlockNumber(pos), SafeHeadAtL1Block(l1Head))

For the first root attack (gindex 2 / depth-1 left child), TraceIndex(30) = 2^29 - 1, so the “claimed” block is about startingBlockNumber + 2^29 — Ink ~589,830,147, OP ~692,317,405. Both are past the real tip, so they clamp to the L2 safe head derived from l1Head (parent of the creation block, 25785478).

Safe heads I used:
- Ink ≈ 53,599,386
- OP ≈ 155,749,670

Honest claim = L2 output root at that block:

keccak256( bytes32(0) ‖ stateRoot ‖ messagePasserStorageRoot ‖ blockHash )

where messagePasser is 0x4200000000000000000000000000000000000016, and storage root comes from eth_getProof (account storageHash) at that block.

Walkthrough:
- Identify gameType 8 + splitDepth 30 → first attack targets that huge trace index, then clamp to safe head.
- Resolve SafeHeadAtL1Block(l1Head) for Ink and OP (node / rollup APIs, or known safe head at that L1 block).
- Fetch L2 header (stateRoot, blockHash) and message passer storage root at those blocks.
- Hash the four words as above.
- Cross-check: I recomputed Ink’s root from rpc-gel.inkonchain.com header + eth_getProof and got an exact match. Same formula for OP.

ink_claim = 0x82c941153a9de14c4533b301799ee33206b6a475d7c4fdbe7cd2f1c9d7271b6f
op_claim = 0x192f163548d61d555a282e1ffcec8ec7b1e4cf9deced7e910b87292f0aeab5f1

These are bytes32 claims, not tx hashes. Deadbeef gameType-8 spam is a real pattern on these factories; the puzzle is a fabricated instance of something challengers actually race.
