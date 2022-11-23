// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Voting__TransferFailed();

contract Voting is ReentrancyGuard{

    // State variables
    uint256 public votingTimeLimit;
    uint256 public AMOUNT_TO_VOTE;
    uint256 private s_timePollBegins;
    uint256 public s_poolAmount;
    votingState private s_votingState;
    address public s_winningCandidate;
    candidate[] private s_candidates; 
    voter[] private s_voters; 

    event winnerPicked(address indexed player);
    event enterPoll(address indexed player);

    // Struct of a voter cotaining the address of the candidate they voted for and the amount of votes sent.
    struct voter {
        address candidateAddress;
        address voterAddress;
        uint256 votes;
        uint256 moneySent;
    }

    struct candidate {
        address candidateAddress;
        uint256 votes;
        uint256 poolAmount;
    }

    // Mapping of candidates address to the number of votes received
    mapping(address => candidate) public candidateToThereStats;

    // Mapping of candidate's address to the address of who voted for them.
    mapping(address => voter) public voterToVoterStats;

    // Mapping of voter to who they voted for
    mapping(address => address) public voterToCandidateAddr;

    // Enumeration of the states of the voting poll: Open, Closed
    enum votingState {
        OPEN,
        CLOSED
    }

    // Declare amount of time the voting poll will be open.
    // Declare amount required to vote.
    constructor(uint256 _time, uint256 _amount ) {
        votingTimeLimit = _time;
        AMOUNT_TO_VOTE = _amount;
        s_votingState = votingState.OPEN;
        s_timePollBegins = block.timestamp;
    }

    // 1. Send money to the contract to vote for a candidate.
    // 2. If the money sent meets required amount then pick a candidate to vote for, else revert tx.
    // 3. Update mapping of addresses of candidates mapping
    // 4. Check if the voting poll is open, if not revert.
    function vote(address candidateAddress, address voterAddress) external payable {
        require(voterToVoterStats[msg.sender].votes <= 1, "You have already voted");
        require(msg.value >= AMOUNT_TO_VOTE, "You must send more money to vote");
        require(s_votingState == votingState.OPEN, "Voting is closed");

        candidateToThereStats[candidateAddress].votes += 1;
        candidateToThereStats[candidateAddress].poolAmount += msg.value;
        voterToVoterStats[voterAddress].candidateAddress = candidateAddress;
        voterToVoterStats[voterAddress].votes += 1;
        voterToVoterStats[voterAddress].moneySent += msg.value;

        s_poolAmount += msg.value;

        emit enterPoll(msg.sender);
    }

    // 1. Close the voting poll
    // 2. Check to see which candidate had the most votes
    // 3. Send funds from the winning candidate pool to all voters who voted for the respective candidate.
    // 4. Open the voting poll again.
    function pickWinner() public nonReentrant {
        s_votingState = votingState.CLOSED;
        uint256 winningVoters = 0;
        address mostCandidateVotes;
        uint256 mostVotes = 0;
        for(uint n = 0; n < s_candidates.length; n++) {
            if(s_candidates[n].votes > mostVotes) {
                mostCandidateVotes = s_candidates[n].candidateAddress;
            }
        }
        s_winningCandidate = mostCandidateVotes;

        for(uint k = 0; k < s_voters.length; k++) {
            if(s_voters[k].candidateAddress == s_winningCandidate) {
                address winningVoter = s_voters[k].voterAddress;
                winningVoters += 1;
                candidateToThereStats[s_winningCandidate].poolAmount;
                uint256 amountPerWinner = s_poolAmount / winningVoters;
                (bool success, ) = winningVoter.call{value: (amountPerWinner)}("");
                
                if(!success) {
                    revert Voting__TransferFailed();
                }
            }
        }

        // s_candidates = new candidate [](0);
        // s_voters = new voter[](0);
        s_votingState = votingState.OPEN;
        s_timePollBegins = block.timestamp;
        emit winnerPicked(s_winningCandidate);
    }

    function getVotingState() public view returns (votingState) {
        return s_votingState;
    }

    function getWinningCandidate() public view returns (address) {
        return s_winningCandidate;
    }

    function getPollStartingTime() public view returns (uint256) {
        return s_timePollBegins;
    }

    function getVotingInterval() public view returns (uint256) {
        return votingTimeLimit;
    }

    function getNumberOfVoters() public view returns (uint256) {
        return s_voters.length;
    }

    function getEntranceFee() public view returns (uint256) {
        return AMOUNT_TO_VOTE;
    }
}