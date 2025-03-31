// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tenderly} from "../src/Tenderly.sol";
import {strings} from "solidity-stringutils/strings.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract TenderlyTest is Test {
    using Tenderly for *;
    using strings for *;

    Tenderly.Client tenderly;
    string slugPrefix = "tenderly-utils-test-";

    function setUp() public {
        vm.chainId(1);
        string memory accountSlug = vm.envString("TENDERLY_ACCOUNT_NAME");
        string memory projectSlug = vm.envString("TENDERLY_PROJECT_NAME");
        string memory accessKey = vm.envString("TENDERLY_ACCESS_KEY");
        tenderly.initialize(accountSlug, projectSlug, accessKey);

        Tenderly.VirtualTestnet[] memory vnets = tenderly.getVirtualTestnets();
        for (uint256 i = 0; i < vnets.length; i++) {
            if (vnets[i].slug.toSlice().contains(slugPrefix.toSlice())) {
                tenderly.deleteVirtualTestnetById(vnets[i].id);
            }
        }
    }

    function _test_Tenderly_createVirtualTestnet(string memory slug, uint256 chainId)
        internal
        returns (Tenderly.VirtualTestnet memory vnet)
    {
        vnet = tenderly.createVirtualTestnet(slug, chainId);
        assertTrue(vnet.slug.toSlice().contains(slug.toSlice()));
        assertGt(bytes(vnet.id).length, 0);
        assertGt(vnet.rpcs.length, 0);
    }

    function test_Tenderly_createVirtualTestnet() public {
        _test_Tenderly_createVirtualTestnet(string.concat(slugPrefix, "1"), 7357);
    }

    function test_Tenderly_getVirtualTestnetById() public {
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(string.concat(slugPrefix, "2"), 1337);
        Tenderly.VirtualTestnet memory vnet2 = tenderly.getVirtualTestnetById(vnet.id);
        assertEq(vnet2.id, vnet.id);
    }

    function test_Tenderly_getVirtualTestnets() public {
        Tenderly.VirtualTestnet[] memory vnets = tenderly.getVirtualTestnets();
        for (uint256 i = 0; i < vnets.length; i++) {
            assertGt(bytes(vnets[i].id).length, 0);
        }
    }

    function test_Tenderly_deleteVirtualTestnetById() public {
        uint256 countBefore = tenderly.getVirtualTestnets().length;
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(string.concat(slugPrefix, "3"), 1337);
        uint256 countAfter = tenderly.getVirtualTestnets().length;
        assertGt(countAfter, countBefore);
        tenderly.deleteVirtualTestnetById(vnet.id);
        assertEq(tenderly.getVirtualTestnets().length, countBefore);
    }

    function test_Tenderly_sendTransaction() public {
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(string.concat(slugPrefix, "4"), 1337);
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        Tenderly.Transaction memory transaction = tenderly.sendTransaction(
            vnet.id, address(this), weth, 0, abi.encodeWithSelector(IWETH.deposit.selector, address(this), 0)
        );
        assertGt(bytes(transaction.tx_hash).length, 0);
    }
}
