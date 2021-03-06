require('@nomiclabs/hardhat-ethers');
const hre = require('hardhat');
const { PawnContract } = require('../test/Pawn.test');

const { PawnConfig, Proxies, Tokens } = require('./.deployment_data_prelive.json');
const proxies = Proxies.Prelive;

const PawnProxyAddr     = proxies.PAWN_CONTRACT_ADDRESS;
const PawnBuildName     = "contracts/pawn/pawn-p2p/PawnContract.sol:PawnContract";

const RepuProxyAddr     = proxies.REPUTATION_CONTRACT_ADDRESS;
const RepuBuildName     = "contracts/pawn/reputation/Reputation.sol:Reputation";

const ExchangeProxyAddr = proxies.EXCHANGE_CONTRACT_ADDRESS;

const LoanProxyAddr     = proxies.PAWN_P2PLOAN_CONTRACT_ADDRESS;

const zoom              = PawnConfig.ZOOM;
const lateThreshold     = PawnConfig.LateThreshold;
const penaltyRate       = PawnConfig.PenaltyRate;
const prepaidFeeRate    = PawnConfig.PrepaidFee;
const systemFeeRate     = PawnConfig.SystemFee;
const operator          = PawnConfig.EvaluationOperator;
const feeWallet         = PawnConfig.FeeWallet;

const decimals          = 10**18;

async function main() {
    const [deployer] = await hre.ethers.getSigners();

    console.log("============================================================");
    console.log(`Initialize contracts with the account: ${deployer.address}`);  
    console.log("Account balance:", ((await deployer.getBalance())/decimals).toString());
    console.log("============================================================");

    const PawnFactory   = await hre.ethers.getContractFactory(PawnBuildName);
    const PawnArtifact  = await hre.artifacts.readArtifact(PawnBuildName);
    const PawnContract  = PawnFactory.attach(PawnProxyAddr);

    const RepuFactory   = await hre.ethers.getContractFactory(RepuBuildName);
    const RepuArtifact  = await hre.artifacts.readArtifact(RepuBuildName);
    const RepuContract  = RepuFactory.attach(RepuProxyAddr);

    console.log(`Initializing ${PawnArtifact.contractName}...`);
    await PawnContract.initialize(zoom);
    console.log(`Initialized contract with Zoom factor of ${zoom}\n\r`);

    console.log(`Setting Fee wallet...`);
    await PawnContract.setFeeWallet(feeWallet);
    console.log(`Fee wallet set at: ${feeWallet}\n\r`);

    console.log(`Setting contract operator...`);
    await PawnContract.setOperator(operator);
    console.log(`Contract operator: ${operator}\n\r`);

    console.log(`Setting Late threshold...`);
    await PawnContract.setLateThreshold(lateThreshold);
    console.log(`Late threshold: ${lateThreshold}\n\r`);

    console.log(`Setting Penalty rate...`);
    await PawnContract.setPenaltyRate(penaltyRate);
    console.log(`Penalty rate: ${penaltyRate}\n\r`);

    console.log(`Setting Prepaid fee rate...`);
    await PawnContract.setPrepaidFeeRate(prepaidFeeRate);
    console.log(`Prepaid fee rate: ${prepaidFeeRate}\n\r`);

    console.log(`Setting System fee rate...`);
    await PawnContract.setSystemFeeRate(systemFeeRate);
    console.log(`System fee rate: ${systemFeeRate}\n\r`);

    console.log(`Setting Reputation contract...`);
    await PawnContract.setReputationContract(RepuProxyAddr);
    console.log(`Reputation contract set at address: ${RepuProxyAddr}\n\r`);

    console.log(`Setting Exchange contract...`);
    await PawnContract.setExchangeContract(ExchangeProxyAddr);
    console.log(`Exchange contract set at address: ${ExchangeProxyAddr}\n\r`);

    console.log(`Setting Loan contract...`);
    await PawnContract.setPawnLoanContract(LoanProxyAddr);
    console.log(`Loan contract set at address: ${LoanProxyAddr}\n\r`);

    console.log(`Setting Whitelisted collateral...`);
    for await (let token of Tokens) {
        if(token.Address != "0x0000000000000000000000000000000000000000") {
            await PawnContract.setWhitelistCollateral(token.Address, 1);
            console.log(`\tWhitelisted token as collateral: ${token.Symbol}: ${token.Address}`);
        }
    }

    // console.log("============================================================\n\r");
    // console.log(`Initializing ${RepuArtifact.contractName}...`);
    // console.log(`Setting contract caller...`);
    // await RepuContract.addWhitelistedContractCaller(PawnProxyAddr);
    // console.log(`Contract caller set at address: ${PawnArtifact.contractName} - ${PawnProxyAddr}\n\r`);

    console.log("============================================================\n\r");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });