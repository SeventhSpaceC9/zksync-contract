import { Wallet, utils } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import {ProxyAgent, setGlobalDispatcher} from "undici";
const {privateKey}=require("../secrets.json")
const { ProxyAgent, setGlobalDispatcher } = require("undici")

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
    //====use http proxy
    const proxyAgent = new ProxyAgent("http://127.0.0.1:7890")
    setGlobalDispatcher(proxyAgent)

    console.log(`Running deploy script for the Greeter contract`);

    // Initialize the wallet.
    const wallet = new Wallet(privateKey);

    // Create deployer object and load the artifact of the contract you want to deploy.
    const deployer = new Deployer(hre, wallet);
    // const artifact = await deployer.loadArtifact("Greeter");
    // const artifact = await deployer.loadArtifact("IGGYCoin");
    const artifact = await deployer.loadArtifact("VestingSEVS");
    //construct arguments
    const args=["0xE8984D4A0d0a1863D29f8434d4492a9612013D6f",60 * 10, 60 *5]

    const deploymentFee = await deployer.estimateDeployFee(artifact,args);

    // // OPTIONAL: Deposit funds to L2
    // // Comment this block if you already have funds on zkSync.
    // const depositHandle = await deployer.zkWallet.deposit({
    //     to: deployer.zkWallet.address,
    //     token: utils.ETH_ADDRESS,
    //     amount: deploymentFee.mul(2),
    // });
    // // Wait until the deposit is processed on zkSync
    // await depositHandle.wait();

    // Deploy this contract. The returned object will be of a `Contract` type, similarly to ones in `ethers`.
    // `greeting` is an argument for contract constructor.
    const parsedFee = ethers.utils.formatEther(deploymentFee.toString());
    console.log(`The deployment is estimated to cost ${parsedFee} ETH`);

    // const greeterContract = await deployer.deploy(artifact, [greeting]);
    const contract = await deployer.deploy(artifact, args);

    //obtain the Constructor Arguments
    // console.log("constructor args:" + greeterContract.interface.encodeDeploy([greeting]));
    console.log("constructor args:" + contract.interface.encodeDeploy(args));

    // Show the contract info.
    const contractAddress = contract.address;
    console.log(`${artifact.contractName} was deployed to ${contractAddress}`);
}
