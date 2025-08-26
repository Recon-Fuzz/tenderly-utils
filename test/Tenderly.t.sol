// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Tenderly} from "../src/Tenderly.sol";
import {strings} from "../lib/solidity-stringutils/src/strings.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

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
                console.log("deleting vnet", vnets[i].id, vnets[i].slug);
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
        _test_Tenderly_createVirtualTestnet(_slug(msg.sig), 7357);
    }

    function test_Tenderly_getVirtualTestnetById() public {
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(_slug(msg.sig), 1337);
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
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(_slug(msg.sig), 1337);
        uint256 countAfter = tenderly.getVirtualTestnets().length;
        assertGt(countAfter, countBefore);
        tenderly.deleteVirtualTestnetById(vnet.id);
        uint256 countFinally = tenderly.getVirtualTestnets().length;
        assertLe(countFinally, countAfter);
    }

    function test_Tenderly_sendTransaction() public {
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(_slug(msg.sig), 1337);
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        Tenderly.Transaction memory transaction = tenderly.sendTransaction(
            vnet.id, address(this), weth, 0, abi.encodeWithSelector(IWETH.deposit.selector, address(this), 0)
        );
        assertGt(bytes(transaction.tx_hash).length, 0);
    }

    function test_Tenderly_setStorageAt() public {
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(_slug(msg.sig), 1337);
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        bytes32 slot = bytes32(uint256(2));
        bytes32 value = bytes32(uint256(6));
        tenderly.setStorageAt(vnet, weth, slot, value);

        bytes32 storageAt = tenderly.getStorageAt(vnet, weth, slot);
        assertEq(storageAt, value);
    }

    function test_Tenderly_setBalance() public {
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(_slug(msg.sig), 1337);
        address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        uint256 balance = 1000 ether;
        tenderly.setBalance(vnet, weth, balance);

        uint256 balance2 = tenderly.getBalance(vnet, weth);
        assertEq(balance2, balance);
    }

    function test_Tenderly_increaseTime() public {
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(_slug(msg.sig), 1337);
        tenderly.increaseTime(vnet, 24 hours);
    }

    function test_Tenderly_increaseBlocks() public {
        Tenderly.VirtualTestnet memory vnet = _test_Tenderly_createVirtualTestnet(_slug(msg.sig), 1337);
        tenderly.increaseBlocks(vnet, 1);
    }

    function _slug(bytes4 suffix) internal view returns (string memory) {
        return string.concat(slugPrefix, Strings.toHexString(uint256(uint32(suffix))));
    }
}
