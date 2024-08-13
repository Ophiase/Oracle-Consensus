# Stochastic Vector Oracle Consensus

<p align="center">
    <img src="./resources/consensus_graphic_4.png" width=500>
</p>

Sponsorized by [ETH Global - StarkHack](https://ethglobal.com/events/starkhack). \
Prizes : 
- **Starkware** - Best use of Starknet Promising Projects
- **Nethermind** - Best Runner Up Integration of AI in transaction simulation

Establish on-chain consensus over predictions from multiple oracles that can evolve over time.
- ✅ Security: The consensus is implemented directly on the Starknet blockchain using smart contracts developed in Cairo.
- ✅ Robustness: The consensus resists failing oracles (e.g., bugs, hacks, statistical errors). Oracles that diverge too much from the group do not influence the consensus.
- ✅ Reliability: The consensus always provides reliability metrics for the algorithms using it.
- ✅ Durability: The consensus resists the test of time. If authorized by the smart contract, admins can vote to replace dead oracles (based on their divergence).

We also provide an oracle client for demonstration purposes.
- Data is scraped in real-time from Hacker News.
- Oracle predictions are based on sentiment analysis over stochastic samples of comments.

🚧 Warning: This project was developed as a proof of concept during a Hackaton. \
Therefore, the smart contracts and math tools will be obsolete in the future versions of Cairo/Starknet.


![](resources/application_screenshot.png)

## Documentations.

- Mathematical details : [documentation/README.md](documentation/README.md).
- Smart contract interface for oracles : [contract/README.md](contract/README.md).
- Oracle Client : [client/README.md](client/README.md).
