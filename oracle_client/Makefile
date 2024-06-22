import_contracts:
	rm -rf contracts
	mkdir contracts 
	cp -r ../oracle_contract/target/dev/* contracts

run_scraper:
	python3 scraper.py

run:
	python3 main.py

# run_live:
# 	python3 main.py --simulation_mode 0

# run_server:
# 	python3 -m http.server 8000