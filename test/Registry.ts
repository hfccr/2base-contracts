import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
// import chai, { expect } from "chai";
// import chaiAsPromised from "chai-as-promised";
import hre from "hardhat";
import { parseEther } from "viem";
import { ProfileDetails } from "../types/registry";

// chai.use(chaiAsPromised);
const sendAmount = "0.0001";

describe("Registry", function () {
  // We define a fixture to reuse the same setup in every test.
  async function deployRegistryFixture() {
    const [owner, otherAccount, invitee] = await hre.viem.getWalletClients();

    const registry = await hre.viem.deployContract("Registry" as string);

    const publicClient = await hre.viem.getPublicClient();

    return {
      registry,
      owner,
      otherAccount,
      invitee,
      publicClient,
    };
  }

  describe("Invite and Claim", function () {
    it("Should successfully invite a profile", async function () {
      const { registry, invitee, publicClient } = await loadFixture(
        deployRegistryFixture
      );

      const profile = {
        id: "githubProfile",
        provider: 0, // github
      };

      const inviteAmount = parseEther(sendAmount);

      // Send the invite
      const hash = await registry.write.invite([profile], {
        value: inviteAmount,
        client: { wallet: invitee },
      });

      await publicClient.waitForTransactionReceipt({ hash });

      const balance = await registry.read.registry([0, "githubProfile"]);

      expect(balance).to.equal(inviteAmount);
    });

    it("Should fail to invite a profile with invalid amount", async function () {
      const { registry, invitee } = await loadFixture(deployRegistryFixture);

      const profile = {
        id: "githubProfile",
        provider: 0,
      };

      const invalidAmount = parseEther("0.0002");

      // Attempt to send invite with incorrect amount
      await expect(
        registry.write.invite([profile], {
          value: invalidAmount,
          client: { wallet: invitee },
        })
      ).to.be.rejectedWith("Invalid amount");
    });

    it("Should successfully claim a profile", async function () {
      const { registry, invitee, publicClient } = await loadFixture(
        deployRegistryFixture
      );

      const profile = {
        id: "githubProfile",
        provider: 0,
      };

      const inviteAmount = parseEther(sendAmount);

      // Send the invite
      await registry.write.invite([profile], {
        value: inviteAmount,
        client: { wallet: invitee },
      });

      // Claim the balance
      const hash = await registry.write.claim([profile], {
        client: { wallet: invitee },
      });

      await publicClient.waitForTransactionReceipt({ hash });

      const balanceAfterClaim = await registry.read.registry([
        0,
        "githubProfile",
      ]);

      expect(balanceAfterClaim).to.equal(0);
    });

    it("Should fail to claim an already claimed profile", async function () {
      const { registry, invitee } = await loadFixture(deployRegistryFixture);

      const profile = {
        id: "githubProfile",
        provider: 0,
      };

      const inviteAmount = parseEther(sendAmount);

      // Send the invite
      await registry.write.invite([profile], {
        value: inviteAmount,
        client: { wallet: invitee },
      });

      // Claim the balance
      await registry.write.claim([profile], {
        client: { wallet: invitee },
      });

      // Try claiming again, should fail
      await expect(
        registry.write.claim([profile], {
          client: { wallet: invitee },
        })
      ).to.be.rejectedWith("Profile already claimed");
    });
  });

  describe("Views", function () {
    it("Should return the invited profiles for a user", async function () {
      const { registry, invitee } = await loadFixture(deployRegistryFixture);

      const profile = {
        id: "githubProfile",
        provider: 0,
      };

      const inviteAmount = parseEther(sendAmount);

      await registry.write.invite([profile], {
        value: inviteAmount,
        client: { wallet: invitee },
      });

      const invitedProfiles = (await registry.read.viewInvitedProfiles(
        []
      )) as ProfileDetails[];

      expect(invitedProfiles).to.have.lengthOf(1);
      expect(invitedProfiles[0].id).to.equal("githubProfile");
    });

    it("Should return the correct balance and invite count for a profile", async function () {
      const { registry, invitee } = await loadFixture(deployRegistryFixture);

      const profile = {
        id: "githubProfile",
        provider: 0,
      };

      const inviteAmount = parseEther(sendAmount);

      // Send the invite
      await registry.write.invite([profile], {
        value: inviteAmount,
        client: { wallet: invitee },
      });

      const [balance, inviteCount] =
        (await registry.read.getProfileBalanceAndInviteCount([profile])) as [
          bigint,
          bigint
        ];

      expect(balance).to.equal(inviteAmount);
      expect(inviteCount).to.equal(1);
    });

    it("Should return the addresses with invite counts", async function () {
      const { registry, invitee } = await loadFixture(deployRegistryFixture);

      const profile = {
        id: "githubProfile",
        provider: 0,
      };

      const inviteAmount = parseEther(sendAmount);

      // Send the invite
      await registry.write.invite([profile], {
        value: inviteAmount,
        client: { wallet: invitee },
      });

      const [addresses, counts] =
        (await registry.read.getAddressesWithInviteCounts()) as [
          string[],
          number[]
        ];

      expect(addresses).to.include(invitee.account.address);
      expect(counts[0]).to.equal(1);
    });

    it("Should return the addresses with claimed invite counts", async function () {
      const { registry, invitee } = await loadFixture(deployRegistryFixture);

      const profile = {
        id: "githubProfile",
        provider: 0,
      };

      const inviteAmount = parseEther(sendAmount);

      // Send the invite
      await registry.write.invite([profile], {
        value: inviteAmount,
        client: { wallet: invitee },
      });

      // Claim the invite
      await registry.write.claim([profile], {
        client: { wallet: invitee },
      });

      const [addresses, claimedCounts] =
        (await registry.read.getAddressesWithClaimedInvites()) as [
          string[],
          number[]
        ];

      expect(addresses).to.include(invitee.account.address);
      expect(claimedCounts[0]).to.equal(1);
    });
  });
});
