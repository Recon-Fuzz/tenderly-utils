// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tenderly} from "@src/Tenderly.sol";

contract TenderlyTest is Test {
    using Tenderly for Tenderly.Builder;

    Tenderly.Builder tenderly;

    function setUp() public {
        string memory accountSlug = vm.envString("TENDERLY_ACCOUNT_NAME");
        string memory projectSlug = vm.envString("TENDERLY_PROJECT_NAME");
        string memory accessKey = vm.envString("TENDERLY_ACCESS_KEY");
        tenderly.build(accountSlug, projectSlug, accessKey);
    }

    function _test_Tenderly_createVirtualTestnet(string memory slug, uint256 chainId)
        internal
        returns (Tenderly.VirtualTestnet memory vnet)
    {
        vnet = tenderly.createVirtualTestnet(slug, chainId);
        assertEq(vnet.slug, slug);
        assertGt(bytes(vnet.id).length, 0);
        assertGt(vnet.rpcs.length, 0);
    }

    function test_Tenderly_createVirtualTestnet() public {
        _test_Tenderly_createVirtualTestnet("abc", 7357);
    }

    function test_Tenderly_getVirtualTestnetById() public {
        string memory slug = "test";
        uint256 chainId = 1337;
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(slug, chainId);
        Tenderly.VirtualTestnet memory vnet2 = tenderly.getVirtualTestnetById(vnet.id);
        assertEq(vnet2.id, vnet.id);
    }
}
