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
}