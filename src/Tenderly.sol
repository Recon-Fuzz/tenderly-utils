// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Vm.sol";
import {HTTP} from "solidity-http/HTTP.sol";
import {console} from "forge-std/console.sol";

library Tenderly {
    using HTTP for *;

    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    string constant BASE_URL = "https://api.tenderly.co/api/v1";

    struct Instance {
        string accountSlug;
        string projectSlug;
        string accessKey;
        HTTP.Client http;
    }

    struct Client {
        Instance[] instances;
    }

    struct Rpc {
        string name;
        string url;
    }

    struct VirtualTestnet {
        string id;
        Rpc[] rpcs;
        string slug;
    }

    struct HTTPVars {
        string requestBody;
        string tmp;
        HTTP.Response response;
    }

    struct Transaction {
        string id;
        string tx_hash;
    }

    function initialize(
        Client storage self,
        string memory accountSlug,
        string memory projectSlug,
        string memory accessKey
    ) internal returns (Client storage) {
        self.instances.push();
        Instance storage i = self.instances[self.instances.length - 1];
        i.accountSlug = accountSlug;
        i.projectSlug = projectSlug;
        i.accessKey = accessKey;
        i.http.initialize().withHeader("X-Access-Key", accessKey).withHeader("Content-Type", "application/json");
        return self;
    }

    function instance(Client storage self) private view returns (Instance storage) {
        return self.instances[self.instances.length - 1];
    }

    // https://docs.tenderly.co/reference/api#/operations/getVnet
    function getVirtualTestnetById(Client storage self, string memory vnetId)
        internal
        returns (VirtualTestnet memory)
    {
        HTTP.Response memory response = instance(self).http.instance().GET(
            string.concat(
                BASE_URL,
                "/account/",
                instance(self).accountSlug,
                "/project/",
                instance(self).projectSlug,
                "/vnets/",
                vnetId
            )
        ).request();

        return VirtualTestnet({
            id: abi.decode(vm.parseJson(response.data, ".id"), (string)),
            rpcs: abi.decode(vm.parseJson(response.data, ".rpcs"), (Rpc[])),
            slug: abi.decode(vm.parseJson(response.data, ".slug"), (string))
        });
    }

    // https://docs.tenderly.co/reference/api#/operations/createVnet
    function createVirtualTestnet(Client storage self, string memory slug, uint256 chainId)
        internal
        returns (VirtualTestnet memory)
    {
        HTTPVars memory vars;

        vars.requestBody = vm.serializeString(".createVirtualTestnet", "slug", slug);
        vars.requestBody = vm.serializeString(".createVirtualTestnet", "display_name", slug);

        vars.tmp = vm.serializeUint(".createVirtualTestnet.fork_config", "network_id", block.chainid);
        vars.tmp = vm.serializeString(".createVirtualTestnet.fork_config", "block_number", "latest");
        vars.requestBody = vm.serializeString(".createVirtualTestnet", "fork_config", vars.tmp);

        vars.tmp = "";
        vars.tmp = vm.serializeUint(".createVirtualTestnet.virtual_network_config", "chain_id", chainId);
        vars.tmp =
            vm.serializeString(".createVirtualTestnet.virtual_network_config.chain_config", "chain_config", vars.tmp);
        vars.requestBody = vm.serializeString(".createVirtualTestnet", "virtual_network_config", vars.tmp);

        vars.tmp = "";
        vars.tmp = vm.serializeBool(".createVirtualTestnet.sync_state_config", "enabled", false);
        vars.requestBody = vm.serializeString(".createVirtualTestnet", "sync_state_config", vars.tmp);

        vars.tmp = "";
        vars.tmp = vm.serializeBool(".createVirtualTestnet.explorer_page_config", "enabled", true);
        vars.tmp = vm.serializeString(".createVirtualTestnet.explorer_page_config", "verification_visibility", "src");
        vars.requestBody = vm.serializeString(".createVirtualTestnet", "explorer_page_config", vars.tmp);

        vars.response = instance(self).http.instance().POST(
            string.concat(
                BASE_URL, "/account/", instance(self).accountSlug, "/project/", instance(self).projectSlug, "/vnets"
            )
        ).withBody(vars.requestBody).request();

        return VirtualTestnet({
            id: abi.decode(vm.parseJson(vars.response.data, ".id"), (string)),
            rpcs: abi.decode(vm.parseJson(vars.response.data, ".rpcs"), (Rpc[])),
            slug: abi.decode(vm.parseJson(vars.response.data, ".slug"), (string))
        });
    }

    // No docs
    function getVirtualTestnets(Client storage self) internal returns (VirtualTestnet[] memory) {
        HTTP.Response memory response = instance(self).http.instance().GET(
            string.concat(
                BASE_URL, "/account/", instance(self).accountSlug, "/project/", instance(self).projectSlug, "/vnets"
            )
        ).request();

        string[] memory args = new string[](4);
        args[0] = "node";
        args[1] = "-e";
        args[2] = "console.log(JSON.parse(process.argv[1]).length)";
        args[3] = response.data;
        bytes memory length = vm.ffi(args);
        uint256 count = vm.parseUint(string(length));

        VirtualTestnet[] memory vnets = new VirtualTestnet[](count);

        for (uint256 i = 0; i < count; i++) {
            string memory prefix = string.concat("[", vm.toString(i), "]");

            bytes memory idRaw = vm.parseJson(response.data, string.concat(prefix, ".id"));
            bytes memory rpcsRaw = vm.parseJson(response.data, string.concat(prefix, ".rpcs"));
            bytes memory slugRaw = vm.parseJson(response.data, string.concat(prefix, ".slug"));

            vnets[i] = VirtualTestnet({
                id: abi.decode(idRaw, (string)),
                rpcs: abi.decode(rpcsRaw, (Rpc[])),
                slug: abi.decode(slugRaw, (string))
            });
        }

        return vnets;
    }

    // https://docs.tenderly.co/reference/api#/operations/deleteVnet
    function deleteVirtualTestnetById(Client storage self, string memory vnetId) internal {
        instance(self).http.instance().DELETE(
            string.concat(
                BASE_URL,
                "/account/",
                instance(self).accountSlug,
                "/project/",
                instance(self).projectSlug,
                "/vnets/",
                vnetId
            )
        ).request();
    }

    // https://docs.tenderly.co/reference/api#/operations/sendTransaction
    function sendTransaction(
        Client storage self,
        string memory vnetId,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (Transaction memory) {
        HTTPVars memory vars;

        vars.tmp = vm.serializeAddress(".sendTransaction.callArgs", "from", from);
        vars.tmp = vm.serializeAddress(".sendTransaction.callArgs", "to", to);
        vars.tmp = vm.serializeUintToHex(".sendTransaction.callArgs", "value", value);
        vars.tmp = vm.serializeString(".sendTransaction.callArgs", "gas", "0x7a1200");
        vars.tmp = vm.serializeString(".sendTransaction.callArgs", "gasPrice", "0x0");
        vars.tmp = vm.serializeBytes(".sendTransaction.callArgs", "data", data);
        vars.requestBody = vm.serializeString(".sendTransaction", "callArgs", vars.tmp);

        vars.response = instance(self).http.instance().POST(
            string.concat(
                BASE_URL,
                "/account/",
                instance(self).accountSlug,
                "/project/",
                instance(self).projectSlug,
                "/vnets/",
                vnetId,
                "/transactions"
            )
        ).withBody(vars.requestBody).request();

        return Transaction({
            id: abi.decode(vm.parseJson(vars.response.data, ".id"), (string)),
            tx_hash: vm.toString(abi.decode(vm.parseJson(vars.response.data, ".tx_hash"), (bytes32)))
        });
    }
}
