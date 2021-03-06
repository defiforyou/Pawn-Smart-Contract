require('@nomiclabs/hardhat-ethers');

const hre = require('hardhat');
const { PawnConfig } = require('./.deployment_data.json');

const PawnBuildName     = "contracts/pawn/pawn-p2p/PawnContract.sol:PawnContract";
const ProxyBuildName    = "AdminUpgradeabilityProxy";
const ProxyData         = "0x";
const RepuBuildName     = "contracts/pawn/reputation/Reputation.sol:Reputation";
const NFTBuildName      = "contracts/pawn/nft/DFY_Physical_NFTs.sol:DFY_Physical_NFTs";
const EvaBuildName      = "contracts/pawn/evaluation/EvaluationContract.sol:AssetEvaluation";
const PawnNFTBuildName  = "contracts/pawn/pawn-nft/PawnNFTContract.sol:PawnNFTContract";
const ExchangeBuildName = "Exchange";
const LoanBuildName     = "PawnP2PLoanContract";

const proxyType = { kind: "uups" };

const decimals      = 10**18;

async function main() {
    const [deployer, proxyAdmin] = await hre.ethers.getSigners();
    
    console.log("============================================================\n\r");
    console.log("Deploying contracts with the account:", deployer.address);  
    console.log("Account balance:", ((await deployer.getBalance())/decimals).toString());
    console.log("============================================================\n\r");
  
    const NFTFactory    = await hre.ethers.getContractFactory(NFTBuildName);
    const NFTArtifact   = await hre.artifacts.readArtifact(NFTBuildName);

    const NFTContract      = await hre.upgrades.deployProxy(
        NFTFactory, 
        [
            "DFY_Physical_NFTs", 
            "DFYNFT", 
            PawnConfig.IpfsUri
        ], 
        proxyType
    );
    
    await NFTContract.deployed();
  
    console.log(`NFT_CONTRACT_ADDRESS: ${NFTContract.address}`);

    let implementationAddress = await hre.upgrades.erc1967.getImplementationAddress(NFTContract.address);
    console.log(`${NFTArtifact.contractName} implementation address: ${implementationAddress}`);

    console.log("============================================================\n\r");

    const EvaFactory    = await hre.ethers.getContractFactory(EvaBuildName);
    const EvaArtifact   = await hre.artifacts.readArtifact(EvaBuildName);

    const EvaContract   = await hre.upgrades.deployProxy(
        EvaFactory, 
        [
            PawnConfig.IpfsUri, 
            NFTContract.address, 
            PawnConfig.DFYToken
        ], 
        proxyType ?? "");

    await EvaContract.deployed();

    console.log(`EVALUATION_CONTRACT_ADDRESS: ${EvaContract.address}`);

    implementationAddress = await hre.upgrades.erc1967.getImplementationAddress(EvaContract.address);
    console.log(`${EvaArtifact.contractName} implementation address: ${implementationAddress}`);
    
    console.log("============================================================\n\r");

    const PawnNFTFactory    = await hre.ethers.getContractFactory(PawnNFTBuildName);
    const PawnNFTArtifact   = await hre.artifacts.readArtifact(PawnNFTBuildName);

    const PawnNFTContract   = await hre.upgrades.deployProxy(PawnNFTFactory, [100000], proxyType);

    await PawnNFTContract.deployed();

    console.log(`PAWN_NFT_CONTRACT_ADDRESS: ${PawnNFTContract.address}`);

    implementationAddress = await hre.upgrades.erc1967.getImplementationAddress(PawnNFTContract.address);
    console.log(`${PawnNFTArtifact.contractName} implementation address: ${implementationAddress}`);
    
    console.log("============================================================\n\r");

    const RepuFactory   = await hre.ethers.getContractFactory(RepuBuildName);
    const RepuArtifact  = await hre.artifacts.readArtifact(RepuBuildName);

    const RepuContract  = await hre.upgrades.deployProxy(RepuFactory, proxyType);
    
    await RepuContract.deployed();

    console.log(`REPUTATION_CONTRACT_ADDRESS: ${RepuContract.address}`);

    implementationAddress = await hre.upgrades.erc1967.getImplementationAddress(RepuContract.address);
    console.log(`${RepuArtifact.contractName} implementation address: ${implementationAddress}`);
    
    console.log("============================================================\n\r");

    const PawnFactory   = await hre.ethers.getContractFactory(PawnBuildName);
    const PawnArtifact  = await hre.artifacts.readArtifact(PawnBuildName);

    const pawnDeploy   = await PawnFactory.deploy();
    
    await pawnDeploy.deployed();
  
    console.log(`${PawnArtifact.contractName} implementation address: ${pawnDeploy.address}`);

    console.log("============================================================\n\r");

    const ProxyFactory  = await hre.ethers.getContractFactory(ProxyBuildName, proxyAdmin);
    // const ProxyArtifact = await hre.artifacts.readArtifact(ProxyBuildName);

    const proxyDeploy   = await ProxyFactory.deploy(pawnDeploy.address, proxyAdmin.address, ProxyData);
    
    await proxyDeploy.deployed();
  
    console.log(`PAWN_CONTRACT_ADDRESS: ${proxyDeploy.address}`);
    console.log("============================================================\n\r");
    
    const ExchangeFactory   = await hre.ethers.getContractFactory(ExchangeBuildName);
    const ExchangeArtifact  = await hre.artifacts.readArtifact(ExchangeBuildName);
    const ExchangeContract  = await hre.upgrades.deployProxy(ExchangeFactory, proxyType);

    await ExchangeContract.deployed();

    console.log(`EXCHANGE_CONTRACT_ADDRESS: ${ExchangeContract.address}`);

    implementationAddress = await hre.upgrades.erc1967.getImplementationAddress(ExchangeContract.address);
    console.log(`${ExchangeArtifact.contractName} implementation address: ${implementationAddress}`);

    console.log("============================================================\n\r");

    const LoanFactory   = await hre.ethers.getContractFactory(LoanBuildName);
    const LoanArtifact  = await hre.artifacts.readArtifact(LoanBuildName);
    const LoanContract  = await hre.upgrades.deployProxy(LoanFactory, proxyType);

    await LoanContract.deployed();

    console.log(`PAWN_NFPLOAN_CONTRACT_ADDRESS: ${LoanContract.address}`);

    implementationAddress = await hre.upgrades.erc1967.getImplementationAddress(LoanContract.address);
    console.log(`${LoanArtifact.contractName} implementation address: ${implementationAddress}`);

    console.log("============================================================\n\r");
}
  
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });