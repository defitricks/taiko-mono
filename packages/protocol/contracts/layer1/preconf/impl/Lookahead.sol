// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../shared/common/EssentialContract.sol";
import "../iface/ILookahead.sol";
import "../iface/IPreconfRegistry.sol";
import "../iface/IPreconfServiceManager.sol";
import "../libs/LibNames.sol";
import "../libs/LibEpoch.sol";

/// @title PreconfTaskManager
/// @custom:security-contact security@taiko.xyz
contract Lookahead is ILookahead, EssentialContract {
    using LibEpoch for uint256;

    uint256 private constant DISPUTE_PERIOD = 1 days;

    // Maps the epoch timestamp to the lookahead poster.
    // If the lookahead poster has been slashed, it maps to the 0-address.
    // Note: This may be optimised to re-use existing slots and reduce gas cost.
    mapping(uint256 epochTimestamp => address poster) internal posters;
    uint256[49] private __gap;

    bytes32 public immutable DOMAIN_SEPARATOR;

    error PreconferNotRegistered();
    error LookaheadIsNotRequired();

    uint256 public immutable beaconGenesisTimestamp;

    modifier onlyFromPreconfer() {
        address registry = resolve(LibNames.B_PRECONF_REGISTRY, false);
        require(
            IPreconfRegistry(registry).getPreconferIndex(msg.sender) != 0, PreconferNotRegistered()
        );
        _;
    }

    constructor(uint256 _beaconGenesisTimestamp) {
        beaconGenesisTimestamp = _beaconGenesisTimestamp;
    }

    /// @inheritdoc ILookahead
    function forcePostLookahead(LookaheadSetParam[] calldata _lookaheadSetParams)
        external
        onlyFromPreconfer
        nonReentrant
    {
        // Lookahead must be missing
        (uint256 currentEpochTimestamp, uint256 nextEpochTimestamp) =
            block.timestamp.getEpochTimestamp(beaconGenesisTimestamp);

        if (!_isLookaheadRequired(currentEpochTimestamp, nextEpochTimestamp)) {
            revert LookaheadIsNotRequired();
        }

        // Update the lookahead for next epoch
        _postLookahead(nextEpochTimestamp, _lookaheadSetParams);

        // Block the preconfer from withdrawing stake from Eigenlayer during the dispute window
        unchecked {
            IPreconfServiceManager(resolve(LibNames.B_PRECONF_SERVICE_MANAGER, false))
                .lockStakeUntil(msg.sender, block.timestamp + DISPUTE_PERIOD);
        }
    }

    /// @inheritdoc ILookahead
    function postLookahead(LookaheadSetParam calldata _lookaheadSetParams)
        external
        onlyFromNamed(LibNames.B_PRECONF_SERVICE_MANAGER)
        nonReentrant
    { }

    /// @inheritdoc ILookahead
    function isCurrentPreconfer(address addr) external view returns (bool) {
        //
    }

    /// @inheritdoc ILookahead
    function isLookaheadRequired() external view returns (bool) {
        (uint256 currentEpochTimestamp, uint256 nextEpochTimestamp) =
            block.timestamp.getEpochTimestamp(beaconGenesisTimestamp);

        return _isLookaheadRequired(currentEpochTimestamp, nextEpochTimestamp);
    }

    function _postLookahead(
        uint256 _epochTimestamp,
        LookaheadSetParam[] calldata _lookaheadSetParams
    )
        internal
    {
        // TODO
    }

    function _isLookaheadRequired(
        uint256 _currentEpochTimestamp,
        uint256 _nextEpochTimestamp
    )
        internal
        view
        returns (bool)
    {
        // If it's the first slot of current epoch, we don't need the lookahead since the offchain
        // node may not have access to it yet.
        return
            block.timestamp != _currentEpochTimestamp && posters[_nextEpochTimestamp] == address(0);
    }
}
