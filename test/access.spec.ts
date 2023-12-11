import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { describe, it } from "mocha";
import { ethers } from "hardhat";

describe("PublicLabels", () => {
  async function deployFixture() {
    const [admin, contrib1, contrib2, verifier1, verifier2, other1] =
      await ethers.getSigners();

    const PublicLabels = await ethers.getContractFactory("PublicLabels");
    const PL = await PublicLabels.connect(admin).deploy();

    return { PL, admin, contrib1, contrib2, verifier1, verifier2, other1 };
  }

  it("constructor", async () => {
    const { PL, admin } = await loadFixture(deployFixture);
    expect(
      await PL.hasRole(await PL.DEFAULT_ADMIN_ROLE(), admin.address)
    ).to.equal(true);
  });

  it("addContributor", async () => {
    const { PL, admin, contrib1 } = await loadFixture(deployFixture);
    expect(
      await PL.hasRole(await PL.CONTRIBUTOR_ROLE(), contrib1.address)
    ).to.equal(false);
    await PL.connect(admin).addContributor(contrib1.address);
    expect(
      await PL.hasRole(await PL.CONTRIBUTOR_ROLE(), contrib1.address)
    ).to.equal(true);
  });

  it("removeContributor", async () => {
    const { PL, admin, contrib1 } = await loadFixture(deployFixture);
    await PL.connect(admin).addContributor(contrib1.address);
    expect(
      await PL.hasRole(await PL.CONTRIBUTOR_ROLE(), contrib1.address)
    ).to.equal(true);
    await PL.connect(admin).removeContributor(contrib1.address);
    expect(
      await PL.hasRole(await PL.CONTRIBUTOR_ROLE(), contrib1.address)
    ).to.equal(false);
  });

  it("addVerifier", async () => {
    const { PL, admin, verifier1 } = await loadFixture(deployFixture);
    expect(
      await PL.hasRole(await PL.VERIFIER_ROLE(), verifier1.address)
    ).to.equal(false);
    await PL.connect(admin).addVerifier(verifier1.address);
    expect(
      await PL.hasRole(await PL.VERIFIER_ROLE(), verifier1.address)
    ).to.equal(true);
  });

  it("removeVerifier", async () => {
    const { PL, admin, verifier1 } = await loadFixture(deployFixture);
    await PL.connect(admin).addVerifier(verifier1.address);
    expect(
      await PL.hasRole(await PL.VERIFIER_ROLE(), verifier1.address)
    ).to.equal(true);
    await PL.connect(admin).removeVerifier(verifier1.address);
    expect(
      await PL.hasRole(await PL.VERIFIER_ROLE(), verifier1.address)
    ).to.equal(false);
  });

  it("approvePendingChanges", async () => {
    const { PL, admin, contrib1 } = await deployFixture();

    await PL.connect(admin).addContributor(contrib1.address);

    const label = "New Label";
    const addr = ethers.Wallet.createRandom().address;
    await PL.connect(contrib1).setLabels([addr], [label]);

    // Get the pending change ID (assuming it's the first and only one)
    const pendingChangeId = 0;

    const tx = await PL.connect(admin).approvePendingChanges([pendingChangeId]);
    const receipt = await tx.wait();

    // Filter EntryChange event
    const eventFilter = PL.filters.EntryChange();
    const events = await PL.queryFilter(
      eventFilter,
      receipt?.blockNumber,
      receipt?.blockNumber
    );

    expect(events.length).to.be.greaterThan(0);
    const event = events[0];
    expect(event.args.addr).to.equal(addr);
    expect(event.args.label).to.equal(label);
    const VERIFIED = 2;
    expect(event.args.state).to.equal(VERIFIED);
  });

  it("rejectPendingChanges", async function () {
    const { PL, admin, contrib1 } = await deployFixture();

    await PL.connect(admin).addContributor(contrib1.address);

    const addr = ethers.Wallet.createRandom().address;
    const label = "Test Label";
    await PL.connect(contrib1).setLabels([addr], [label]);

    // Assuming the pending change ID is 0 (since it's the first)
    const pendingChangeId = 0;

    const tx = await PL.connect(admin).rejectPendingChanges([pendingChangeId]);
    const receipt = await tx.wait();

    // Filter PendingChange event
    const eventFilter = PL.filters.PendingChange();
    const events = await PL.queryFilter(
      eventFilter,
      receipt?.blockNumber,
      receipt?.blockNumber
    );

    expect(events.length).to.be.greaterThan(0);
    const event = events.find(
      (e: any) => Number(e.args.changeId) === pendingChangeId
    );
    expect(event).to.not.be.undefined;
  });

  it("setLabels by Contributor", async function () {
    const { PL, admin, contrib1 } = await deployFixture();

    const tx1 = await PL.connect(admin).addContributor(contrib1.address);
    await tx1.wait();

    const addr = ethers.Wallet.createRandom().address;
    const label = "Test Label";

    // Contributor sets label
    const tx2 = await PL.connect(contrib1).setLabels([addr], [label]);
    await tx2.wait();

    // Get the pending change ID (assuming it's the first and only one)
    const pendingChangeId = 0;
    const tx3 = await PL.connect(admin).approvePendingChanges([
      pendingChangeId,
    ]);
    const receipt = await tx3.wait();

    // Check for PendingChange event
    const eventFilter = PL.filters.EntryChange();
    const events = await PL.queryFilter(
      eventFilter,
      receipt?.blockNumber,
      receipt?.blockNumber
    );

    expect(events.length).to.be.greaterThan(0);
    const event = events.find(
      (e) => e.args.addr === addr && e.args.label === label
    );
    expect(event).to.not.be.undefined;
  });

  it("setLabels by Admin", async function () {
    const { PL, admin } = await deployFixture();

    const addr = ethers.Wallet.createRandom().address;
    const label = "Test Label";

    const tx = await PL.connect(admin).setLabels([addr], [label]);
    const receipt = await tx.wait();

    // Check for PendingChange event
    const eventFilter = PL.filters.EntryChange();
    const events = await PL.queryFilter(
      eventFilter,
      receipt?.blockNumber,
      receipt?.blockNumber
    );

    expect(events.length).to.be.greaterThan(0);
    const event = events.find(
      (e) => e.args.addr === addr && e.args.label === label
    );
    expect(event).to.not.be.undefined;
  });
});
