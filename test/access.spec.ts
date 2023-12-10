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
});
