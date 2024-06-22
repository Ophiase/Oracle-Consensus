import json
import os
from starknet_py.net.full_node_client import FullNodeClient

# ----------------------------------------------------------------------

DB_PATH = os.path.join("data","db.sqlite")
N_ORACLES = 7
N_FAILING_ORACLES = 2

SIMULATION_REFRESH_RATE = 5 # seconds

# Simulation mode : 30 texts inputs each time (= number of elements on the comment page)
# Live mode : 30 last texts inputs
PREDICTION_WINDOW = 50
BOOTSTRAPING_SUBSET = 10 # oracle average on 10 elements of the prediction window

# https://huggingface.co/SamLowe/roberta-base-go_emotions
LABELS = {
    'optimism' : None,
    'anger' : None,
    'annoyance' : None,
    'excitement' : None,
    'nervousness' : None,
    'remorse' : None
}

LABELS_KEYS = list(LABELS.keys())
print(LABELS_KEYS)

DIMENSION = len(LABELS)

# ----------------------------------------------------------------------
# GLOBAL VARIABLES

class GlobalState:
    def __init__(self):
        self.application_on = True

        self.auto_fetch = False
        self.simulation_step = 0

        self.predictions = None
        self.dimension = DIMENSION

        self.remote_consensus = None
        self.remote_first_pass_consensus_reliability = None
        self.remote_second_pass_consensus_reliability = None
        self.remote_skewness = None
        self.remote_kurtosis = None

        self.remote_consensus_active = None
        self.remote_admin_list = None
        self.remote_oracle_list = None
        self.remote_dimension = None
        self.remote_replacement_propositions = None

        self.active_component = 0

        # -----------------------------

        with open(os.path.join('data', 'contract_info.json'), 'r') as file :
            data = json.load(file)
            self.RPC = data['rpc']
            self.DECLARED_ADDRESS = data['declared_address']
            self.DEPLOYED_ADDRESS = data['deployed_address']

        self.client = FullNodeClient(node_url=self.RPC)
        self.addresses = None
        self.private_keys = None

        self.admin_accounts = None
        self.oracle_accounts = None
        self.default_contract = None


globalState = GlobalState()
