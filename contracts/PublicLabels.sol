// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IPublicLabels.sol";

contract PublicLabels is IPublicLabels {
    function addContributor(address addr) external {}

    function removeContributor(address addr) external {}

    function addVerifier(address addr) external {}

    function removeVerifier(address addr) external {}

    function approvePendingChanges(uint[] memory changeIds) external {}

    function rejectPendingChanges(uint[] memory changeIds) external {}

    function setLabels(
        address[] memory addrs,
        string[] memory labels
    ) external {}

    function setStates(
        address[] memory addrs,
        Status[] memory states
    ) external {}

    function allContributors() external view returns (address[] memory) {}

    function allVerfiers() external view returns (address[] memory) {}

    function pendingChanges(
        uint start,
        uint limit
    ) external view returns (address[] memory addr, Entry[] memory entries) {}

    function allEntries(
        uint start,
        uint limit
    ) external view returns (Entry[] memory entries) {}

    function entries(
        address[] memory addrs
    ) external view returns (Entry[] memory entries) {}
}
