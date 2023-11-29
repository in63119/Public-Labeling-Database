// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPublicLabels {
    // types

    enum Status {
        NONE = 0,
        LABELED = 1,
        VERIFIED = 2,
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

    function addContributor(address addr) onlyOwner;
    function removeContributor(address addr) onlyOwner;
    function addVerifier(address addr) onlyOwner;
    function removeVerifier(address addr) onlyOwner;

    function approvePendingChanges(uint[] changeIds) onlyOwner
    function rejectPendingChanges(uint[] changeIds) onlyOwner

    function setLabels(address[] addrs, string[] labels) onlyContributor;
    function setStates(address[] addrs, Status[] states) onlyVerifier;

    // getters

    function allContributors() view returns (address[]);
    function allVerfiers() view returns (address[]);

    function pendingChanges(uint start, uint limit) view returns (address[] addr, Entry[] entries);

    function allEntries(uint start, uint limit) view returns (Entry[] entries);
    function entries(address[] addrs) view returns (Entry[] entries);
}
