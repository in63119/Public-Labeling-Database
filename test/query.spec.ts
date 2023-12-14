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

  it("pendingChanges should return the correct entries", async function () {
    const { PL, admin, contrib1 } = await loadFixture(deployFixture);

    await PL.connect(admin).addContributor(contrib1.address);

    const labels = ["Label1", "Label2", "Label3"];
    const addrs = labels.map(() => ethers.Wallet.createRandom().address);

    for (let i = 0; i < labels.length; i++) {
      await PL.connect(contrib1).setLabels([addrs[i]], [labels[i]]);
    }

    const start = 0;
    const limit = 2;
    const [returnedAddrs, returnedEntries] = await PL.connect(
      admin
    ).pendingChanges(start, limit);

    expect(returnedAddrs.length).to.equal(limit);
    for (let i = 0; i < limit; i++) {
      expect(returnedAddrs[i]).to.equal(addrs[i]);
      expect(returnedEntries[i].label).to.equal(labels[i]);
    }
  });
});
