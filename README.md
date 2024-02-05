# NFTMintProxyContract


1. 批量创建NFT
```json
function batchMintNFT(
        address[] calldata nftcontract,
        address[] calldata receivers,
        uint256[] calldata amounts
    )
```
- 批量创建NFT时，需要指定NFT合约地址
- 批量创建NFT时，需要指定NFT接收方地址
- 批量创建NFT时，需要指定mint的个数

2. 调用示例
```golang
func BatchMint(nftcallercontract string, nftcontracts, receivers []common.Address, nftids []*big.Int, gaslimit uint64) {
	instance := nftcallerinstance(nftcallercontract)
	auth := gentx(gaslimit)
	tx, err := instance.BatchMintNFT(auth, nftcontracts, receivers, nftids)
	if err != nil {
		log.Fatalf("error creating nftcallerinstance :%v", err)
	}
	fmt.Printf("tx sent: %s", tx.Hash().Hex())
}
```

3. NFTCaller合约部署：
```solidity
    constructor(address _owner, address _miner) payable {
        owner = _owner;
        miner = _miner;
    }
```
- 指定Owner地址：更新Owner、Miner地址
- 指定Miner地址: 执行 batchMint函数

4. NFT 合约部署
```solidity
  constructor(
        string memory name,
        string memory symbol,
        string memory _baseurl,
        address _nftcaller
    ) 
```
- NFT的 名称
- NFT的 符号缩写
- NFT的 元数据的baseurl
- NFT的 NFTCaller合约地址
- Owner为部署合约的地址：更新Owner地址、baseurl、NFTCaller合约地址、mint

5. 示例

NFT 合约：
```json
合约地址：0x73d8Fe8ad74Ba147928b66147B43273fc02a74Ac 
Owner: 0xDEE9bA27F961446D90E00b87BDcEfe79142CA760 
```

NFT Caller 合约：
```json
合约地址：0x01a16eA07DC701D7dFFC83a87A500Af1A3322B83 
Owner: 0xDEE9bA27F961446D90E00b87BDcEfe79142CA760
Miner: 0xDEE9bA27F961446D90E00b87BDcEfe79142CA760  
```


Miner地址 调用NFTCaller合约，执行 batchMint 函数: MINT 1 个 NFT到地址：0xf5fBB766074124A574fc9aFaF9c9f139e7efB981：
```golang
nftcallercontract := "0x01a16eA07DC701D7dFFC83a87A500Af1A3322B83"
	nftcontracts := []common.Address{common.HexToAddress("0x73d8Fe8ad74Ba147928b66147B43273fc02a74Ac")}
	receivers := []common.Address{common.HexToAddress("0xf5fBB766074124A574fc9aFaF9c9f139e7efB981")}
	mintamounts := []*big.Int{big.NewInt(int64(1))}
    transactions.BatchMint(nftcallercontract, nftcontracts, receivers, mintamounts, uint64(3000000))
```

```json
https://explorer.testnet.immutable.com/tx/0xd3a69a6ada82af087101b5b897e7c1d9a6d436876fd05329867474f40179a676
```
