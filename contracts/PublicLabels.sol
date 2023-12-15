// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IPublicLabels.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PublicLabels is IPublicLabels, AccessControl {
  bytes32 public constant CONTRIBUTOR_ROLE = keccak256("CONTRIBUTOR");
  bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER");

  uint private nextPendingChangeId = 0;

  mapping(bytes32 => address[]) private roleMembers;
  mapping(address => Entry) private entries;
  mapping(uint => address) public pendingChangeAddrs;
  mapping(uint => Entry) public pendingChangeEntries;

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
    _;
  }

  modifier onlyAdminOrContributor() {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
        hasRole(CONTRIBUTOR_ROLE, msg.sender),
      "Not authorized"
    );
    _;
  }

  modifier onlyAdminOrVerifier() {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
        hasRole(VERIFIER_ROLE, msg.sender),
      "Not authorized"
    );
    _;
  }

  // setters

  function addContributor(address addr) external onlyAdmin {
    grantRole(CONTRIBUTOR_ROLE, addr);
    roleMembers[CONTRIBUTOR_ROLE].push(addr);
    emit AddContributor(addr);
  }

  function removeContributor(address addr) external onlyAdmin {
    uint roleIndex = _findRoleIndex(CONTRIBUTOR_ROLE, addr);

    require(
      roleIndex != roleMembers[CONTRIBUTOR_ROLE].length,
      "Not a CONTRIBUTOR address."
    );

    roleMembers[CONTRIBUTOR_ROLE][roleIndex] = roleMembers[CONTRIBUTOR_ROLE][
      roleMembers[CONTRIBUTOR_ROLE].length - 1
    ];
    roleMembers[CONTRIBUTOR_ROLE].pop();

    revokeRole(CONTRIBUTOR_ROLE, addr);
    emit RemoveContributor(addr);
  }

  function addVerifier(address addr) external onlyAdmin {
    grantRole(VERIFIER_ROLE, addr);
    emit AddVerifier(addr);
  }

  function removeVerifier(address addr) external onlyAdmin {
    revokeRole(VERIFIER_ROLE, addr);
    emit RemoveVerifier(addr);
  }

  function approvePendingChanges(uint[] memory changeIds) external onlyAdmin {
    for (uint i = 0; i < changeIds.length; i++) {
      uint changeId = changeIds[i];
      require(changeId < nextPendingChangeId, "Invalid changeId");

      address addr = pendingChangeAddrs[changeId];
      Entry memory pendingEntry = pendingChangeEntries[changeId];
      entries[addr] = Entry(pendingEntry.label, Status.VERIFIED);
      emit EntryChange(addr, pendingEntry.label, Status.VERIFIED);

      delete pendingChangeAddrs[changeId];
      delete pendingChangeEntries[changeId];
    }
  }

  function rejectPendingChanges(uint[] memory changeIds) external onlyAdmin {
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
  ) external onlyAdminOrContributor {
    require(
      addrs.length == labels.length,
      "Address and label arrays length mismatch"
    );

    bool isAdmin = false;

    if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
      isAdmin = true;
    }

    for (uint i = 0; i < addrs.length; i++) {
      address addr = addrs[i];
      if (isAdmin) {
        Entry memory currentEntry = entries[addr];
        entries[addr] = Entry(labels[i], currentEntry.state);
        emit EntryChange(addr, labels[i], currentEntry.state);
      } else {
        _addPendingChange(addr, labels[i]);
      }
    }
  }

  function setStates(
    address[] memory addrs,
    Status[] memory states
  ) external onlyAdminOrVerifier {
    require(
      addrs.length == states.length,
      "Address and state arrays length mismatch"
    );

    for (uint i = 0; i < addrs.length; i++) {
      address addr = addrs[i];
      Entry memory currentEntry = entries[addr];
      entries[addr] = Entry(currentEntry.label, states[i]);
      emit EntryChange(addr, currentEntry.label, states[i]);
    }
  }

  // getters

  function allContributors() external view returns (address[] memory) {
    return roleMembers[CONTRIBUTOR_ROLE];
  }

  function allVerfiers() external view returns (address[] memory) {
    return roleMembers[VERIFIER_ROLE];
  }

  function pendingChanges(
    uint start,
    uint limit
  ) external view returns (address[] memory addr, Entry[] memory entries) {
    uint count = 0;

    for (uint i = start; i < nextPendingChangeId && count < limit; i++) {
      if (bytes(pendingChangeEntries[i].label).length != 0) {
        count++;
      }
    }

    addr = new address[](count);
    entries = new Entry[](count);

    count = 0;
    for (uint i = start; i < nextPendingChangeId && count < limit; i++) {
      if (bytes(pendingChangeEntries[i].label).length != 0) {
        addr[count] = pendingChangeAddrs[i];
        entries[count] = pendingChangeEntries[i];
        count++;
      }
    }

    return (addr, entries);
  }

  function allEntries(
    uint start,
    uint limit
  ) external view returns (Entry[] memory _entries) {
    uint totalEntries = 0;

    for (uint i = start; totalEntries < limit && i < nextPendingChangeId; i++) {
      if (bytes(pendingChangeEntries[i].label).length != 0) {
        totalEntries++;
      }
    }

    Entry[] memory _entries = new Entry[](totalEntries);
    uint index = 0;

    for (uint i = start; index < totalEntries && i < nextPendingChangeId; i++) {
      if (bytes(pendingChangeEntries[i].label).length != 0) {
        _entries[index] = pendingChangeEntries[i];
        index++;
      }
    }

    return _entries;
  }

  function getEntries(
    address[] memory addrs
  ) external view returns (Entry[] memory _entries) {
    Entry[] memory _entries = new Entry[](addrs.length);

    for (uint i = 0; i < addrs.length; i++) {
      _entries[i] = entries[addrs[i]];
    }

    return _entries;
  }

  function _addPendingChange(address addr, string memory label) internal {
    pendingChangeEntries[nextPendingChangeId] = Entry(label, Status.LABELED);
    pendingChangeAddrs[nextPendingChangeId] = addr;
    emit PendingChange(nextPendingChangeId);
    nextPendingChangeId++;
  }

  function _findRoleIndex(
    bytes32 role,
    address addr
  ) internal view returns (uint) {
    for (uint i = 0; i < roleMembers[role].length; i++) {
      if (roleMembers[role][i] == addr) {
        return i;
      }
    }

    return roleMembers[role].length;
  }
}
