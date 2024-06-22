# Off Chain oracle model

In this folder there are 3 scripts :
- ``scraper.py`` :
    - It looks for new comments on Hackernews each 5 minutes and add them to the database.
- ``main.py`` : Web demonstration of the smart contract on Sepolia.
    - Simulate oracles
        - Use sentiment analysis to evaluate metrics
    - Two modes :
        - Real Time : wait for new content in the database
        - Simulation : Each $\delta$ time, take the $N$ next comments and update oracles.
            - At the end of the database, it goes back the beginning.

## Installation

Required : 
- firefox
- cargo : geckodriver
- python3 : selenium, transformers, eel

### Fill the following files (create them if necessary) :

``data/contract_info.json``
```json
{
    "rpc": "https://free-rpc.nethermind.io/sepolia-juno",
    "declared_address" : "<INSERT>",
    "deployed_address" : "<INSERT>"
}
```

Declaration/Deployment explained in [oracle_contract/README.md](oracle_contract/README.md)

``data/sepolia.json``
```json
{
    "admins_addresses": [
        "<INSERT>",
        "<INSERT>",
        "<INSERT>"
    ],
    "admins_private_keys": [
        "<INSERT>",
        "<INSERT>",
        "<INSERT>"
    ],
    "oracles_addresses" : [
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>"
    ],
    "oracles_private_keys": [
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>",
        "<INSERT>"
    ]
}
```

It's not safe to put your private keys in a json file. \
We assume you are using test accounts specificaly for Sepolia.

Remark: I deployed the contract with 7 oracles, thus I need 8 oracles to demonstrate client ability to replace oracles.

## Execution

The main program requires ``data/db.sqlite`` to fetch.

Launch ``scraper.py`` a first time to fill it (30 posts / 10 minutes with default parameters). 

It can also be executed at ``main.py`` startup with ``--scraper`` option.

```bash
python3 scraper.py # real time database
python3 main.py # simulate the oracles using real datas
```