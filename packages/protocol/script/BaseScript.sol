// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/src/console2.sol";
import "forge-std/src/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@optimism/packages/contracts-bedrock/src/EAS/Common.sol";

import "src/shared/common/DefaultResolver.sol";

abstract contract BaseScript is Script {
    address public resolver = vm.envOr("RESOLVER", address(0));
    uint256 public deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    modifier broadcast() {
        require(deployerPrivateKey != 0, "invalid private key");
        vm.startBroadcast(deployerPrivateKey);
        _;
        vm.stopBroadcast();
    }

    function deploy(
        bytes32 name,
        address impl,
        bytes memory data
    )
        internal
        returns (address proxy)
    {
        proxy = address(new ERC1967Proxy(impl, data));
        string memory _name = Strings.toString(uint256(name));
        vm.writeJson(
            vm.serializeAddress("deployment", _name, proxy),
            string.concat(vm.projectRoot(), "/deployments/deploy_l1.json")
        );

        console2.log(">", string.concat("'", bytes32ToString(name), "'"));
        console2.log("       proxy   :", proxy);
        console2.log("       impl    :", impl);
        console2.log("       owner   :", OwnableUpgradeable(proxy).owner());
        console2.log("       chain id:", block.chainid);
        if (resolver != address(0)) {
            console2.log("  registered at:", resolver);
            DefaultResolver(resolver).setAddress(block.chainid, name, proxy);
        }
    }

        function deploy(
        bytes32 name,
        address impl,
        bytes memory data,
        DefaultResolver _resolver
    )
        internal
        returns (address proxy)
    {
        proxy = address(new ERC1967Proxy(impl, data));
        string memory _name = Strings.toString(uint256(name));
        vm.writeJson(
            vm.serializeAddress("deployment", _name, proxy),
            string.concat(vm.projectRoot(), "/deployments/deploy_l1.json")
        );

        console2.log(">", string.concat("'", bytes32ToString(name), "'"));
        console2.log("       proxy   :", proxy);
        console2.log("       impl    :", impl);
        console2.log("       owner   :", OwnableUpgradeable(proxy).owner());
        console2.log("       chain id:", block.chainid);
            console2.log("  registered at:", address(_resolver));
            _resolver.setAddress(block.chainid, name, proxy);
        }
}
