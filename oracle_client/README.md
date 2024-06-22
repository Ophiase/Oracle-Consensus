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

## Execution

```bash
python3 scraper.py # real time database
python3 main.py # simulate the oracles using real datas
```