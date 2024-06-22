from web_interface import init_server
import eel
import atexit
import subprocess
import atexit
import web_interface
import argparse
from threading import Thread
from common import globalState, DB_PATH, N_ORACLES, N_FAILING_ORACLES, SIMULATION_REFRESH_RATE, PREDICTION_WINDOW, BOOTSTRAPING_SUBSET, LABELS, LABELS_KEYS, DIMENSION
from contract import retrieve_account_data

def main():
    parser = argparse.ArgumentParser(description="Oracle Scheduler")

    parser.add_argument('--disable_sepolia', action='store_true', default=False, help='Do not load data/sepolia.json by default')
    parser.add_argument('--dimension', type=int, default=DIMENSION, help='contract dimension')
    parser.add_argument('--live_mode', action='store_true', default=False)
    parser.add_argument('--scraper', action='store_true', default=False, help='Run the scraper in background.')
    parser.add_argument('--rate', type=int, default=int(30*60), help='scraper Refresh interval in seconds')
    
    args = parser.parse_args()
    
    print("------------------------------------")

    if not args.scraper and args.live_mode :
        print("Info: Simulation mode disabled. Either run the scraper externaly or restart this application with -scraper.")

    if not args.live_mode :
        print(f"Info: Simulation mode requires at least {PREDICTION_WINDOW} posts in {DB_PATH}")

    if args.scraper :
        background_process = subprocess.Popen(["python3", "scraper.py", "--rate", str(args.rate)])
        atexit.register(lambda: cleanup(background_process))

    globalState.dimension = args.dimension # DIMENSION if args.high_dimension else 2

    if not args.disable_sepolia :
        retrieve_account_data()

    init_server()
    eel.initComponents(DIMENSION // 2)

    # if args.live_mode :
    #     Thread(target=lambda: live_mode(args.rate, dimension)).start()

    # else :
    #     Thread(target=lambda: simulation_mode(dimension)).start()

    while globalState.application_on :
        eel.sleep(3)
    
    # print("Scheduler terminated.")

def cleanup(background_process) :
    # print("Cleaning up the background process...")
    background_process.terminate()
    background_process.wait()
    print("scraper terminated.")

if __name__ == "__main__":
    main()
