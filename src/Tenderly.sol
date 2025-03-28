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
    }

    struct Builder {
        Instance[] instances;
        HTTP.Builder http;
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
        string inner;
        string outer;
        HTTP.Response response;
    }

    function build(Builder storage self, string memory accountSlug, string memory projectSlug, string memory accessKey)
        internal
        returns (Builder storage)
    {
        self.instances.push(Instance({accountSlug: accountSlug, projectSlug: projectSlug, accessKey: accessKey}));
        return self;
    }

    function _instance(Builder storage self) private view returns (Instance storage) {
        return self.instances[self.instances.length - 1];
    }

    // https://docs.tenderly.co/reference/api#/operations/getVnet
    function getVirtualTestnetById(Builder storage self, string memory vnetId)
        internal
        returns (VirtualTestnet memory)
    {
        Instance memory i = _instance(self);
        HTTP.Response memory response = self.http.build().GET(
            string.concat(BASE_URL, "/account/", i.accountSlug, "/project/", i.projectSlug, "/vnets/", vnetId)
        ).withHeader("X-Access-Key", i.accessKey).request();

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
        Instance memory i = _instance(self);
        HTTPVars memory vars;

        vars.requestBody = vm.serializeString(".", "slug", slug);
        vars.requestBody = vm.serializeString(".", "display_name", slug);

        vars.inner = vm.serializeUint(".fork_config", "network_id", block.chainid);
        vars.inner = vm.serializeString(".fork_config", "block_number", "latest");
        vars.requestBody = vm.serializeString(".", "fork_config", vars.inner);

        vars.inner = "";
        vars.inner = vm.serializeUint(".virtual_network_config", "chain_id", chainId);
        vars.outer = vm.serializeString(".virtual_network_config.chain_config", "chain_config", vars.inner);
        vars.requestBody = vm.serializeString(".", "virtual_network_config", vars.outer);

        vars.inner = "";
        vars.inner = vm.serializeString(".sync_state_config", "enabled", "false");
        vars.requestBody = vm.serializeString(".", "sync_state_config", vars.inner);

        vars.inner = "";
        vars.inner = vm.serializeString(".explorer_page_config", "enabled", "true");
        vars.inner = vm.serializeString(".explorer_page_config", "verification_visibility", "src");
        vars.requestBody = vm.serializeString(".", "explorer_page_config", vars.inner);

        vars.response = self.http.build().POST(
            string.concat(BASE_URL, "/account/", i.accountSlug, "/project/", i.projectSlug, "/vnets")
        ).withBody(vars.requestBody).withHeader("Content-Type", "application/json").withHeader(
            "X-Access-Key", i.accessKey
        ).request();

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
        Instance memory i = _instance(self);
        HTTPVars memory vars;

        string memory callArgs;

        callArgs = vm.serializeAddress(".", "from", from);
        callArgs = vm.serializeAddress(".", "to", to);
        callArgs = vm.serializeUint(".", "value", value);
        callArgs = vm.serializeString(".", "gas", "0x7a1200");
        callArgs = vm.serializeString(".", "gasPrice", "0x0");
        callArgs = vm.serializeBytes(".", "data", data);
        vars.requestBody = vm.serializeString(".", "callArgs", callArgs);

        vars.response = self.http.build().POST(
            string.concat(
                BASE_URL, "/account/", i.accountSlug, "/project/", i.projectSlug, "/vnets/", vnetId, "/transactions"
            )
        ).withBody(vars.requestBody).withHeader("X-Access-Key", i.accessKey).request();

        return vars.response.data;
    }
}
