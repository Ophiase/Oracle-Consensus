import eel
import time
from threading import Thread
from oracle_scheduler import simulation_mode, simulation_fetch, gen_classifier
from common import globalState
from contract import call_consensus, call_first_pass_consensus_reliability, \
call_second_pass_consensus_reliability, update_all_the_predictions, \
invoke_update_proposition, invoke_vote_for_a_proposition, \
call_replacement_propositions, call_dimension, call_oracle_list, \
call_admin_list, call_consensus_active, call_skewness, call_kurtosis

# ----------------------------------------------------------------------

HELP = '''
Commands :
    - help / clear / exit
    
    - fetch

    - live_mode on/off (default: off)
    - auto_fetch on/off (default: off)
    - scraper on/off (default: off)

    - contract_declaration_address
    - contract_address

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

---------------------------------------

'''

#     - set_component <component> (max : contract_dimension / local_prediction_dimension)

# ----------------------------------------------------------------------

def init_server():
    print("Starting graphical interface...")
    eel.init('web')
    eel.start('index.html',
            mode='default',
            host='localhost',
            block=False)

# ----------------------------------------------------------------------

# def address_as_hex(input: str) -> int :
#     if str.startswith(input, "0x") :
#         pass

# def address_as_index(input: str) -> int :pass

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

        case "contract_declaration_address" :
            eel.writeToConsole(f"Contract Declaration Address :\n{globalState.DECLARED_ADDRESS}")            

        case "contract_address" :
            eel.writeToConsole(f"Contract Address :\n{globalState.DEPLOYED_ADDRESS}")

        # case "get_component" :
        #     eel.writeToConsole("Active component: " + str(globalState.active_component))

        # case "set_component" :
        #     if unexpected_argument(2, splitted) : return
        #     component = int(splitted[1])
        #     globalState.active_component = component
        #     eel.writeToConsole(f"Switched to :{globalState.active_component}")

        case "fetch":
            eel.writeToConsole("Processing ..")
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
            eel.writeToConsole("consensus :\n" + ','.join([
                f"{x:0.2f}" for x in consensus
            ]))
        case "reliability_first_pass" :
            eel.writeToConsole(f"reliability_first_pass : {call_first_pass_consensus_reliability()}")
            eel.updateProgressBar(
                0, int(globalState.remote_first_pass_consensus_reliability*100)
            )
        case "reliability" :
            eel.writeToConsole(f"reliability : {call_second_pass_consensus_reliability()}")
            eel.updateProgressBar(
                1, int(globalState.remote_second_pass_consensus_reliability*100)
            )
        
        case "resume" :
            for x in ["consensus", "reliability_first_pass", "reliability"] :
                query(x)

            active = globalState.remote_consensus_active
            consensus = globalState.remote_consensus
            
            fpr = globalState.remote_first_pass_consensus_reliability
            spr = globalState.remote_second_pass_consensus_reliability

            skewness = call_skewness()
            kurtosis = call_kurtosis()

            eel.setSepoliaConsole(
                f"consensus_active: {active} \n" + 
                f"consensus : " + ', '.join([f"{x:0.2f}" for x in consensus]) + "\n" +
                f"reliability_first_pass : {fpr:0.3f} \n" +
                f"reliability_second_pass : {spr:0.3f}\n" +
                f"skewness : " + ', '.join([f"{x:0.2f}" for x in skewness]) + "\n" +
                f"kurtosis : " + ', '.join([f"{x:0.2f}" for x in kurtosis])
            )

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