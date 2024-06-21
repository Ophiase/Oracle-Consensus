# run_server:
# 	python3 -m http.server 8000

import_contracts:
	rm -rf contracts
	mkdir contracts 
	cp -r ../oracle_contract/target/dev/* contracts

run_only_scrapper:
	python3 scrapper.py

run_simulation:
	python3 oracle_scheduler.py

run_live:
	python3 oracle_scheduler.py --simulation_mode 0