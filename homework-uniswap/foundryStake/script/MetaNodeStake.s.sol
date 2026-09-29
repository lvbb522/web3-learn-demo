// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MetaNodeStake} from "../src/MetaNodeStake.sol";
import {MetaNodeToken} from "../src/MetaNodeToken.sol";
import {TestERC20} from "../src/TestERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";

// 注意，部署合约中的msg.sender 是部署者，对应--private-key 中的地址
// MetaNodeToken metaNode = new MetaNodeToken();
// MetaNodeStake impl = new MetaNodeStake();
// ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
// 以上这种创建合约的方式，被创建合约的构造函数和init函数中的msg.sender 都是部署者
// 所以，部署合约时，需要使用--private-key 来指定部署者
// 测试合约中的msg.sender 是测试合约本身
contract MetaNodeStakeScript is Script {

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // 1. 部署奖励代币
        // vm.prank(admin);
        MetaNodeToken metaNode = new MetaNodeToken();

        // 2. 部署实现合约
        MetaNodeStake impl = new MetaNodeStake();

        // 3. 部署代理，调用 initialize
        bytes memory initData = abi.encodeWithSelector(
            MetaNodeStake.initialize.selector,
            IERC20(address(metaNode)),
            100,
            10_000_000,
            100
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        MetaNodeStake stake = MetaNodeStake(address(proxy));

        // 4. 把三种角色都授予 admin
        // bytes32 defaultAdminRole = stake.DEFAULT_ADMIN_ROLE();
        // bytes32 adminRole = stake.ADMIN_ROLE();
        // bytes32 upgradeRole = stake.UPGRADE_ROLE();

        // address admin = msg.sender;
        // stake.grantRole(defaultAdminRole, admin);
        // stake.grantRole(adminRole, admin);
        // stake.grantRole(upgradeRole, admin);

        // 5. 放弃部署者自己的角色（可选，推荐）
        // 注意：放弃 DEFAULT_ADMIN_ROLE 后，部署者就不能再管理角色了
        // 如果只想转交 ADMIN 和 UPGRADE，保留 DEFAULT_ADMIN_ROLE 也行
        // address deployer = msg.sender;
        // stake.renounceRole(adminRole, deployer);
        // stake.renounceRole(upgradeRole, deployer);

        // 6. 给 stake 合约打赏奖励代币
        metaNode.transfer(address(stake), 5_000_000 * 1e18);

        console.log(address(metaNode));
        console.log(address(impl));
        console.log(address(stake));

        // 6. 打印三个角色的持有情况
        bytes32 defaultAdminRole = stake.DEFAULT_ADMIN_ROLE();
        bytes32 adminRole = stake.ADMIN_ROLE();
        bytes32 upgradeRole = stake.UPGRADE_ROLE();

        console.log("DEFAULT_ADMIN_ROLE (bytes32):");
        console.logBytes32(defaultAdminRole);
        console.log("ADMIN_ROLE (bytes32):");
        console.logBytes32(adminRole);
        console.log("UPGRADE_ROLE (bytes32):");
        console.logBytes32(upgradeRole);

        address deployer = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        // 7. 验证 deployer 是否持有这三个角色
        console.log("deployer has DEFAULT_ADMIN_ROLE:", stake.hasRole(defaultAdminRole, deployer));
        console.log("deployer has ADMIN_ROLE:", stake.hasRole(adminRole, deployer));
        console.log("deployer has UPGRADE_ROLE:", stake.hasRole(upgradeRole, deployer));


        vm.stopBroadcast();
    }
}
