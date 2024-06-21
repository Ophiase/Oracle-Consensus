import os

DB_PATH = os.path.join("data","db.sqlite")
N_ORACLES = 7
N_FAILING_ORACLES = 2

SIMULATION_REFRESH_RATE = 5 # seconds

# Simulation mode : 30 texts inputs each time (= number of elements on the comment page)
# Live mode : 30 last texts inputs
PREDICTION_WINDOW = 30
BOOTSTRAPING_SUBSET = 20 # oracle average on 10 elements of the prediction window

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

# -----------------------------------
# GLOBAL VARIABLES

class GlobalState:
    def __init__(self):
        self.application_on = True

        self.simulation_step = 0
        self.auto_fetch = False
        self.predictions = None
        self.dimension = DIMENSION


globalState = GlobalState()
