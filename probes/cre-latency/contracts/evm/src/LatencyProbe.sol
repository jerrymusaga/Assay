// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReceiverTemplate} from "./ReceiverTemplate.sol";

/// @title LatencyProbe
/// @notice Measures end-to-end Chainlink CRE latency: the gap between an event
///         being emitted on Monad and the DON's report landing back onchain.
///
///         Deliberately both the trigger source AND the receiver, so both
///         timestamps come from the same chain clock. No cross-contract or
///         cross-chain skew to argue about.
///
///         ping()  -> emits Ping (the CRE log trigger fires on this)
///         onReport -> CRE writes back, we record arrival block/timestamp
contract LatencyProbe is ReceiverTemplate {
    struct Sample {
        uint64 triggerBlock;
        uint64 triggerTime;
        uint64 writeBlock;
        uint64 writeTime;
    }

    uint256 public seq;
    mapping(uint256 => Sample) public samples;

    /// @notice Emitted by ping(); this is what the CRE log trigger watches.
    event Ping(uint256 indexed seqNo, uint256 blockNumber, uint256 timestamp);

    /// @notice Emitted when the DON's report arrives back onchain.
    event Pong(
        uint256 indexed seqNo,
        uint256 triggerBlock,
        uint256 writeBlock,
        uint256 blockDelta,
        uint256 secondsDelta
    );

    constructor(address forwarder) ReceiverTemplate(forwarder) {}

    /// @notice Fire one probe. Anyone can call; each call is a fresh sample.
    function ping() external returns (uint256 seqNo) {
        seqNo = ++seq;
        samples[seqNo] = Sample({
            triggerBlock: uint64(block.number),
            triggerTime: uint64(block.timestamp),
            writeBlock: 0,
            writeTime: 0
        });
        emit Ping(seqNo, block.number, block.timestamp);
    }

    /// @notice Called by the Chainlink Forwarder after ReceiverTemplate validates it.
    /// @param report ABI-encoded (uint256 seqNo)
    function _processReport(bytes calldata report) internal override {
        uint256 seqNo = abi.decode(report, (uint256));

        Sample storage s = samples[seqNo];
        // Ignore an unknown or already-completed sample rather than reverting —
        // a revert here would be indistinguishable from a delivery failure.
        if (s.triggerBlock == 0 || s.writeBlock != 0) {
            return;
        }

        s.writeBlock = uint64(block.number);
        s.writeTime = uint64(block.timestamp);

        emit Pong(
            seqNo,
            s.triggerBlock,
            s.writeBlock,
            s.writeBlock - s.triggerBlock,
            s.writeTime - s.triggerTime
        );
    }

    /// @notice Read one sample plus its computed deltas.
    function getSample(uint256 seqNo)
        external
        view
        returns (
            uint64 triggerBlock,
            uint64 triggerTime,
            uint64 writeBlock,
            uint64 writeTime,
            bool complete,
            uint64 blockDelta,
            uint64 secondsDelta
        )
    {
        Sample memory s = samples[seqNo];
        complete = s.writeBlock != 0;
        return (
            s.triggerBlock,
            s.triggerTime,
            s.writeBlock,
            s.writeTime,
            complete,
            complete ? s.writeBlock - s.triggerBlock : 0,
            complete ? s.writeTime - s.triggerTime : 0
        );
    }
}
