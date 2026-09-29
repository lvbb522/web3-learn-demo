# V2 Core
## UniswapV2Factory
### 接口概述
```solidity
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
```

### 只读方法 (Read-Only Functions)

#### `feeTo()`

- **功能**：返回协议费用接收地址。如果该地址为零地址（`0x0`），则表示协议费用当前处于**关闭状态**，所有交易手续费（0.3%）都归流动性提供者（LP）所有。
- **参数**：无。
- **返回值**：`address` – 协议费用接收合约或地址。
- **治理背景**：该地址由 `feeToSetter` 管理，其变更通常需要 Uniswap 治理投票。目前该地址通常指向一个由协议控制的合约（如 `TokenJar`），而非个人钱包

#### `feeToSetter()`

- **功能**：返回有权修改 `feeTo` 地址的管理员地址。
- **参数**：无。
- **返回值**：`address` – 当前的管理员地址（通常是治理 Timelock 合约）。

#### `getPair(address tokenA, address tokenB)`

- **功能**：查询 `tokenA` 和 `tokenB` 对应的交易对（Pair）合约地址。
- **参数**：
    - `tokenA` (address): 第一个代币的合约地址。
    - `tokenB` (address): 第二个代币的合约地址。
- **返回值**：`address pair` – 交易对合约地址。如果该交易对**尚未创建**，则返回零地址（`0x0`）。
- **注意**：两个代币参数的顺序可以互换，结果相同

#### `allPairs(uint)`

- **功能**：根据索引查询通过此 Factory 创建的第 `n` 个交易对地址。
- **参数**：
    - `uint`: 交易对的索引（从 `0` 开始计数）。
- **返回值**：`address pair` – 对应索引的交易对地址。如果索引超出已创建的总数，返回零地址。

#### `allPairsLength()`

- **功能**：返回通过此 Factory 创建的交易对总数。
- **参数**：无。
- **返回值**：`uint` – 已创建的交易对数量。

### 状态变更方法 (State-Changing Functions)

#### `createPair(address tokenA, address tokenB)`

- **功能**：为 `tokenA` 和 `tokenB` 创建一个全新的交易对（Pair）合约。
- **参数**：
    - `tokenA` (address): 第一个代币的合约地址。
    - `tokenB` (address): 第二个代币的合约地址。
- **返回值**：`address pair` – 新创建的 Pair 合约地址。
- **核心逻辑与约束**：
    1. **禁止相同代币**：`tokenA` 必须不等于 `tokenB`。
    2. **禁止零地址**：两个代币地址都不能是 `0x0`。
    3. **唯一性检查**：如果该交易对已存在（即 `getPair` 返回非零地址），则**直接回滚**（`PAIR_EXISTS`），防止重复创建。
    4. **地址排序**：在内部，代币地址会被严格排序（`token0 < token1`），确保无论传入顺序如何，Pair 地址都是唯一的且确定性的。
    5. **CREATE2 部署**：使用 `CREATE2` 操作码部署 `UniswapV2Pair` 合约，这意味着 Pair 地址是**确定性**的，可以通过 `token0`、`token1` 和 Factory 地址预先计算出来（即 `pairFor` 函数的原理）。
- **事件**：成功创建后触发 `PairCreated` 事件，其中包含排序后的 `token0`、`token1`、新 `pair` 地址以及当前的总数索引。

#### `setFeeTo(address)`

- **功能**：修改协议费用接收地址（`feeTo`）。
- **参数**：
    - `address`: 新的费用接收地址。
- **访问控制**：**仅限 `feeToSetter` 调用**。其他地址调用将回滚（`FORBIDDEN`）。
- **影响**：将此地址设置为非零地址将**全局开启**协议费用机制。此后，所有 V2 池子将开始抽取 0.05% 的协议费用（从 LP 的 0.25% 收益中分出）。

#### `setFeeToSetter(address)`

- **功能**：移交管理员权限，修改 `feeToSetter` 地址。
- **参数**：
    - `address`: 新的管理员地址。
- **访问控制**：**仅限当前 `feeToSetter` 调用**。这是一个“两步转移”式的权限变更，用于将控制权移交给治理合约或其他地址。

## UniswapV2Pair

### 接口概览
```solidity
interface IUniswapV2Pair is IUniswapV2ERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
```

### 只读方法

#### `factory()`

- **功能**：返回创建此 Pair 的 Factory 合约地址。
- **参数**：无。
- **返回值**：`address` – Factory 合约地址。

#### `token0()` / `token1()`

- **功能**：返回此交易对中排序后的两种代币地址。`token0` 的地址一定小于 `token1`。
- **参数**：无。
- **返回值**：`address` – 对应代币的合约地址。

#### `getReserves()`

- **功能**：获取当前池子的储备量及上次更新时间戳。这是链下计算兑换价格和链上其他合约读取价格的核心方法。
- **参数**：无。
- **返回值**：
    - `uint112 _reserve0`: token0 的储备量。
    - `uint112 _reserve1`: token1 的储备量。
    - `uint32 _blockTimestampLast`: 上次更新储备量时的区块时间戳（取模 2^32）。

#### `price0CumulativeLast()` / `price1CumulativeLast()`

- **功能**：返回累计价格变量，用于构建 TWAP 预言机。记录的是“价格 × 时间”的累加值。
- **参数**：无。
- **返回值**：`uint` – 累计价格值。

#### `kLast()`

- **功能**：返回上次流动性事件（mint/burn）时记录的恒定乘积值（`reserve0 * reserve1`），用于计算协议费用。
- **参数**：无。
- **返回值**：`uint` – 上次记录的 k 值。

### 状态变更方法 

#### `initialize(address _token0, address _token1)`

- **功能**：初始化 Pair 合约的代币地址。**只能由 Factory 合约在创建 Pair 时调用一次**。
- **参数**：
    - `_token0`: 排序后的第一个代币地址。
    - `_token1`: 排序后的第二个代币地址。
- **返回值**：无。
- **访问控制**：`require(msg.sender == factory)`。

#### `mint(address to)`

- **功能**：铸造 LP 代币。**调用前需先将两种代币转入 Pair 合约**。合约会根据新增的资产比例计算应铸造的 LP 代币数量并发送给 `to`。
- **参数**：
    - `to` (address): 接收 LP 代币的地址。
- **返回值**：`uint liquidity` – 实际铸造的 LP 代币数量。
- **核心逻辑**：首次添加流动性时，铸造量 = `sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY`，其中 `MINIMUM_LIQUIDITY`（1000）被永久锁定到零地址。后续添加则按比例计算。

#### `burn(address to)`

- **功能**：销毁 LP 代币并取回底层资产。**调用前需先将 LP 代币转入 Pair 合约**。合约会按比例将两种代币发送给 `to`。
- **参数**：
    - `to` (address): 接收底层资产的地址。
- **返回值**：
    - `uint amount0`: 取回的 token0 数量。
    - `uint amount1`: 取回的 token1 数量。

#### `swap(uint amount0Out, uint amount1Out, address to, bytes calldata data)`

- **功能**：执行兑换或闪电贷。**调用前需先转入输入代币**，或通过 `data` 参数触发回调在后续归还。
- **参数**：
    - `amount0Out`: 要转出的 token0 数量。
    - `amount1Out`: 要转出的 token1 数量。
    - `to`: 接收输出代币的地址。
    - `data`: 附加数据，非空时触发闪电贷回调。
- **返回值**：无。

#### `skim(address to)`

- **功能**：提取超出账面储备（`reserve`）的那部分代币，发送给 `to`。用于处理意外转入或余额溢出问题。
- **参数**：
    - `to` (address): 接收多余代币的地址。
- **返回值**：无。

#### `sync()`

- **功能**：将合约记录的储备量更新为当前实际余额，修复“账实不符”的问题。
- **参数**：无。
- **返回值**：无。

# V2 Periphery

## UniswapV2Router02

### 接口概览

```solidity
interface IUniswapV2Router02 is IUniswapV2Router01 {
    // ===== Router02 新增，支持转账扣费代币 =====
    function removeLiquidityETHSupportingFeeOnTransferTokens(...) external returns (uint);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(...) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(...) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(...) external;
}
interface IUniswapV2Router01 {
    // ===== 流动性管理 =====
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(...) external returns (uint, uint, uint);
    function addLiquidityETH(...) external payable returns (uint, uint, uint);
    function removeLiquidity(...) external returns (uint, uint);
    function removeLiquidityETH(...) external returns (uint);
    function removeLiquidityWithPermit(...) external returns (uint, uint);
    function removeLiquidityETHWithPermit(...) external returns (uint);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(...) external returns (uint);
    // ===== 兑换交易 =====
    function swapExactTokensForTokens(...) external returns (uint[] memory);
    function swapTokensForExactTokens(...) external returns (uint[] memory);
    function swapExactETHForTokens(...) external payable returns (uint[] memory);
    function swapTokensForExactETH(...) external returns (uint[] memory);
    function swapExactTokensForETH(...) external returns (uint[] memory);
    function swapETHForExactTokens(...) external payable returns (uint[] memory);
    // ===== 报价与辅助 =====
    function quote(...) external pure returns (uint);
    function getAmountOut(...) external pure returns (uint);
    function getAmountIn(...) external pure returns (uint);
    function getAmountsOut(...) external view returns (uint[] memory);
    function getAmountsIn(...) external view returns (uint[] memory);
}
```

### 只读方法 (Read-Only Functions)

#### `factory()`

- **功能**：返回 Uniswap V2 Factory 合约的地址。
- **参数**：无。
- **返回值**：`address` – Factory 合约地址。

#### `WETH()`

- **功能**：返回 WETH（Wrapped Ether）合约的地址。
- **参数**：无。
- **返回值**：`address` – WETH 合约地址。

#### `quote(uint amountA, uint reserveA, uint reserveB)`

- **功能**：给定某代币的数量和储备量，根据比例计算另一种代币的等值数量。用于链下报价，不消耗 Gas。
- **参数**：
    - `amountA` (uint): 代币 A 的数量。
    - `reserveA` (uint): 代币 A 在池子中的储备量。
    - `reserveB` (uint): 代币 B 在池子中的储备量。
- **返回值**：`uint amountB` – 等值的代币 B 数量。公式：`amountA * reserveB / reserveA`。

#### `getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)`

- **功能**：给定精确的输入量和池子储备，计算能换到多少输出代币。**已扣除 0.3% 手续费**。
- **参数**：
    - `amountIn` (uint): 输入代币数量。
    - `reserveIn` (uint): 输入代币的储备量。
    - `reserveOut` (uint): 输出代币的储备量。
- **返回值**：`uint amountOut` – 实际能换到的输出代币数量。

#### `getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)`

- **功能**：给定精确的输出量和池子储备，计算需要多少输入代币。**已包含 0.3% 手续费**。
- **参数**：
    - `amountOut` (uint): 期望的输出代币数量。
    - `reserveIn` (uint): 输入代币的储备量。
    - `reserveOut` (uint): 输出代币的储备量。
- **返回值**：`uint amountIn` – 需要支付的输入代币数量。

#### `getAmountsOut(uint amountIn, address[] path)`

- **功能**：给定精确的输入量和路径，计算路径上每一步能换到的代币数量。
- **参数**：
    - `amountIn` (uint): 输入代币数量。
    - `path` (address[]): 兑换路径数组，第一个是输入代币，最后一个是输出代币。
- **返回值**：`uint[] memory amounts` – 路径上每一步的数量数组，`amounts[0] = amountIn`，最后一个元素是最终输出。

#### `getAmountsIn(uint amountOut, address[] path)`

- **功能**：给定精确的输出量和路径，从目标倒推，计算路径上每一步需要多少输入代币。
- **参数**：
    - `amountOut` (uint): 期望的输出代币数量。
    - `path` (address[]): 兑换路径数组。
- **返回值**：`uint[] memory amounts` – 路径上每一步的数量数组，`amounts[amounts.length - 1] = amountOut`，第一个元素是实际需要的输入量。

### 流动性管理方法 

#### `addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline)`

- **功能**：向 ERC-20⇄ERC-20 池子添加流动性。合约会按当前池子比例计算实际需要的两种代币数量。
- **参数**：
    - `tokenA` / `tokenB` (address): 两种代币的地址。
    - `amountADesired` / `amountBDesired` (uint): 希望存入的两种代币数量。
    - `amountAMin` / `amountBMin` (uint): 愿意接受的最小存入量，用于滑点保护。
    - `to` (address): 接收 LP 代币的地址。
    - `deadline` (uint): 交易截止时间。
- **返回值**：
    - `uint amountA`: 实际存入的 tokenA 数量。
    - `uint amountB`: 实际存入的 tokenB 数量。
    - `uint liquidity`: 铸造的 LP 代币数量。

#### `addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline)`

- **功能**：向 ERC-20⇄WETH 池子添加流动性，直接使用 ETH（内部自动包装为 WETH）。
- **参数**：
    - `token` (address): ERC-20 代币地址。
    - `amountTokenDesired` (uint): 希望存入的代币数量。
    - `amountTokenMin` / `amountETHMin` (uint): 最小存入量，滑点保护。
    - `to` (address): 接收 LP 代币的地址。
    - `deadline` (uint): 截止时间。
    - `msg.value`: 发送的 ETH 数量。
- **返回值**：
    - `uint amountToken`: 实际存入的代币数量。
    - `uint amountETH`: 实际存入的 ETH 数量。
    - `uint liquidity`: 铸造的 LP 代币数量。

#### `removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline)`

- **功能**：销毁 LP 代币，取回 ERC-20⇄ERC-20 池子中的两种底层代币。
- **参数**：
    - `tokenA` / `tokenB` (address): 两种代币地址。
    - `liquidity` (uint): 要销毁的 LP 代币数量。
    - `amountAMin` / `amountBMin` (uint): 愿意接受的最小取回量。
    - `to` (address): 接收底层资产的地址。
    - `deadline` (uint): 截止时间。
- **返回值**：
    - `uint amountA`: 取回的 tokenA 数量。
    - `uint amountB`: 取回的 tokenB 数量。

#### `removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline)`

- **功能**：销毁 LP 代币，取回 ERC-20⇄WETH 池子中的代币和 ETH（WETH 自动解包）。
- **参数**：
    - `token` (address): ERC-20 代币地址。
    - `liquidity` (uint): 要销毁的 LP 代币数量。
    - `amountTokenMin` / `amountETHMin` (uint): 最小取回量。
    - `to` (address): 接收资产的地址。
    - `deadline` (uint): 截止时间。
- **返回值**：`uint amountETH` – 取回的 ETH 数量。

#### `removeLiquidityWithPermit(...)`

- **功能**：与 `removeLiquidity` 相同，但使用 EIP-2612 离线签名授权 LP 代币，无需单独发起 `approve` 交易。
- **参数**：在 `removeLiquidity` 基础上增加 `v`、`r`、`s` 签名参数。
- **返回值**：同 `removeLiquidity`。

#### `removeLiquidityETHWithPermit(...)`

- **功能**：与 `removeLiquidityETH` 相同，但使用离线签名授权。
- **参数**：在 `removeLiquidityETH` 基础上增加签名参数。
- **返回值**：同 `removeLiquidityETH`。

#### `removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(...)`

- **功能**：与 `removeLiquidityETHWithPermit` 相同，但支持转账扣费代币（此函数在 Router01 接口中已声明，但实际实现在 Router02 中）。
- **参数**：同 `removeLiquidityETHWithPermit`。
- **返回值**：`uint amountETH` – 实际收到的 ETH 数量。

### ✍️ 兑换交易方法 (State-Changing Functions)

#### `swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] path, address to, uint deadline)`

- **功能**：用精确数量的输入代币，换取尽可能多的输出代币。
- **参数**：
    - `amountIn` (uint): 精确的输入代币数量。
    - `amountOutMin` (uint): 最小输出代币数量，滑点保护。
    - `path` (address[]): 兑换路径。
    - `to` (address): 接收输出代币的地址。
    - `deadline` (uint): 截止时间。
- **返回值**：`uint[] memory amounts` – 路径上每一步的数量数组。

#### `swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] path, address to, uint deadline)`

- **功能**：用尽可能少的输入代币，换取精确数量的输出代币。
- **参数**：
    - `amountOut` (uint): 精确的输出代币数量。
    - `amountInMax` (uint): 最大输入代币数量，滑点保护。
    - `path` (address[]): 兑换路径。
    - `to` (address): 接收输出代币的地址。
    - `deadline` (uint): 截止时间。
- **返回值**：`uint[] memory amounts` – 路径上每一步的数量数组。

#### `swapExactETHForTokens(uint amountOutMin, address[] path, address to, uint deadline)`

- **功能**：用精确数量的 ETH，换取尽可能多的代币。
- **参数**：
    - `amountOutMin` (uint): 最小输出代币数量。
    - `path` (address[]): 路径数组，**第一个元素必须是 WETH**。
    - `to` (address): 接收代币的地址。
    - `deadline` (uint): 截止时间。
    - `msg.value`: 发送的 ETH 数量。
- **返回值**：`uint[] memory amounts` – 路径上每一步的数量数组。
    

#### `swapTokensForExactETH(uint amountOut, uint amountInMax, address[] path, address to, uint deadline)`

- **功能**：用尽可能少的代币，换取精确数量的 ETH。
- **参数**：
    - `amountOut` (uint): 精确的 ETH 输出数量。
    - `amountInMax` (uint): 最大输入代币数量。
    - `path` (address[]): 路径数组，**最后一个元素必须是 WETH**。
    - `to` (address): 接收 ETH 的地址。
    - `deadline` (uint): 截止时间。
- **返回值**：`uint[] memory amounts` – 路径上每一步的数量数组。

#### `swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] path, address to, uint deadline)`

- **功能**：用精确数量的代币，换取尽可能多的 ETH。
- **参数**：
    - `amountIn` (uint): 精确的输入代币数量。
    - `amountOutMin` (uint): 最小 ETH 输出数量。
    - `path` (address[]): 路径数组，**最后一个元素必须是 WETH**。
    - `to` (address): 接收 ETH 的地址。
    - `deadline` (uint): 截止时间。
- **返回值**：`uint[] memory amounts` – 路径上每一步的数量数组。

#### `swapETHForExactTokens(uint amountOut, address[] path, address to, uint deadline)`

- **功能**：用尽可能少的 ETH，换取精确数量的代币。
- **参数**：
    - `amountOut` (uint): 精确的输出代币数量。
    - `path` (address[]): 路径数组，**第一个元素必须是 WETH**。
    - `to` (address): 接收代币的地址。
    - `deadline` (uint): 截止时间。
    - `msg.value`: 发送的 ETH 数量。
- **返回值**：`uint[] memory amounts` – 路径上每一步的数量数组。

### 支持转账扣费代币

这些函数专门用于处理**转账时收取手续费**的代币（Fee-On-Transfer Tokens）。标准函数会因为实际到账金额与传入的 `amountIn` 不符而失败，这些函数通过查询实际余额变化来适配。

#### `swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] path, address to, uint deadline)`

- **功能**：与 `swapExactTokensForTokens` 相同，但能正确处理转账扣费代币。
- **参数**：同 `swapExactTokensForTokens`。
- **返回值**：无（不返回 `amounts`，因为实际到账金额可能变化）。

#### `swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] path, address to, uint deadline)`

- **功能**：与 `swapExactETHForTokens` 相同，但支持转账扣费代币。
- **参数**：同 `swapExactETHForTokens`。
- **返回值**：无。

#### `swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] path, address to, uint deadline)`

- **功能**：与 `swapExactTokensForETH` 相同，但支持转账扣费代币。
- **参数**：同 `swapExactTokensForETH`。
- **返回值**：无。

#### `removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline)`

- **功能**：与 `removeLiquidityETH` 相同，但支持转账扣费代币。
- **参数**：同 `removeLiquidityETH`。
- **返回值**：`uint amountETH` – 实际收到的 ETH 数量。