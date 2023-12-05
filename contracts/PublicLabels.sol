// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IPublicLabels.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PublicLabels is IPublicLabels, Ownable {
  mapping(address => bool) private contributors;
  mapping(address => bool) private verifiers;
  mapping(address => Entry) private addressToEntry;
  mapping(uint => Entry) public pendingEntryById;

  uint private nextChangeId = 0;

  constructor() Ownable(msg.sender) {}

  // setters

  function addContributor(address addr) external onlyOwner {
    require(!_isContributor(addr), "Address is already a contributor");
    contributors[addr] = true;
    emit AddContributor(addr);
  }

  function removeContributor(address addr) external onlyOwner {
    require(_isContributor(addr), "Address is not a contributor");
    contributors[addr] = false;
    emit RemoveContributor(addr);
  }

  function addVerifier(address addr) external onlyOwner {
    require(!_isVerifier(addr), "Address is already a verifier");
    verifiers[addr] = true;
    emit AddVerifier(addr);
  }

  function removeVerifier(address addr) external onlyOwner {
    require(_isVerifier(addr), "Address is not a verifier");
    verifiers[addr] = false;
    emit RemoveVerifier(addr);
  }

  function approvePendingChanges(uint[] memory changeIds) external onlyOwner {
    for (uint i = 0; i < changeIds.length; i++) {
      uint changeId = changeIds[i];
      require(changeId < nextChangeId, "Invalid changeId");

      Entry memory pendingEntry = pendingEntryById[changeId];
      addressToEntry[pendingEntry.addr] = pendingEntry;
      emit EntryChange(pendingEntry.addr, pendingEntry.label, Status.VERIFIED);
      delete pendingEntryById[changeId];
    }
  }

  function rejectPendingChanges(uint[] memory changeIds) external onlyOwner {
    for (uint i = 0; i < changeIds.length; i++) {
      uint changeId = changeIds[i];
      require(changeId < nextChangeId, "Invalid changeId");

      delete pendingEntryById[changeId];
      emit PendingChange(changeId);
    }
  }

  function setLabels(address[] memory addrs, string[] memory labels) external {
    require(
      addrs.length == labels.length,
      "Address and label arrays length mismatch"
    );
    require(
      msg.sender == owner() || _isContributor(msg.sender),
      "Not authorized"
    );

    for (uint i = 0; i < addrs.length; i++) {
      if (msg.sender == owner()) {
        addressToEntry[addrs[i]] = Entry(
          addrs[i],
          labels[i],
          addressToEntry[addrs[i]].state
        );
        emit EntryChange(addrs[i], labels[i], addressToEntry[addrs[i]].state);
      } else {
        _addPendingChange(addrs[i], labels[i]);
      }
    }
  }

  function setStates(address[] memory addrs, Status[] memory states) external {
    require(
      addrs.length == states.length,
      "Address and state arrays length mismatch"
    );
    require(msg.sender == owner() || _isVerifier(msg.sender), "Not authorized");

    for (uint i = 0; i < addrs.length; i++) {
      addressToEntry[addrs[i]].state = states[i];
      emit EntryChange(addrs[i], addressToEntry[addrs[i]].label, states[i]);
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

  function entries(
    address[] memory addrs
  ) external view returns (Entry[] memory entries) {}

  // helpers
  function _isContributor(address addr) internal view returns (bool) {
    return contributors[addr];
  }

  function _isVerifier(address addr) internal view returns (bool) {
    return verifiers[addr];
  }

  function _addPendingChange(address addr, string memory label) internal {
    require(_isContributor(msg.sender), "Not authorized");

    pendingEntryById[nextChangeId] = Entry(addr, label, Status.LABELED);
    emit PendingChange(nextChangeId);
    nextChangeId++;
  }
}
