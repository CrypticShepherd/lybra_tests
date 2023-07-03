// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {GovernanceTimelock} from "../lib/2023-06-lybra/contracts/lybra/governance/GovernanceTimelock.sol";
import {Configurator} from "../lib/2023-06-lybra/contracts/lybra/configuration/LybraConfigurator.sol";

import {EUSD} from "../lib/2023-06-lybra/contracts/lybra/token/EUSD.sol";
import {PeUSDMainnet} from "../lib/2023-06-lybra/contracts/lybra/token/PeUSDMainnetStableVision.sol";

import {LybraStETHDepositVault} from "../lib/2023-06-lybra/contracts/lybra/pools/LybraStETHVault.sol";
import {LybraRETHVault} from "../lib/2023-06-lybra/contracts/lybra/pools/LybraRETHVault.sol";

import {mockLBRPriceOracle} from "../lib/2023-06-lybra/contracts/mocks/mockLBRPriceOracle.sol";
import {esLBRBoost} from "../lib/2023-06-lybra/contracts/lybra/miner/esLBRBoost.sol";
import {EUSDMiningIncentives} from "../lib/2023-06-lybra/contracts/lybra/miner/EUSDMiningIncentives.sol";
import {ProtocolRewardsPool} from "../lib/2023-06-lybra/contracts/lybra/miner/ProtocolRewardsPool.sol";

import {esLBR} from "../lib/2023-06-lybra/contracts/lybra/token/esLBR.sol";
import {LBR} from "../lib/2023-06-lybra/contracts/lybra/token/LBR.sol";
import {GovernanceTimelock} from "../lib/2023-06-lybra/contracts/lybra/governance/GovernanceTimelock.sol";
import {LybraGovernance} from "../lib/2023-06-lybra/contracts/lybra/governance/LybraGovernance.sol";

import {mockCurve} from "../lib/2023-06-lybra/contracts/mocks/mockCurve.sol";
import {stETHMock} from "../lib/2023-06-lybra/contracts/mocks/stETHMock.sol";
import {mockRETH} from "./mockRETH.sol";
import {mockChainlink} from "./chainLinkMock.sol";
import {mockRPLDeposit} from "./mockRPLDeposit.sol";

contract TestsBase is Test {
    address goerliLzEndPoint = 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23;

    esLBR realEsLBR;
    LBR realLBR;
    address[] governanceTimelockAddresses;
    GovernanceTimelock realGovernanceTimelock;
    LybraGovernance realGovernance;
    Configurator realConfigurator;

    EUSD realEUSD;
    PeUSDMainnet realPeUSDMainnet;

    LybraStETHDepositVault realStETHVault;
    LybraRETHVault realRETHVault;

    esLBRBoost realBoost;
    EUSDMiningIncentives realEUSDMiningIncentives;
    ProtocolRewardsPool realProtcolRewardsPool;
    address[] pools;
    address[] miners;
    bool[] minerBools;

    mockCurve fakeCurve;
    stETHMock fakeStETH;
    mockRETH fakeRETH;
    mockChainlink fakeChainLink;
    mockRPLDeposit fakeRocketpoolDeposit;
    mockLBRPriceOracle fakeLBRPriceOracle;

    address owner = address(7);

    function setUp() public virtual {
        vm.startPrank(owner);

        // set up mock contracts, part one
        fakeCurve = new mockCurve();
        fakeStETH = new stETHMock();
        fakeRETH = new mockRETH();
        fakeChainLink = new mockChainlink();
        fakeRocketpoolDeposit = new mockRPLDeposit();

        // set up governance time lock
        governanceTimelockAddresses.push(owner);
        // delay of 1, proposers, executors and admin are all us (the owner)
        realGovernanceTimelock = new GovernanceTimelock(
            1,
            governanceTimelockAddresses,
            governanceTimelockAddresses,
            owner
        );

        // set up configurator with real governance and fake curve used for stables conversion
        realConfigurator = new Configurator(address(realGovernanceTimelock), address(fakeCurve));

        // set up real EUSD
        realEUSD = new EUSD(address(realConfigurator));

        // set up real PeUSD
        realPeUSDMainnet = new PeUSDMainnet(address(realConfigurator), 8, goerliLzEndPoint);

        // register both with configurator
        realConfigurator.initToken(address(realEUSD), address(realPeUSDMainnet));

        // set up real StETH Vault
        realStETHVault = new LybraStETHDepositVault(address(realConfigurator), address(fakeStETH), address(fakeChainLink));
        realConfigurator.setMintVault(address(realStETHVault), true);
        realConfigurator.setMintVaultMaxSupply(address(realStETHVault), 10_000_000_000 * 1e18);

        // set up real RETH Vault
        realRETHVault = new LybraRETHVault(address(realPeUSDMainnet), address(realConfigurator), address(fakeRETH), address(fakeChainLink), address(fakeRocketpoolDeposit));
        realConfigurator.setMintVault(address(realRETHVault), true);
        realConfigurator.setMintVaultMaxSupply(address(realRETHVault), 10_000_000_000 * 1e18);
        realConfigurator.setBorrowApy(address(realRETHVault), 200);
        realConfigurator.setSafeCollateralRatio(address(realRETHVault), 160 * 1e18);
        realConfigurator.setBadCollateralRatio(address(realRETHVault), 130 * 1e18);

        // set up incentives
        fakeLBRPriceOracle = new mockLBRPriceOracle();
        realBoost = new esLBRBoost();
        realEUSDMiningIncentives = new EUSDMiningIncentives(address(realConfigurator), address(realBoost), address(fakeChainLink), address(fakeLBRPriceOracle));
        pools.push(address(realStETHVault));
        pools.push(address(realRETHVault));
        realEUSDMiningIncentives.setPools(pools);
        realProtcolRewardsPool = new ProtocolRewardsPool(address(realConfigurator));
        realConfigurator.setProtocolRewardsPool(address(realProtcolRewardsPool));
        miners.push(address(realProtcolRewardsPool));
        minerBools.push(true);
        miners.push(address(owner)); // add owner as minter so that we can easily get some LBR or esLBR
        minerBools.push(true);
        realConfigurator.setTokenMiner(miners, minerBools);

        // set up rest of governance
        realEsLBR = new esLBR(address(realConfigurator));
        realLBR = new LBR(address(realConfigurator), 8, goerliLzEndPoint);
        realGovernance = new LybraGovernance("LYBRA", realGovernanceTimelock, address(realEsLBR));

        vm.stopPrank();
    }
}