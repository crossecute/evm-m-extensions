// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {ProposeTransferSwapFacilityOwner} from "../script/ProposeTransferSwapFacilityOwner.s.sol";
import {Safe} from "../lib/common/lib/safe-utils/src/Safe.sol";
import {ISafeSmartAccount} from "../lib/common/lib/safe-utils/src/ISafeSmartAccount.sol";
import {Enum} from "../lib/common/lib/safe-utils/lib/safe-smart-account/contracts/common/Enum.sol";
import {
    AccessControl
} from "../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {
    Ownable
} from "../lib/common/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract ReplayNonce22 is ProposeTransferSwapFacilityOwner {
    using Safe for Safe.Client;

    uint256 internal constant FORK_BLOCK = 23834855;
    bytes32 internal constant SAFE_TX_HASH = 0xab7012df75fc7907ace6cb632bc3865ded2956c33fa2aab2d4b3d85167d485a6;

    function build() public returns (address to, bytes memory data) {
        require(block.chainid == 1 && block.number == FORK_BLOCK, "Wrong historical fork");
        require(_targets.length == 0, "Batch already built");
        _buildBatch();
        _safeMultiSig.initialize(_SAFE_MULTISIG);
        require(_safeMultiSig.getNonce() == 22, "Wrong Safe nonce");
        return _safeMultiSig.getProposeTransactionsTargetAndData(_targets, _data);
    }

    function run() external override {
        (address to, bytes memory data) = build();
        require(
            _safeMultiSig.getSafeTxHash(to, 0, data, Enum.Operation.DelegateCall, 22) == SAFE_TX_HASH,
            "Historical Safe hash mismatch"
        );

        uint256 snapshot = vm.snapshotState();
        _simulateBatch(_SAFE_MULTISIG);
        _verifyEffects();
        require(vm.revertToState(snapshot), "Restore failed");

        require(_execute(to, data), "Safe execution failed");
        require(_safeMultiSig.getNonce() == 23, "Safe nonce did not advance");
        _verifyEffects();
        _writeTransaction(to, data);
    }

    function _execute(address to, bytes memory data) internal returns (bool) {
        // These are public historical approvals, used only against the pinned local fork.
        bytes memory signatures =
            vm.parseJsonBytes(vm.readFile("attest/fixtures/nonce-22.safe-service.json"), ".signatures");
        return ISafeSmartAccount(_SAFE_MULTISIG)
            .execTransaction(
                to, 0, data, Enum.Operation.DelegateCall, 0, 0, 0, address(0), payable(address(0)), signatures
            );
    }

    function _verifyEffects() internal view {
        require(Ownable(_PROXY_ADMIN).owner() == _MAINNET_TIMELOCK, "ProxyAdmin owner mismatch");
        AccessControl facility = AccessControl(_SWAP_FACILITY);
        bytes32 role = facility.DEFAULT_ADMIN_ROLE();
        require(facility.hasRole(role, _ENG_MULTISIG), "Engineering admin missing");
        require(!facility.hasRole(role, _SAFE_MULTISIG), "Original Safe still admin");
    }

    function _writeTransaction(address to, bytes memory data) internal {
        string memory key = "nonce22";
        vm.serializeAddress(key, "safe", _SAFE_MULTISIG);
        vm.serializeString(key, "chainId", "1");
        vm.serializeString(key, "safeVersion", "1.3.0");
        vm.serializeAddress(key, "to", to);
        vm.serializeString(key, "value", "0");
        vm.serializeBytes(key, "data", data);
        vm.serializeString(key, "operation", "1");
        vm.serializeString(key, "safeTxGas", "0");
        vm.serializeString(key, "baseGas", "0");
        vm.serializeString(key, "gasPrice", "0");
        vm.serializeAddress(key, "gasToken", address(0));
        vm.serializeAddress(key, "refundReceiver", address(0));
        string memory json = vm.serializeString(key, "nonce", "22");
        vm.writeJson(json, "out/m0-nonce-22.json");
    }
}
