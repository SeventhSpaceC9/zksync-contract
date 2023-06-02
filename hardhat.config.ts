import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
const {alchemyGoerliKey,alchemyEthMainnetKey}=require("./secrets.json")
import "@matterlabs/hardhat-zksync-verify";

module.exports = {
    zksolc: {
        version: "1.3.10",
        compilerSource: "binary",
        settings: {},
    },
    // defaultNetwork: "zkSyncTestnet",
    defaultNetwork: "zkSyncMainnet",

    networks: {
        zkSyncTestnet: {
            url: "https://testnet.era.zksync.dev",
            ethNetwork: "https://eth-goerli.g.alchemy.com/v2/" + alchemyGoerliKey, // RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
            zksync: true,
            verifyURL: 'https://zksync2-testnet-explorer.zksync.dev/contract_verification'
        },
        zkSyncMainnet: {
            url: "https://mainnet.era.zksync.io",
            ethNetwork: "https://eth-mainnet.g.alchemy.com/v2/" + alchemyEthMainnetKey, // RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
            zksync: true,
            verifyURL: 'https://zksync2-mainnet-explorer.zksync.io/contract_verification'
        },
    },
    solidity: {
        version: "0.8.8",
    },
};
