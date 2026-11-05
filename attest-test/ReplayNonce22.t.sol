// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {ReplayNonce22} from "../attest/ReplayNonce22.s.sol";

contract ReplayNonce22Test is ReplayNonce22 {
    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), FORK_BLOCK);
    }

    function testOriginalSimulationAndSignedSafeExecution() public {
        this.run();
    }

    function testChangedCalldataCannotUseHistoricalApprovals() public {
        (address to, bytes memory data) = build();
        data[data.length - 1] = bytes1(uint8(data[data.length - 1]) ^ 1);
        vm.expectRevert();
        this.executeMutation(to, data);
    }

    function executeMutation(address to, bytes calldata data) external {
        require(msg.sender == address(this), "Self only");
        _execute(to, data);
    }
}
