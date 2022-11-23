const { assert, expect } = require('chai');
const { ethers } = require('hardhat');

const { time } = require("@nomicfoundation/hardhat-network-helpers")

describe("Voting Poll Unit Tests", function () {
    let votingContract, voting, entranceFee, interval, voter1, voter2

    beforeEach(async () => {
        let accounts = ethers.getSigners()
        voter1 = accounts[0]
        voter2 = accounts[1]
        votingContract = await ethers.getContract("Voting")
        voting = votingContract.connect(voter1);
        interval = voting.get
    })
})