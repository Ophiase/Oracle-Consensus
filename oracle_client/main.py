from web_interface import init_server
import eel
import atexit
import subprocess
import atexit
import web_interface
import argparse
from threading import Thread
from common import globalState, DB_PATH, N_ORACLES, N_FAILING_ORACLES, SIMULATION_REFRESH_RATE, PREDICTION_WINDOW, BOOTSTRAPING_SUBSET, LABELS, LABELS_KEYS, DIMENSION

def main():
    parser = argparse.ArgumentParser(description="Oracle Scheduler")

    parser.add_argument('--high_dimension', action='store_true', default=False, help='High dimension contract')
    parser.add_argument('--live_mode', action='store_true', default=False)
    parser.add_argument('--scrapper', action='store_true', default=False, help='Run the scrapper in background.')
    parser.add_argument('--rate', type=int, default=30*60, help='Scrapper Refresh interval in seconds')
    
    args = parser.parse_args()
    
    print("------------------------------------")

    if not args.scrapper and args.live_mode :
        print("Info: Simulation mode disabled. Either run the scrapper externaly or restart this application with -scrapper.")

    if not args.live_mode :
        print(f"Info: Simulation mode requires at least {PREDICTION_WINDOW} posts in {DB_PATH}")

    if args.scrapper :
        background_process = subprocess.Popen(["python3", "scrapper", "--rate", args.rate])
        atexit.register(lambda: cleanup(background_process))

    globalState.dimension = DIMENSION if args.high_dimension else 2

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
    print("Scrapper terminated.")

if __name__ == "__main__":
    main()
