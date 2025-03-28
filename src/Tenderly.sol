// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Vm.sol";
import {HTTP} from "solidity-http/HTTP.sol";

library Tenderly {
    using HTTP for HTTP.Builder;
    using HTTP for HTTP.Request;

    Vm constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    string constant BASE_URL = "https://api.tenderly.co/api/v1";

    struct Instance {
        string accountSlug;
        string projectSlug;
        string accessKey;
        HTTP.Builder http;
    }

    struct Builder {
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

    function build(Builder storage self, string memory accountSlug, string memory projectSlug, string memory accessKey)
        internal
        returns (Builder storage)
    {
        self.instances.push();
        Instance storage i = self.instances[self.instances.length - 1];
        i.accountSlug = accountSlug;
        i.projectSlug = projectSlug;
        i.accessKey = accessKey;
        i.http.build().withHeader("X-Access-Key", accessKey).withHeader("Content-Type", "application/json");
        return self;
    }

    function instance(Builder storage self) private view returns (Instance storage) {
        return self.instances[self.instances.length - 1];
    }

    // https://docs.tenderly.co/reference/api#/operations/getVnet
    function getVirtualTestnetById(Builder storage self, string memory vnetId)
        internal
        returns (VirtualTestnet memory)
    {
        HTTP.Response memory response = instance(self).http.build().GET(
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
    function createVirtualTestnet(Builder storage self, string memory slug, uint256 chainId)
        internal
        returns (VirtualTestnet memory)
    {
        HTTPVars memory vars;

        vars.requestBody = vm.serializeString(".", "slug", slug);
        vars.requestBody = vm.serializeString(".", "display_name", slug);

        vars.tmp = vm.serializeUint(".fork_config", "network_id", block.chainid);
        vars.tmp = vm.serializeString(".fork_config", "block_number", "latest");
        vars.requestBody = vm.serializeString(".", "fork_config", vars.tmp);

        vars.tmp = "";
        vars.tmp = vm.serializeUint(".virtual_network_config", "chain_id", chainId);
        vars.tmp = vm.serializeString(".virtual_network_config.chain_config", "chain_config", vars.tmp);
        vars.requestBody = vm.serializeString(".", "virtual_network_config", vars.tmp);

        vars.tmp = "";
        vars.tmp = vm.serializeBool(".sync_state_config", "enabled", false);
        vars.requestBody = vm.serializeString(".", "sync_state_config", vars.tmp);

        vars.tmp = "";
        vars.tmp = vm.serializeBool(".explorer_page_config", "enabled", true);
        vars.tmp = vm.serializeString(".explorer_page_config", "verification_visibility", "src");
        vars.requestBody = vm.serializeString(".", "explorer_page_config", vars.tmp);

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

    // https://docs.tenderly.co/reference/api#/operations/sendTransaction
    function sendTransaction(
        Builder storage self,
        string memory vnetId,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (string memory) {
        HTTPVars memory vars;

        string memory callArgs;

        callArgs = vm.serializeAddress(".", "from", from);
        callArgs = vm.serializeAddress(".", "to", to);
        callArgs = vm.serializeUint(".", "value", value);
        callArgs = vm.serializeString(".", "gas", "0x7a1200");
        callArgs = vm.serializeString(".", "gasPrice", "0x0");
        callArgs = vm.serializeBytes(".", "data", data);
        vars.requestBody = vm.serializeString(".", "callArgs", callArgs);

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

        return vars.response.data;
    }
}
