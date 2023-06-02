# zksync合约 编写/编译/部署/验证
将要部署的sol合约放入`contracts`目录下，修改`deploy.ts`中的部署信息：
```js
//需要部署的合约
const artifact = await deployer.loadArtifact("VestingSEVS");
//构造参数
const args=["0xE8984D4A0d0a1863D29f8434d4492a9612013D6f",60 * 10, 60 *5]
```

网络参数在`hardhat.config.ts`中修改

编译:`yarn hardhat compile`

部署：`yarn hardhat deploy-zksync --network zkSyncTestnet`

验证：`yarn hardhat verify --network zkSyncTestnet 0x31405e08bDeF836cc3a0F1F68556FEEb2a61f78c 参数`

复杂参数用文件`yarn hardhat verify --network zkSyncTestnet 0x31405e08bDeF836cc3a0F1F68556FEEb2a61f78c  --constructor-args arguments.js`
