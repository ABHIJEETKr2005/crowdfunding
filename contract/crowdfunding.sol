// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Crowdfunding {
    struct Campaign {
        address payable creator;
        string title;
        uint goal;
        uint deadline;
        uint amountRaised;
        bool claimed;
    }

    uint public campaignCount;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public contributions;

    event CampaignCreated(uint id, address creator, string title, uint goal, uint deadline);
    event ContributionReceived(uint id, address contributor, uint amount);
    event FundsClaimed(uint id, uint amount);
    event RefundIssued(uint id, address contributor, uint amount);

    function createCampaign(string memory _title, uint _goal, uint _duration) public {
        campaignCount++;
        campaigns[campaignCount] = Campaign(
            payable(msg.sender),
            _title,
            _goal,
            block.timestamp + _duration,
            0,
            false
        );
        emit CampaignCreated(campaignCount, msg.sender, _title, _goal, block.timestamp + _duration);
    }

    function contribute(uint _id) public payable {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Contribution must be more than 0");

        campaign.amountRaised += msg.value;
        contributions[_id][msg.sender] += msg.value;

        emit ContributionReceived(_id, msg.sender, msg.value);
    }

    function claimFunds(uint _id) public {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "Only campaign creator can claim");
        require(block.timestamp >= campaign.deadline, "Campaign not yet ended");
        require(campaign.amountRaised >= campaign.goal, "Funding goal not met");
        require(!campaign.claimed, "Funds already claimed");

        campaign.claimed = true;
        campaign.creator.transfer(campaign.amountRaised);

        emit FundsClaimed(_id, campaign.amountRaised);
    }

    function refund(uint _id) public {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.deadline, "Campaign not yet ended");
        require(campaign.amountRaised < campaign.goal, "Funding goal was met");

        uint contributed = contributions[_id][msg.sender];
        require(contributed > 0, "No contribution to refund");

        contributions[_id][msg.sender] = 0;
        payable(msg.sender).transfer(contributed);

        emit RefundIssued(_id, msg.sender, contributed);
    }
}
