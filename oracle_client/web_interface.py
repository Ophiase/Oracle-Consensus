import eel
import time
from threading import Thread
from oracle_scheduler import simulation_mode, simulation_fetch, gen_classifier
from common import globalState
from contract import call_consensus, call_first_pass_consensus_reliability, \
call_second_pass_consensus_reliability, update_all_the_predictions, \
invoke_update_proposition, invoke_vote_for_a_proposition, \
call_replacement_propositions, call_dimension, call_oracle_list, \
call_admin_list, call_consensus_active

# ----------------------------------------------------------------------

HELP = '''
Commands :
    - help / clear / exit
    
    - fetch

    - live_mode on/off (default: off)
    - auto_fetch on/off (default: off)
    - scraper on/off (default: off)

    - (S) commit (call update_proposition for each oracle)
    
    - (S) resume
    - (S) consensus
    - (S) reliability_first_pass
    - (S) reliability
    
    - (S) is_consensus_active

    - (S) admin_list
    - (S) oracle_list
    - (S) dimension
    - (S) replacement_propositions

    - (S) update_proposition <caller_admin> None
    - (S) update_proposition <caller_admin> <old_oracle> <new_oracle>
    - (S) vote_for_a_proposition <caller_admin> <which_admin>

For <admin> <oracle> arguments, you can either specify the index in the contract or the address starting with "0x"

(S) indicates an interaction with Sepolia
'''

# ----------------------------------------------------------------------

def init_server():
    print("Starting graphical interface...")
    eel.init('web')
    eel.start('index.html',
            mode='default',
            host='localhost',
            block=False)

# ----------------------------------------------------------------------

def on_off_to_bool(x):
    return True if x == "on" else False

def unexpected_argument(n, x) -> bool :
    if n != len(x) :
        eel.writeToConsole("Unexpected number of arguments.")
    return n != len(x)

def not_implemented() : eel.writeToConsole("Not implemented yet.")

@eel.expose
def query(text : str):
    print(f"Query : {text}")

    splitted = text.split()
    if len(splitted) == 0:
        return
    match splitted[0] :

        # -------------------------------------

        case "fetch":
            print("Processing ..")
            simulation_fetch(gen_classifier())
        case "auto_fetch":
            if unexpected_argument(2, splitted) : return
            globalState.auto_fetch = on_off_to_bool(splitted[1])
            if globalState.auto_fetch :
                eel.writeToConsole("Auto-Fetch: ENABLED")
                simulation_mode()
            else :
                eel.writeToConsole("Auto-Fetch: DISABLE")
        case "commit":
            if globalState.remote_dimension is None :
                call_dimension()

            predictions = globalState.predictions
            if predictions is None :
                eel.writeToConsole("Fetch before!")
            else :
                eel.writeToConsole("Commit predictions...")
                update_all_the_predictions(predictions)
                eel.writeToConsole("Done.")
        case "consensus" :
            consensus = call_consensus()
            eel.writeToConsole("consensus : " + str([
                f"{x:0.2f}" for x in consensus
            ]))
        case "reliability_first_pass" :
            eel.writeToConsole(f"reliability_first_pass : {call_first_pass_consensus_reliability()}")
        case "reliability" :
            eel.writeToConsole(f"reliability : {call_second_pass_consensus_reliability()}")
        
        case "resume" :
            for x in ["consensus", "reliability_first_pass", "reliability"] :
                query(x)

        case "live_mode" : not_implemented()
        case "scraper" : NotImplemented()

        case "is_consensus_active" : 
            eel.writeToConsole(f"Is consensus active: {call_consensus_active()}")
        case "admin_list" : 
            eel.writeToConsole(f"Admin list: {call_admin_list()}")
        case "oracle_list" : 
            eel.writeToConsole(f"Oracle list: {call_oracle_list()}")
        case "dimension" : 
            eel.writeToConsole(f"Dimension: {call_dimension()}")

        case "replacement_propositions" : 
            eel.writeToConsole(f"Replacement propositions: {call_consensus_active()}")

        case "update_proposition" : not_implemented() # <caller_admin> None
        # case "update_proposition" : not_implemented() # <caller_admin> <old_oracle> <new_oracle>
        
        case "vote_for_a_proposition" : not_implemented() # <caller_admin> <which_admin>

        # -------------------------------------

        case "clear": eel.clearConsole()
        case "help" : eel.writeToConsole(HELP)
        case "exit" : exit()
        case "" : pass
        case _ : eel.writeToConsole("invalid command")