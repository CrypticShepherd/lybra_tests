// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


import "forge-std/Test.sol";
import {TestsBase} from "./TestsBase.t.sol";

contract TestsPOC is TestsBase {
    function setUp() public virtual override {
        TestsBase.setUp();
    }

   // test absolute basics (inital state) for real EUSD
    function testEUSDBasics() public {
        assertTrue(keccak256(abi.encodePacked(realEUSD.name())) == keccak256(abi.encodePacked("eUSD")));
        assertTrue(keccak256(abi.encodePacked(realEUSD.symbol())) == keccak256(abi.encodePacked("eUSD")));
        assertEq(realEUSD.decimals(), 18);
        assertEq(realEUSD.totalSupply(), 0);
        assertEq(realEUSD.balanceOf(owner), 0);
    }

    // test absolute basics (inital state) for stETH Vault
    function testStETHVaultBasics() public {
        assertEq(realStETHVault.getAssetPrice(), fakeChainLink.fetchPrice());
        assertEq(realStETHVault.getPoolTotalEUSDCirculation(), 0);
    }

    // basic mint test depositing stETH (so no deposit into Lido)
    function testStETHAssetMint() public {
        vm.startPrank(owner);

        fakeStETH.approve(address(realStETHVault), 2*1e18);
        realStETHVault.depositAssetToMint(2*1e18, 2000*1e18);
        assertEq(realStETHVault.totalDepositedAsset(), 2*1e18);
        assertEq(realStETHVault.poolTotalEUSDCirculation(), 2000*1e18);
        assertEq(realStETHVault.getBorrowedOf(owner), 2000*1e18);
        assertEq(realEUSD.balanceOf(owner), 2000*1e18);

        vm.stopPrank();
    }

        // test absolute basics (inital state) for real EUSD
    function testPeUSDMainnetBasics() public {
        assertTrue(keccak256(abi.encodePacked(realPeUSDMainnet.name())) == keccak256(abi.encodePacked("peg-eUSD")));
        assertTrue(keccak256(abi.encodePacked(realPeUSDMainnet.symbol())) == keccak256(abi.encodePacked("PeUSD")));
        assertEq(realPeUSDMainnet.decimals(), 18);
        assertEq(realPeUSDMainnet.totalSupply(), 0);
        assertEq(realPeUSDMainnet.balanceOf(owner), 0);
    }

    // test absolute basics (inital state) for stETH Vault
    function testRETHVaultBasics() public {
        assertEq(realRETHVault.getAssetPrice(), fakeChainLink.fetchPrice() * fakeRETH.getExchangeRatio() / 1e18);
        assertEq(realRETHVault.getPoolTotalPeUSDCirculation(), 0);
    }

    // basic mint test depositing stETH (so no deposit into Lido)
    function testRETHAssetMint() public {
        vm.startPrank(owner);

        fakeRETH.approve(address(realRETHVault), 2*1e18);
        realRETHVault.depositAssetToMint(2*1e18, 2000*1e18);
        assertEq(realRETHVault.totalDepositedAsset(), 2*1e18);
        assertEq(realRETHVault.getPoolTotalPeUSDCirculation(), 2000*1e18);
        assertEq(realRETHVault.getBorrowedOf(owner), 2000*1e18);
        assertEq(realPeUSDMainnet.balanceOf(owner), 2000*1e18);

        vm.stopPrank();
    }

    function testEsLBR() public {
        vm.startPrank(owner);
        assertEq(realEsLBR.totalSupply(), 0);
        assertTrue(keccak256(abi.encodePacked(realEsLBR.name())) == keccak256(abi.encodePacked("esLBR")));
        assertTrue(keccak256(abi.encodePacked(realEsLBR.symbol())) == keccak256(abi.encodePacked("esLBR")));
        vm.stopPrank();
    }

    function testLBR() public {
        vm.startPrank(owner);
        assertEq(realLBR.totalSupply(), 0);
        assertTrue(keccak256(abi.encodePacked(realLBR.name())) == keccak256(abi.encodePacked("LBR")));
        assertTrue(keccak256(abi.encodePacked(realLBR.symbol())) == keccak256(abi.encodePacked("LBR")));
        vm.stopPrank();
    }

    function testGovernance() public {
        vm.startPrank(owner);
        assertTrue(keccak256(abi.encodePacked(realGovernance.name())) == keccak256(abi.encodePacked("LYBRA")));
        assertTrue(keccak256(abi.encodePacked(realGovernance.CLOCK_MODE())) == keccak256(abi.encodePacked("mode=blocknumber&from=default")));
        vm.stopPrank();
    }

    function testProposal() public {
        vm.startPrank(owner);

        // get some voting power
        realEsLBR.mint(owner, 2*1e23);
        realEsLBR.delegate(owner);
        vm.roll(2);

        // make a proposal
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        string memory description = "Test Proposal";
        uint256 proposalID = realGovernance.propose(
            targets,
            values,
            calldatas,
            description
        );

        // vote
        vm.roll(2 + realGovernance.votingDelay() + 1);
        realGovernance.castVote(proposalID, 1);

        // queue
        vm.roll(2 + realGovernance.votingPeriod() + realGovernance.votingDelay() + 1);
        realGovernanceTimelock.grantRole(realGovernanceTimelock.TIMELOCK(), owner);
        realGovernanceTimelock.grantRole(realGovernanceTimelock.PROPOSER_ROLE(), address(realGovernance));
        realGovernance.queue(targets, values, calldatas, keccak256(abi.encodePacked(description)));

        // execute
        vm.warp(3);
        realGovernanceTimelock.grantRole(realGovernanceTimelock.EXECUTOR_ROLE(), address(realGovernance));
        realGovernance.execute(targets, values, calldatas, keccak256(abi.encodePacked(description)));

        vm.stopPrank();
    }

}