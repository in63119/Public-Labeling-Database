// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPublicLabels {
  // types

  enum Status {
    NONE,
    LABELED,
    VERIFIED
  }

  struct Entry {
    string label;
    Status state;
  }

  // events

  event AddContributor(address indexed contributor);
  event RemoveContributor(address indexed contributor);
  event AddVerifier(address indexed verifier);
  event RemoveVerifier(address indexed verifier);
  event EntryChange(address indexed addr, string label, Status state);
  event PendingChange(uint indexed changeId);

  // setters

  function addContributor(address addr) external;

  function removeContributor(address addr) external;

  function addVerifier(address addr) external;

  function removeVerifier(address addr) external;

  function approvePendingChanges(uint[] memory changeIds) external;

  function rejectPendingChanges(uint[] memory changeIds) external;

  function setLabels(address[] memory addrs, string[] memory labels) external;

  function setStates(address[] memory addrs, Status[] memory states) external;

  // getters

  function allContributors() external view returns (address[] memory);

  function allVerfiers() external view returns (address[] memory);

  function pendingChanges(
    uint start,
    uint limit
  ) external view returns (address[] memory addr, Entry[] memory entries);

  function allEntries(
    uint start,
    uint limit
  ) external view returns (Entry[] memory _entries);

  function getEntries(
    address[] memory addrs
  ) external view returns (Entry[] memory _entries);
}
