package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"

	"myproject03/count"
)

func main() {
	// 1. 连接以太坊节点（使用本地 Hardhat 节点）
	client, err := ethclient.Dial("https://eth-sepolia.g.alchemy.com/v2/alch_MmZSIhgmcZmAssbQj3IzU")
	if err != nil {
		log.Fatalf("连接节点失败: %v", err)
	}
	defer client.Close()

	// 2. 准备私钥（Hardhat 默认的第一个账户）
	privateKey, err := crypto.HexToECDSA("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
	if err != nil {
		log.Fatalf("解析私钥失败: %v", err)
	}

	// 3. 获取 ChainID
	chainID, err := client.ChainID(context.Background())
	if err != nil {
		log.Fatalf("获取 ChainID 失败: %v", err)
	}
	fmt.Printf("Chain ID: %s\n", chainID.String())

	// 4. 创建授权对象
	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		log.Fatalf("创建授权失败: %v", err)
	}

	// 设置 Gas 参数（可选）
	auth.GasLimit = uint64(300000)
	auth.GasPrice, err = client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Printf("获取 Gas 价格失败: %v，使用默认值", err)
		auth.GasPrice = big.NewInt(1000000000) // 1 Gwei
	}

	// 获取发送地址
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("无法获取公钥")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	fmt.Printf("发送地址: %s\n", fromAddress.Hex())

	// 获取账户余额
	balance, err := client.BalanceAt(context.Background(), fromAddress, nil)
	if err != nil {
		log.Printf("获取余额失败: %v", err)
	} else {
		fmt.Printf("账户余额: %s ETH\n", balance.String())
	}

	fmt.Println("\n========== 开始部署合约 ==========")

	// 5. 部署合约
	address, tx, instance, err := count.DeployCount(auth, client)
	if err != nil {
		log.Fatalf("部署合约失败: %v", err)
	}

	fmt.Printf("   合约部署交易已发送\n")
	fmt.Printf("   交易哈希: %s\n", tx.Hash().Hex())
	fmt.Printf("   合约地址: %s\n", address.Hex())

	// 6. 等待部署交易被确认
	fmt.Println("   等待交易确认...")
	receipt, err := waitForReceipt(client, tx)
	if err != nil {
		log.Fatalf("等待交易确认失败: %v", err)
	}
	fmt.Printf("  部署成功！区块号: %d\n", receipt.BlockNumber)

	fmt.Println("\n========== 开始调用合约方法 ==========")

	// 7. 读取初始值
	count, err := instance.GetCount(nil)
	if err != nil {
		log.Fatalf("读取计数失败: %v", err)
	}
	fmt.Printf("📊 当前计数: %d\n", count)

	// 8. 第一次加一
	fmt.Println("\n 执行第一次加一...")
	tx, err = instance.Increment(auth)
	if err != nil {
		log.Fatalf("加一失败: %v", err)
	}
	fmt.Printf("   交易哈希: %s\n", tx.Hash().Hex())

	// 等待交易确认
	receipt, err = waitForReceipt(client, tx)
	if err != nil {
		log.Fatalf("等待交易确认失败: %v", err)
	}
	fmt.Printf(" 交易确认，区块号: %d\n", receipt.BlockNumber)

	// 读取第一次加一后的值
	count, err = instance.GetCount(nil)
	if err != nil {
		log.Fatalf("读取计数失败: %v", err)
	}
	fmt.Printf(" 第一次加一后: %d\n", count)

	// 9. 第二次加一
	fmt.Println("\n 执行第二次加一...")
	tx, err = instance.Increment(auth)
	if err != nil {
		log.Fatalf("加一失败: %v", err)
	}
	fmt.Printf("   交易哈希: %s\n", tx.Hash().Hex())

	// 等待交易确认
	receipt, err = waitForReceipt(client, tx)
	if err != nil {
		log.Fatalf("等待交易确认失败: %v", err)
	}
	fmt.Printf(" 交易确认，区块号: %d\n", receipt.BlockNumber)

	// 10. 读取最终值
	count, err = instance.GetCount(nil)
	if err != nil {
		log.Fatalf("读取计数失败: %v", err)
	}
	fmt.Printf(" 第二次加一后: %d\n", count)

	fmt.Println("\n========== 执行完成 ==========")
	fmt.Printf(" 合约地址: %s\n", address.Hex())
	fmt.Printf(" 最终计数: %d\n", count)
}

// waitForReceipt 等待交易确认
func waitForReceipt(client *ethclient.Client, tx *types.Transaction) (*types.Receipt, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	for {
		select {
		case <-ctx.Done():
			return nil, fmt.Errorf("等待交易确认超时")
		default:
			receipt, err := client.TransactionReceipt(ctx, tx.Hash())
			if err != nil {
				// 如果交易还没被打包，继续等待
				if err.Error() == "not found" {
					time.Sleep(1 * time.Second)
					continue
				}
				return nil, err
			}
			if receipt != nil {
				return receipt, nil
			}
			time.Sleep(1 * time.Second)
		}
	}
}
