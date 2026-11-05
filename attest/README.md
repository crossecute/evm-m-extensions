# M0 nonce 22: unchanged producer, captured proposal

The original `script/ProposeTransferSwapFacilityOwner.s.sol` and `foundry.toml`
are byte-for-byte identical to upstream commit
`9e194fa9410edaaa467a324a55fa07af0e65f5a8`.

`ReplayNonce22` sets a local HTTP transport on `PATH` and invokes the original
script. That script builds and simulates the three calls, derives the Safe hash,
and constructs its usual `safe-utils` proposal. The transport captures the JSON
passed to `curl -d` in `out/m0-nonce-22.json` and returns a local HTTP 201 response.
It never calls the real curl executable or sends the proposal.

The claim uses public test key `1` only because the original script requires
`PRIVATE_KEY` and signs its request. This is not an owner signature and must not
be replaced with a real key. No original signer approvals or service fixture are
needed. Never run this demo with `--broadcast` or Forge Attest's `--attest` option.

Use Foundry 1.8.1 and an Ethereum archive RPC:

```bash
git clone https://github.com/crossecute/forge-attest ../m0-forge-attest
git -C ../m0-forge-attest checkout 998d11c9325990a74c534ef406a968c509d1544a
export MAINNET_RPC_URL='YOUR_ETHEREUM_ARCHIVE_RPC_URL'
../m0-forge-attest/attest.sh --config "$PWD/attest-nonce22.toml" --require-live --json
```

The claim pins the producer, toolchain, Ethereum block 23834855, raw output,
canonical transaction and Safe hash. The existing `safe-service` reader with the
`safe-utils` profile verifies the captured request, including its carried
`contractTransactionHash`. Cast and Solidity independently derive the same hash,
and the required service check compares nonce 22's historical record:

`0xab7012df75fc7907ace6cb632bc3865ded2956c33fa2aab2d4b3d85167d485a6`.

The original per-call simulation remains part of this run. Full signed Safe
execution and separate post-state assertions are not included. Hash equality
proves the complete transaction matches nonce 22, not which source revision the
original operator used or whether the permissions change is appropriate.
