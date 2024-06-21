import eel
import time
from threading import Thread
from oracle_scheduler import simulation_mode, simulation_fetch, gen_classifier
from common import globalState

# -----------------------------------

HELP = '''
Commands :
    - help / clear / exit
    
    - fetch

    - live_mode on/off (default: off)
    - auto_fetch on/off (default: off)
    - scrapper on/off (default: off)

    - (S) commit
    - (S) resume
    - (S) consensus
    - (S) reliability_first_pass
    - (S) reliability


(S) indicates an interaction with Sepolia
'''

# -----------------------------------

def init_server():
    print("Starting graphical interface...")
    eel.init('web')
    eel.start('index.html',
            mode='default',
            host='localhost',
            block=False)

# -----------------------------------

def on_off_to_bool(x):
    return True if x == "on" else False

def not_implemented() : eel.writeToConsole("not implemented yet")

@eel.expose
def query(text : str):
    print(f"Query : {text}")

    splitted = text.split()
    match splitted[0] :

        # -------------------------------------

        case "fetch":
            simulation_fetch(gen_classifier())
        case "auto_fetch":
            globalState.auto_fetch = on_off_to_bool(splitted[1])
            if globalState.auto_fetch :
                simulation_mode()
        case "commit": not_implemented()
        case "resume" : not_implemented()
        case "consensus" : not_implemented()
        case "reliability_first_pass" : not_implemented()
        case "reliability" : not_implemented()

        case "live_mode" : not_implemented()

        # -------------------------------------

        case "clear": not_implemented()
        case "help" :
            eel.writeToConsole(HELP)
        case "exit" :
            exit()
        case "" :
            pass
        case _ :
            eel.writeToConsole("invalid command")