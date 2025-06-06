## tenderly-utils

Interact with the [Tenderly API](https://docs.tenderly.co/api) from Foundry scripts.

### Installation

```bash
forge install Recon-Fuzz/tenderly-utils
```

### Usage

#### 1. Import the library

```solidity
import {Tenderly} from "tenderly-utils/Tenderly.sol";
```

#### 2. Initialize the client

Build the client by passing your account slug, project slug, and access key.

```solidity
using Tenderly for *;

Tenderly.Client tenderly;

function setUp() public {
    string memory accountSlug = vm.envString("TENDERLY_ACCOUNT_NAME");
    string memory projectSlug = vm.envString("TENDERLY_PROJECT_NAME");
    string memory accessKey = vm.envString("TENDERLY_ACCESS_KEY");

    tenderly.initialize(accountSlug, projectSlug, accessKey);
}
```

#### 3. Create and manage Virtual TestNets

```solidity
// Create a Virtual Testnet
Tenderly.VirtualTestnet memory vnet = tenderly.createVirtualTestnet("my-vnet", block.chainid);
console.log("Virtual TestNet ID:", vnet.id);

// Submit a transaction
Tenderly.Transaction memory transaction = tenderly.sendTransaction(
  vnet.id, from, weth, abi.encodeCall(IWETH.withdraw.selector, (amount))
);
```

### Requirements

- Foundry with FFI enabled:
  - Pass `--ffi` to your commands (e.g. `forge test --ffi`)
  - Or set `ffi = true` in your `foundry.toml`

```toml
[profile.default]
ffi = true
```

- A UNIX-based environment with the following installed:
  - `node`
  - All `Recon-Fuzz/solidity-http` dependencies

- Tenderly API access:
  - Get your account/project slug and access key from the [Tenderly dashboard](https://dashboard.tenderly.co)

### Disclaimer

This code is provided "as is" and has not undergone a formal security audit.

Use it at your own risk. The author(s) assume no liability for any damages or losses resulting from the use of this code. It is your responsibility to thoroughly review, test, and validate its security and functionality before deploying or relying on it in any environment.

This is not an official [@tenderly](https://github.com/tenderly) library
