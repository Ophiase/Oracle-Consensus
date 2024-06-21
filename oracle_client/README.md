# Off Chain oracle model

In this folder there are 3 scripts :
- ``scrapper.py`` :
    - Look for new comments on Hackernews each 5 minutes and add them to the database.
- ``oracle_scheduler.py`` :
    - Simulate oracles
        - Use sentiment analysis to evaluate metrics
    - Two modes :
        - Real Time : wait for new content in the database
        - Simulation : Each $\delta$ time, take the $N$ next comments and update oracles.
            - At the end of the database, it goes back the beginning.

## Installation

Required : 
- cargo : geckodriver
- python : selenium, transformers, eel

## Execution

```bash
python3 scrapper.py # real time database
python3 main.py # simulate the oracles using real datas
```