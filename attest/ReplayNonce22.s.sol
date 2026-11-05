// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script} from "../lib/forge-std/src/Script.sol";
import {ProposeTransferSwapFacilityOwner} from "../script/ProposeTransferSwapFacilityOwner.s.sol";

contract ReplayNonce22 is Script {
    function run() external {
        vm.setEnv("PATH", string.concat(vm.projectRoot(), "/attest/no-submit:", vm.envString("PATH")));
        new ProposeTransferSwapFacilityOwner().run();
    }
}
