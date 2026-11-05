# Reproduce M0 Ethereum Safe nonce 22

This demo regenerates the three calls in `ProposeTransferSwapFacilityOwner` and
the complete Safe transaction signed by its owners. It starts from upstream
`9e194fa9410edaaa467a324a55fa07af0e65f5a8` (2025-11-18), which includes the
simulation and proposal calls. It extracts the existing batch builder into one
internal method shared by the original proposal script and the replay.

The replay calls the original `_simulateBatch`, checks its state effects, restores
the fork, then executes the complete Safe envelope with the two public historical
signatures. It checks the Safe nonce advances from 22 to 23 and verifies:

* ProxyAdmin ownership belongs to `0x23CA665c8a73292Fc7AC2cC4493d2cE883BBA468`.
* Engineering Safe `0xb7A9B5f301eF3bAD36C2b4964E82931Dd7fb989C` has SwapFacility `DEFAULT_ADMIN_ROLE`.
* Safe `0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1` no longer has that role.

No private key or new signature is needed. Run these commands without
`--broadcast`. The attestation profile disables FFI and uses only a local fork.
The original proposal entry point still requires a proposer key and contacts the
Safe service; the replay overrides that entry point.

## Run locally

Use Foundry 1.8.1, Solidity 0.8.26 and an Ethereum archive RPC:

```bash
git -c url.https://github.com/.insteadOf=git@github.com: submodule update --init --recursive --jobs 8 lib/forge-std lib/common
export MAINNET_RPC_URL=https://eth.drpc.org
FOUNDRY_PROFILE=attest forge test -vv
FOUNDRY_PROFILE=attest forge script attest/ReplayNonce22.s.sol:ReplayNonce22 \
  --rpc-url "$MAINNET_RPC_URL" --fork-block-number 23834855
```

The public RPC was tested on 2026-11-05; availability and limits may change.
The output `out/m0-nonce-22.json` is generated from Solidity on every run. The
fixture is a separate Safe service snapshot, fetched on 2026-11-05 from
<https://api.safe.global/tx-service/eth/api/v1/multisig-transactions/0xab7012df75fc7907ace6cb632bc3865ded2956c33fa2aab2d4b3d85167d485a6/>.
Only its historical signatures are consumed by the replay. The payload is not
copied from the fixture. A mutation test changes calldata and checks that those
signatures cannot authorize the changed transaction.

## Historical identity

| Field | Value |
| --- | --- |
| Network | Ethereum, chain ID 1 |
| Safe | `0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1`, version 1.3.0 |
| Safe nonce | 22 |
| Safe transaction hash | `0xab7012df75fc7907ace6cb632bc3865ded2956c33fa2aab2d4b3d85167d485a6` |
| Execution transaction | `0x0e510ee28b99bd2e99ca5e6e61145181fe71964a3bece9723e3417139b91f785` |
| Execution block | 23834856 |
| Fork block | 23834855 |
| Fork block hash | `0xe318ff8cdade8f7586f8da8ad683fc695e6b0141d738ff7b5e90ee021ee8d8b3` |
| MultiSendCallOnly | `0x40A2aCCbd92BCA938b02010E17A5b8929b49130D`, outer delegatecall |

All three inner operations are calls with zero ETH value. Safe gas/refund fields
are zero. The MultiSend packed payload is 427 bytes and outer calldata is 516
bytes. This demo adds no on-chain field, transaction, or execution cost.

The matching hash and valid historical signatures establish transaction equality.
They do not establish which commit the original operator ran. The selected
historical source is a matching reconstruction, not an authenticated record of
the original build environment. This demo covers one `evm-m-extensions` script.
The replay retains the producer's historical upstream dependency gitlinks and
does not require separate `common` or `safe-utils` forks. It does not use `m-portal`.

## Forge Attest

The root `attest-nonce22.toml` pins the tested producer commit, toolchain, raw
output hash, canonical hash and complete Safe hash. Use verifier revision
`998d11c9325990a74c534ef406a968c509d1544a`:

```bash
git clone https://github.com/crossecute/forge-attest ../m0-forge-attest
git -C ../m0-forge-attest checkout 998d11c9325990a74c534ef406a968c509d1544a
MAINNET_RPC_URL="$MAINNET_RPC_URL" ../m0-forge-attest/attest.sh \
  --config "$PWD/attest-nonce22.toml" --require-live --json
```

The verifier independently clones the producer, regenerates the output, checks
raw and canonical digests, derives the EIP-712 hash with cast and Solidity, and
compares the Safe service record at nonce 22. This nonce is already executed;
the service comparison is historical, not evidence of a pending proposal. Do not
use the signing/submission option `--attest` for this case study.

The CI workflow runs the fork tests and the same pinned claim with required
service comparison. A service or archive RPC outage fails CI. Neither endpoint
is replaced with a checked-in response during verification.
