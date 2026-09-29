# ERC20

ERC-20 是以太坊上最基础、使用最广泛的**同质化代币标准**(“同质化”意味着每个代币在类型和价值上**完全相同且可互换**)。它定义了一套统一的接口，让所有遵循该标准的代币（如 USDC、DAI、UNI）都能被钱包、交易所和 DeFi 协议以相同方式处理。

### 核心接口与功能

一个智能合约只要实现了以下方法和事件，就可以被称为 ERC-20 代币合约。

**方法（Methods）**

- **`totalSupply()`**：返回代币的总供应量。
- **`balanceOf(address)`**：查询某个地址持有的代币余额。
- **`transfer(address, uint256)`**：将代币从调用者账户转给接收者。
- **`approve(address, uint256)`**：授权第三方地址可以动用你账户中的一定数量的代币。
- **`allowance(address, address)`**：查询某个地址还被允许动用另一个地址多少代币。
- **`transferFrom(address, address, uint256)`**：使用授权机制，由第三方代表你进行转账。
- **`name()` / `symbol()` / `decimals()`**：返回代币名称、符号和小数位数（可选，但通常实现）。

**事件（Events）**

- **`Transfer`**：代币发生转移时触发。
- **`Approval`**：成功调用 `approve` 时触发。

### 核心概念：授权机制

ERC-20 的 `approve` 和 `transferFrom` 设计了一套**授权模式**。代币持有者可以授权某个智能合约（如去中心化交易所）动用自己账户中一定数量的代币。这样，当用户在交易所卖出代币时，交易所就能通过 `transferFrom` 直接从用户钱包扣款，而无需用户每次手动转账。这是 DeFi 应用的基础运行机制。

#  EIP-712 和 ERC-2612

ERC-2612 和 EIP-712 经常被一起提及，因为前者是后者的一个经典应用案例。EIP-712 提供了一套通用的“结构化数据签名”标准，而 ERC-2612 则利用这套标准，为 ERC-20 代币实现了无需 Gas 费的授权（Permit）。

**EIP-712** 解决的是“**签什么**”的问题，让签名内容变得清晰、安全、可验证；**ERC-2612** 则解决了“**怎么用签名**”的问题，将链上授权转变为链下签名，实现了更流畅、更低成本的用户体验。

## EIP-712：让签名变得可读且安全

EIP-712 的核心目标是解决传统签名（`eth_sign`）的问题。传统的签名方法只是对一串没有结构的字节进行签名，用户在钱包里只能看到一串乱码，无法知道签名的具体内容，存在严重的安全隐患。

EIP-712 引入了**结构化数据（Typed Structured Data）** 的概念。它要求被签名的数据必须遵循一个预先定义好的结构，这个结构包含两部分：

1. **类型定义（Types）**：明确消息里有哪些字段，以及每个字段的数据类型（如 `address`、`uint256`、`string` 等）。这就像是一个数据的“蓝图”。
2. **域分隔符（Domain Separator）**：这是一个用来防止签名在不同应用或不同链之间被重放攻击的机制。它通常包含 `name`（应用名称）、`version`、`chainId`（链 ID）和 `verifyingContract`（验证签名的合约地址）等信息。因为有了这个域，即便两个 DApp 定义了完全相同的消息结构，它们的签名也无法互相通用。

当钱包收到一个 EIP-712 签名请求时，它能够解析出结构化的信息，并以人类可读的方式展示给用户，例如“你正在授权 100 个 USDC 给 Uniswap”。这大大提升了签名的透明度和安全性。

## ERC-2612：为 ERC-20 带来“无 Gas 授权”

ERC-2612 是一个专门针对 ERC-20 代币的扩展标准。它利用 EIP-712 的签名能力，增加了一个名为 `permit` 的新函数，从而解决了传统授权流程的痛点。

**传统授权的问题**：在 ERC-2612 出现之前，如果你想使用一个 DeFi 应用（比如兑换代币），你通常需要先发送一笔 `approve` 交易，授权该应用动用你的代币，这笔交易需要你支付 Gas 费。然后你再发送第二笔交易来执行兑换操作，又需要支付一次 Gas 费。这是一个两步操作，用户体验不佳。

**`permit` 的工作方式**：

1. **链下签名**：你在 DApp 中发起操作，DApp 会生成一个符合 EIP-712 格式的授权消息（包含 `owner`、`spender`、`value`、`nonce` 和 `deadline` 等字段）。你只需在钱包里对这个消息签名，**无需支付 Gas 费**。
2. **链上提交**：DApp 或任何第三方（称为中继者 Relayer）可以拿着你的签名，在链上调用代币合约的 `permit` 函数。这个函数会验证签名的有效性，并直接设置好授权额度。
3. **合并操作**：最妙的是，`permit` 通常可以和 DApp 的实际操作（如兑换）在**同一笔交易**中完成。这样一来，你原本需要两步的操作，现在只需要一步，并且 Gas 费可以由 DApp 来支付（或者你只需为最终的操作支付一次）。

# ERC-721

ERC-721 与 ERC-20 最根本的区别在于“非同质化”。ERC-20 代币之间完全相同，而 ERC-721 的每个代币都是独一无二的。

这个唯一性由一个名为 `tokenId` 的 `uint256` 变量承载。对于任何 ERC-721 合约，**合约地址与 `tokenId` 的组合在全网范围内唯一确定一个 NFT**。这意味着，虽然一个合约可以管理成千上万个 NFT，但每一个都可以被独立地识别、追踪和转移。标准本身也考虑到了 NFT 可能代表的广泛资产类型，从实体房产、独特艺术品，到虚拟收藏品（如加密猫），甚至“负价值”资产（如贷款或责任）。

### 标准接口

一个合约要实现 ERC-721 标准，必须实现以下方法和事件。

**核心方法：**

- **`balanceOf(address _owner)`**：查询某地址持有的 NFT 数量
- **`ownerOf(uint256 _tokenId)`**：查询某个 NFT 的当前所有者
- **`transferFrom(address _from, address _to, uint256 _tokenId)`**：转移 NFT 所有权（调用者需自行确认接收方能否处理 NFT）
- **`safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data)`**：安全转移 NFT，若接收方是合约，会检查其是否实现了接收接口
- **`safeTransferFrom(address _from, address _to, uint256 _tokenId)`**：同上，但不携带额外数据
- **`approve(address _approved, uint256 _tokenId)`**：授权某个地址操作特定的 NFT
- **`setApprovalForAll(address _operator, bool _approved)`**：授权或取消授权某个地址操作自己的全部 NFT
- **`getApproved(uint256 _tokenId)`**：查询某个 NFT 被授权的地址
- **`isApprovedForAll(address _owner, address _operator)`**：查询某地址是否被授权操作另一地址的全部 NFT

**必须触发的事件：**

- **`Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId)`**：NFT 所有权转移时
- **`Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId)`**：授权某个 NFT 时
- **`ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved)`**：授权或取消授权全部 NFT 时

### 关键机制：安全转账与授权

**`safeTransferFrom` 与 `transferFrom` 的区别**是 ERC-721 设计中一个重要的安全考量。`transferFrom` 直接将 NFT 发送到目标地址，调用者需要自行确认接收方能够处理 NFT，否则代币可能永久丢失。而 `safeTransferFrom` 在完成转移后，会检查接收方是否为合约（代码大小 > 0），如果是，则调用其 `onERC721Received` 函数，并验证返回值是否正确。如果验证失败，交易将回滚。

**授权机制**则支持两种模式：一是针对单个 NFT 的授权（`approve`），适合将某个特定资产委托给他人管理；二是针对全部资产的授权（`setApprovalForAll`），这是 NFT 市场（如 OpenSea）的标准做法，用户只需授权一次，市场合约即可代理转移其名下的任何 NFT。

# ERC-1155

ERC-1155 是一个**多代币标准**，它的核心设计目标是用**一个智能合约**管理**任意数量**的代币类型——无论是同质化代币、非同质化代币，还是介于两者之间的半同质化代币。

ERC-1155 引入了一个关键概念：**代币 ID**。与 ERC-721 中每个 NFT 拥有唯一 ID 类似，ERC-1155 也用 `uint256` 类型的 `id` 来区分不同的代币类型。但区别在于，ERC-1155 允许**同一个 `id` 拥有多个副本**，其数量由余额映射决定。

如果某个 `id` 的供应量仅为 1，它就可以被当作 NFT 使用；如果供应量大于 1，它则表现为同质化代币。这使得 ERC-1155 能够灵活地在一个合约中同时代表游戏金币（FT）、限量皮肤（NFT）和普通道具（半同质化代币）。ERC-1155 被广泛认为是**游戏和元宇宙场景的“黄金标准”**

### 核心接口

ERC-1155 的接口设计围绕“批量”和“安全”展开，必须实现以下方法：

**批量操作（核心优势）**

|方法|功能说明|
|---|---|
|`safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data)`|在**单次交易**中批量转移多种代币|
|`balanceOfBatch(address[] _owners, uint256[] _ids)`|在**单次调用**中批量查询多个余额|

**单笔操作与授权**

|方法|功能说明|
|---|---|
|`safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data)`|转移单一类型的代币|
|`balanceOf(address _owner, uint256 _id)`|查询某地址持有某 `id` 代币的数量|
|`setApprovalForAll(address _operator, bool _approved)`|授权或取消授权操作员管理**全部**代币|
|`isApprovedForAll(address _owner, address _operator)`|查询授权状态|

**必须触发的事件**：`TransferSingle`（单笔转移）、`TransferBatch`（批量转移）、`ApprovalForAll`（授权）、`URI`（元数据更新）。

### 关键机制

**批量转账的效率优势**是 ERC-1155 最显著的改进。假设用户需要转移 100 个 ID 为 3 的代币、200 个 ID 为 6 的代币和 5 个 ID 为 13 的代币，在 ERC-721 或 ERC-20 中可能需要多笔交易，而在 ERC-1155 中只需一次 `safeBatchTransferFrom` 调用。

**安全的接收钩子**与 ERC-721 类似但更复杂。ERC-1155 定义了 `onERC1155Received` 和 `onERC1155BatchReceived` 两个回调函数。当 `safeTransferFrom` 或 `safeBatchTransferFrom` 将代币发送到合约地址时，合约必须实现并返回正确的魔术值（分别是 `0x150b7a02` 和 `0x4e2312e0`），否则交易将回滚，防止代币被永久锁定。

**授权机制的简化**则是一个明显的权衡。ERC-1155 的 `setApprovalForAll` 只能授权操作员管理**全部**代币，无法像 ERC-20 那样指定授权数量，也无法像 ERC-721 那样针对特定 `tokenId` 授权。这意味着一旦授权，操作员理论上可以转移用户在该合约中拥有的任何资产。

# ERC-165

ERC-165 是一个**元标准**，用于让智能合约公开声明自己实现了哪些接口。它本身不定义任何资产或功能，而是为其他标准（如 ERC-721、ERC-1155）提供一套“接口自检”机制。

### 核心设计：接口标识符

在 ERC-165 出现之前，外部调用者只能“尝试”调用某个函数，失败则推断不支持，这种方法不可靠。ERC-165 将“接口”定义为一组**函数选择器**的集合)。

接口标识符（`interfaceID`）的计算方式是：对该接口中所有函数选择器进行**异或（XOR）** 运算，结果取前 4 个字节（`bytes4`）。例如，ERC-165 自身的 `interfaceID` 是 `0x01ffc9a7`，计算方式为 `bytes4(keccak256('supportsInterface(bytes4)'))`。在 Solidity 中，可以直接用 `type(IERC165).interfaceId` 获取。

### 核心接口

一个符合 ERC-165 的合约必须实现以下函数：

**function supportsInterface(bytes4 interfaceID) external view returns (bool);**

该函数的行为规则：

- 当 `interfaceID` 为 `0x01ffc9a7` 时，返回 `true`（表示支持 ERC-165 本身）
- 当 `interfaceID` 为 `0xffffffff` 时，返回 `false`（这是一个无效标识符的哨兵值）
- 对于合约实际实现的其他接口，返回 `true`

### 检测机制

要检测一个合约是否实现了 ERC-165，标准规定了严格的流程：

1. 调用 `supportsInterface(0x01ffc9a7)`。如果失败或返回 `false`，则目标合约**未实现** ERC-165。
2. 如果返回 `true`，再调用 `supportsInterface(0xffffffff)`。如果这次返回 `true` 或调用失败，则目标合约**未实现** ERC-165（这是一个逻辑自洽性检查，防止合约错误地声明一切）。
3. 只有第一步返回 `true` 且第二步返回 `false`，才能确认目标合约**实现了** ERC-165。

确认合约支持 ERC-165 后，就可以直接调用 `supportsInterface(目标接口ID)` 来判断它是否支持你需要的接口。

# ERC-2981

ERC-2981 是一个**版税信息查询标准**，它本身**不强制执行支付**，只负责让市场能够“问”一个 NFT：“如果卖掉，版税该付给谁、付多少？” 是否真的支付，完全取决于市场自己的政策。

### 核心设计：只回答，不执行

ERC-2981 的定位非常克制。它定义了一个单一函数，任何合约（不限于 ERC-721/1155）都可以实现它，让外部调用者查询版税信息。标准的设计初衷是提供一个**最小化、gas 高效的构建块**，把“支付与否”的问题留给市场生态去博弈。

### 唯一的核心函数

标准只要求实现一个函数：
**function royaltyInfo(uint256 tokenId, uint256 salePrice)  external view returns (address receiver, uint256 royaltyAmount);**

**输入**：`tokenId`（哪个 NFT）和 `salePrice`（成交价）。  
**输出**：`receiver`（版税收款地址）和 `royaltyAmount`（版税金额）。

# ERC-1271

ERC-1271 是一个让**智能合约能够验证签名**的标准。它的核心逻辑非常朴素：既然合约没有私钥，无法像普通钱包那样“签名”，那就让合约自己来判断一个签名是否有效。

以太坊上有两类账户。**外部账户（EOA）** 由私钥控制，可以用私钥对消息签名，任何人都能通过 `ecrecover` 验证。但**智能合约账户**没有私钥，无法生成传统签名。

这带来了一个实际障碍：许多 DeFi 应用依赖“链下签名 + 链上验证”的模式（比如去中心化交易所的订单簿）。如果只支持 EOA，那么智能合约钱包（如多签钱包、Argent、Safe）就无法参与这些应用。

ERC-1271 的解决方案是：**不问“谁签的”，而是问合约“这个签名有效吗”**。

### 核心接口

标准只定义了一个函数：
**function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);**

调用者传入待验证消息的哈希 `_hash` 和签名数据 `_signature`，合约根据自己的逻辑判断签名是否有效。有效时，必须返回魔术值 **`0x1626ba7e`**，任何其他返回值（或调用失败）都视为无效。

函数被标记为 `view`，**不能修改状态**。这是为了防止 Gas 代币铸造等攻击向量。

# ERC-4626

ERC-4626 是一个**代币化生息金库（Tokenized Vault）的标准**，它本身是一个扩展了 ERC-20 的标准，让金库的“份额”变成了可自由转让的 ERC-20 代币。

### 核心逻辑：用 ERC-20 代表金库份额

在 ERC-4626 之前，每个 DeFi 收益聚合器（如 Yearn、Convex）都有自己的一套存取逻辑，集成方（如其他协议或聚合器）需要为每个金库单独写适配器，容易出错且浪费资源。

ERC-4626 的解法很直接：**让金库本身就是一个 ERC-20 合约**。你把基础资产（比如 USDC）存入金库，金库会给你铸造一定数量的“份额代币”（share）。这些份额代币本身就是标准的 ERC-20，可以转让、可以再抵押、可以被其他协议识别。

标准里区分了两个核心概念：

- **asset（资产）**：你存入的基础 ERC-20 代币，比如 USDC。
- **share（份额）**：金库发给你的凭证代币，代表你对金库资产的一部分所有权。随着金库产生收益，`totalAssets` 增加，每份 share 能换回的 asset 就变多了。

### 核心接口：四个“存取”函数

标准定义了四个主要的写操作，分成两组对称的设计：

|函数|输入|行为|
|---|---|---|
|`deposit(assets, receiver)`|指定存入多少 **资产**|存入 `assets`，给 `receiver` 铸造对应的份额|
|`mint(shares, receiver)`|指定要获得多少 **份额**|计算需要多少资产，存入并铸造精确的 `shares`|
|`withdraw(assets, receiver, owner)`|指定要取出多少 **资产**|销毁 `owner` 的份额，给 `receiver` 转出精确的 `assets`|
|`redeem(shares, receiver, owner)`|指定要销毁多少 **份额**|销毁精确的 `shares`，给 `receiver` 转出对应的资产|

每个操作都有对应的 `preview` 函数（如 `previewDeposit`）来模拟结果，以及 `max` 函数（如 `maxDeposit`）来查询当前允许的最大操作量。

# ERC-4337

ERC-4337 是以太坊账户抽象（Account Abstraction）的**应用层标准**。它的核心思路是：不修改以太坊底层协议，而是引入一套全新的交易对象和处理流程，让智能合约钱包能够像普通钱包一样“主动”发起交易。

传统以太坊账户（EOA）由单一私钥控制，存在几个根本性限制：丢失私钥等于失去一切，无法定制安全规则（如多签、社交恢复），每笔交易必须持有 ETH 支付 Gas，且多步操作（如授权+兑换）需要分开发送交易。ERC-4337 的目标就是让账户变得“可编程”。

### 四个核心角色

ERC-4337 把一笔交易拆解成由多个角色协作完成的过程：

**UserOperation（用户操作）**：这是一种全新的“伪交易”对象，描述用户想要执行的动作。它与普通交易的关键区别在于：用户签名的对象是 UserOperation，而不是以太坊交易，签名方案完全由智能账户自己决定（可以是 ECDSA、多签、Passkey 等）。UserOperation 被发送到一个**独立的 mempool**（称为 alt-mempool），与普通交易的内存池分开。

**Bundler（打包者）**：负责从 alt-mempool 中收集 UserOperation，模拟验证其合法性（签名、余额、Gas 等），然后将一批有效的 UserOperation 打包成**一笔真正的以太坊交易**，提交到链上。Bundler 承担 Gas 成本风险，但会从用户或 Paymaster 那里获得补偿。

**EntryPoint（入口点合约）**：链上的核心协调者，是一个**单例合约**（每个链上每个版本只有一个）。当 Bundler 提交打包后的交易时，它调用 EntryPoint 的 `handleOps` 函数。EntryPoint 会遍历每个 UserOperation，先调用用户智能账户的 `validateUserOp` 进行验证，验证通过后再执行用户指定的实际操作。

**Paymaster（代付合约，可选）**：允许第三方代替用户支付 Gas 费，或让用户用 ERC-20 代币（如 USDC）支付 Gas。Paymaster 需要在 EntryPoint 中质押 ETH 并存入资金，EntryPoint 在验证阶段会调用 Paymaster 的 `validatePaymasterUserOp` 来确认它是否愿意为这笔操作买单。

### 一笔交易的完整流程

1. **构建与签名**：用户钱包构建 UserOperation，调用 Bundler 的 `eth_estimateUserOperationGas` 估算 Gas，然后用户用自己的方式签名。
2. **提交**：签名的 UserOperation 通过 `eth_sendUserOperation` 发送到 Bundler 的 mempool。
3. **模拟与打包**：Bundler 在本地模拟验证 UserOperation，确认无误后，将多个操作打包成一笔交易，调用 EntryPoint 的 `handleOps` 提交上链。
4. **链上验证与执行**：EntryPoint 先调用智能账户的 `validateUserOp`（验证签名、Nonce 等），如果指定了 Paymaster，再验证 Paymaster 的支付意愿，最后执行用户的实际操作（`callData`）。
5. **结算**：EntryPoint 从用户账户或 Paymaster 的存款中扣除 Gas 费，补偿给 Bundler。

# EIP-7702

EIP-7702 是 Pectra 硬分叉中引入的一项**协议层提案**，它允许传统的外部拥有账户（EOA）在**不改变地址、不部署新合约**的前提下，临时“借用”一个已部署智能合约的代码来执行逻辑。

### 核心机制：授权列表与代码委托

EIP-7702 引入了一种新的交易类型（Type 4），交易中携带一个**授权列表（Authorization List）**。列表中的每个授权项是一个签名元组：`[chain_id, address, nonce, y_parity, r, s]`。

当交易被执行时，如果签名有效，EOA 的代码槽会被写入一个**委托指示符**：`0xef0100 || 委托合约地址`。此后，任何对该 EOA 的调用，都会在 EOA 自己的存储、余额和身份上下文中，执行委托合约的代码。

这种委托是**持久的**，会一直持续到用户发送另一笔 Type 4 交易，将委托更新到新地址或指向零地址来清除。

### 与 ERC-4337 的关系：互补而非替代

EIP-7702 和 ERC-4337 经常被放在一起讨论，但它们解决的是不同层面的问题。

ERC-4337 是**应用层**方案，需要 Bundler、EntryPoint、Paymaster 一整套独立基础设施，用户操作的是 UserOperation。EIP-7702 是**协议层**方案，让 EOA 直接获得智能合约的能力，无需额外部署账户合约。

以太坊官方建议，EIP-7702 的委托合约最好**兼容或符合 ERC-4337**。这样，EOA 可以通过 ERC-4337 的 Bundler 来提交操作，获得 Gas 代付和抗审查的好处，同时利用 EIP-7702 避免额外的账户部署成本。两者组合可以实现更完整的账户抽象体验。

# ERC-8004

ERC-8004 是一个为 AI Agent 设计的**链上信任基础设施标准**。它的核心目标很明确：让 AI Agent 在**没有中心化中介**的情况下，能够相互发现、验证身份、并基于可验证的信誉记录来决定是否信任对方。

### 要解决的核心问题

AI Agent 之间已经可以通信（如 Google 的 A2A 协议）和调用工具（如 Anthropic 的 MCP），但它们缺少一个根本性的能力：**判断“对方是谁、是否可靠”**。在一个开放网络中，一个全新的 Agent 和一个经过验证的 Agent 从表面看没有区别。ERC-8004 就是为这个问题提供链上答案。

### 三个核心注册表

ERC-8004 通过三个轻量级链上注册表来标准化信任的建立过程：

**身份注册表（Identity Registry）**：每个 AI Agent 被铸造为一个 **ERC-721 代币**，获得一个唯一的 `agentId`。代币的 `tokenURI` 指向一个注册文件（通常托管在 IPFS 或 HTTPS），描述 Agent 的名称、能力、服务端点（如 A2A、MCP、ENS）和支持的信任模型。这个身份是**可移植、抗审查**的，不绑定于任何单一平台。

**信誉注册表（Reputation Registry）**：任何与 Agent 交互过的地址都可以提交反馈，形式是一个**带符号的数字评分**（`int128`）加小数位数。反馈可以附带标签（如 `uptime`、`responseTime`）以及指向链下详细评价的 URI 和哈希。注册表只存储**原始信号**，不计算一个“官方总分”——不同的消费者可以根据自己的标准去解释这些数据。

**验证注册表（Validation Registry）**：这是为**高风险任务**准备的。Agent 可以请求独立的验证者对特定工作进行核查，验证者返回 0-100 的评分和链上证据哈希。验证的具体方式由验证者自行决定：可以是**质押后重跑任务**、**TEE（可信执行环境）证明**，或 **zkML（零知识机器学习证明）**。

# ERC-8183

ERC-8183 是一个为 AI Agent 之间**有条件结算**设计的以太坊标准。它由 Virtuals Protocol 与以太坊基金会 dAI 团队联合提出，核心目标是在没有中心化平台的情况下，让两个互不信任的 Agent 完成“雇佣—交付—结算”的完整流程。

### 要解决的核心问题

当 Agent A 想雇佣 Agent B 完成一项任务时，双方面临经典的信任困境：A 先付款，B 可能不交付合格结果；B 先干活，A 可能拒付。传统互联网用平台（如淘宝）充当托管和仲裁者，但在 Agent 经济中，平台意味着单点故障和规则操纵风险。ERC-8183 的解法是把“平台”抽象为链上智能合约，让托管和结算规则由代码中立执行。

### 核心原语：Job（任务）

ERC-8183 只定义了一个核心对象：**Job**。每个 Job 代表一笔完整的商业交易，涉及三个角色：

- **Client（客户）**：发布任务并注入资金的一方。
- **Provider（服务商）**：执行任务并提交交付物的一方。
- **Evaluator（评估者）**：判断任务是否完成、决定资金归属的一方。这是标准最核心的设计。

### Job 的生命周期

Job 的状态流转非常清晰，全程由智能合约托管资金：

1. **Open**：Client 创建 Job，明确任务要求。
2. **Funded**：Client 将资金（报酬 + 小费）存入合约托管，资金不直接给 Provider。
3. **Submitted**：Provider 完成任务，将交付物（或其哈希/引用）上链提交。
4. **Terminal**：Evaluator 审核后做出最终裁决。若确认合格，调用 `complete`，资金释放给 Provider；若拒绝，调用 `reject`，资金退还 Client。若超时无人行动，Job 过期，资金退回 Client。

### Evaluator：可编程的“裁判”

Evaluator 的引入让 ERC-8183 能适配不同任务类型。协议层只关心“哪个地址调用了 complete 或 reject”，不关心这个地址背后是什么：

- **主观任务**（写作、设计）：Evaluator 可以是一个 AI Agent，读取交付物并与要求比对。
- **确定性任务**（计算、证明）：Evaluator 可以是一个封装 ZK 验证器的合约，链上自动验证证明。
- **高风险任务**：Evaluator 可以是多签钱包、DAO 或质押支持的验证集群。

### Hooks：模块化扩展

Job 原语刻意保持极简，复杂商业逻辑通过 **Hooks** 实现。Hook 是创建 Job 时可附加的可选合约，能在生命周期各阶段前后执行自定义逻辑。例如：竞价机制、基于 ERC-8004 的信誉门槛、资金兑换策略、隐私保护等。

# x402

x402 是一个将支付能力直接嵌入 HTTP 请求流程的开放协议。它的核心思路很简洁：**重新激活 HTTP 协议中早已预留但长期未被使用的 `402 Payment Required` 状态码**，让“请求资源”和“完成支付”在同一交互中同步发生。

### 要解决什么问题

传统互联网支付依赖 API Key、账户注册、信用卡绑定等人工介入的流程。当 AI Agent 需要自主调用付费 API 或购买数据时，这些流程成了根本障碍。x402 的目标是让支付变得像发送 HTTP 请求一样自然——**无需账户、无需 API Key，程序可以直接为资源付费**。

### 一笔支付的完整流程

x402 的交互设计得尽量轻量：

1. **请求资源**：客户端向资源服务器发起 HTTP 请求。
2. **收到 402**：如果资源需要付费，服务器返回 `402 Payment Required`，并在 `PAYMENT-REQUIRED` 头中附带支付要求（金额、网络、收款地址等）。
3. **构造支付负载**：客户端选择一种支付方式，构造 `PaymentPayload`，通过 `PAYMENT-SIGNATURE` 头重新发送请求。
4. **验证与结算**：资源服务器将支付负载交给 **Facilitator** 验证。Facilitator 在链上完成结算，将确认结果返回给服务器。
5. **返回资源**：验证通过后，服务器返回 `200 OK` 和用户请求的资源。

这里的关键角色 **Facilitator** 是一个负责链上验证和结算的服务，资源服务器无需自己维护区块链基础设施。

### 关键概念

x402 的设计是**网络、代币、货币无关**的。它通过“方案（Scheme）”和“网络（Network）”的组合来支持不同的支付方式。

- **方案（Scheme）**：定义“资金如何流动”的逻辑。最初的 `exact` 方案用于精确金额的一次性支付；后续还出现了 `upto`（按实际用量计费）和 `batch-settlement`（批量结算，适合大量微支付）。
- **网络（Network）**：支持 EVM 链（如 Base、Polygon、Arbitrum）和 Solana。网络标识使用 CAIP-2 标准（如 `eip155:8453` 代表 Base）。
- **支付资产**：支持任意 ERC-20 代币（通过 Permit2）和 SPL 代币。最顺畅的体验是使用支持 EIP-3009 的 USDC，因为它允许免 Gas 的签名授权转移。

### 生态与采用

x402 由 Coinbase 发起，**2026 年 4 月贡献给 Linux 基金会**，并成立了 x402 Foundation 进行开放治理。基金会成员包括 Visa、Mastercard、Stripe、Google、AWS、Cloudflare、Circle 等 40 家组织，覆盖支付、云和金融基础设施领域。

截至 2026 年中，x402 已处理**超过 2 亿笔交易**，Solana 承载了其中约 65% 的交易量。但一项分析指出，**超过 95% 的交易量是“协议信号”**（测试和自交易），真实的商业交易规模仍然很小，日均约 2.8 万美元。