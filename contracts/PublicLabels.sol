// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IPublicLabels.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PublicLabels is IPublicLabels, AccessControl {
    bytes32 public constant CONTRIBUTOR_ROLE = keccak256("CONTRIBUTOR");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER");

    mapping(address => Entry) private entries;

    uint private nextPendingChangeId = 0;
    mapping(uint => address) public pendingChangeAddrs;
    mapping(uint => Entry) public pendingChangeEntries;

    constructor() {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _;
    }

    modifier onlyContributor() {
        require(
            hasRole(CONTRIBUTOR_ROLE, msg.sender),
            "Caller is not a contributor"
        );
        _;
    }

    // setters

    function addContributor(address addr) external onlyAdmin {
        grantRole(CONTRIBUTOR_ROLE, addr);
        emit AddContributor(addr);
    }

    function removeContributor(address addr) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        revokeRole(CONTRIBUTOR_ROLE, addr);
        emit RemoveContributor(addr);
    }

    function addVerifier(address addr) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        grantRole(VERIFIER_ROLE, addr);
        emit AddVerifier(addr);
    }

    function removeVerifier(address addr) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        revokeRole(VERIFIER_ROLE, addr);
        emit RemoveVerifier(addr);
    }

    function approvePendingChanges(uint[] memory changeIds) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");

        for (uint i = 0; i < changeIds.length; i++) {
            uint changeId = changeIds[i];
            require(changeId < nextPendingChangeId, "Invalid changeId");

            Entry memory pendingEntry = pendingChangeEntries[changeId];
            entries[pendingEntry.addr] = pendingEntry;
            emit EntryChange(
                pendingEntry.addr,
                pendingEntry.label,
                Status.VERIFIED
            );
            delete pendingChangeEntries[changeId];
        }
    }

    function rejectPendingChanges(uint[] memory changeIds) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");

        for (uint i = 0; i < changeIds.length; i++) {
            uint changeId = changeIds[i];
            require(changeId < nextPendingChangeId, "Invalid changeId");

            delete pendingChangeEntries[changeId];
            emit PendingChange(changeId);
        }
    }

    function setLabels(
        address[] memory addrs,
        string[] memory labels
    ) external {
        require(
            addrs.length == labels.length,
            "Address and label arrays length mismatch"
        );
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(CONTRIBUTOR_ROLE, msg.sender),
            "Not authorized"
        );

        for (uint i = 0; i < addrs.length; i++) {
            if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
                entries[addrs[i]] = Entry(
                    addrs[i],
                    labels[i],
                    entries[addrs[i]].state
                );
                emit EntryChange(addrs[i], labels[i], entries[addrs[i]].state);
            } else {
                _addPendingChange(addrs[i], labels[i]);
            }
        }
    }

    function setStates(
        address[] memory addrs,
        Status[] memory states
    ) external {
        require(
            addrs.length == states.length,
            "Address and state arrays length mismatch"
        );
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(VERIFIER_ROLE, msg.sender),
            "Not authorized"
        );

        for (uint i = 0; i < addrs.length; i++) {
            entries[addrs[i]].state = states[i];
            emit EntryChange(addrs[i], entries[addrs[i]].label, states[i]);
        }
    }

    // getters

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

    function getEntries(
        address[] memory addrs
    ) external view returns (Entry[] memory entries) {}

    function _addPendingChange(address addr, string memory label) internal {
        pendingChangeEntries[nextPendingChangeId] = Entry(
            addr,
            label,
            Status.LABELED
        );
        emit PendingChange(nextPendingChangeId);
        nextPendingChangeId++;
    }
}
