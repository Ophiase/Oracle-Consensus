import argparse
from pprint import pprint
import random
import sqlite3
from threading import Thread
import time
import eel
import numpy as np
from transformers import pipeline
from typing import List
import subprocess
import atexit
import web_interface
from web_interface import init_server

DB_PATH = "db.sqlite"
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

# ---------------------------------------------------

def gen_classifier():
    return pipeline(task="text-classification", model="SamLowe/roberta-base-go_emotions", top_k=None)

def prediction_to_vector(prediction : dict) -> np.array :
    result = LABELS.copy()
    
    for item in prediction:
        if item['label'] in result:
            result[item['label']] = item['score']

    return np.array([result[label] for label in LABELS])

def sentiment_analysis(classifier, inputs : List[str]) -> List[np.array]:
    return [
        prediction_to_vector(specific_output) for specific_output in classifier(inputs)
    ]

# ---------------------------------------------------

def read_all_from_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('SELECT * FROM comments')
    rows = c.fetchall()
    conn.close()

    for row in rows:
        print(row)

def read_window_from_db(position):
    conn = sqlite3.connect(DB_PATH)
    
    # fetch the number of elements :
    c = conn.cursor()
    c.execute('SELECT COUNT(id) FROM comments LIMIT 1')
    N = c.fetchall()[0][0]
    
    position = (position + PREDICTION_WINDOW) % N
    if position + PREDICTION_WINDOW >= N : position = 0 

    # fetch from position in db
    c = conn.cursor()
    c.execute(
        f'''
        SELECT comment FROM comments
        WHERE id >= {position}
        ORDER BY id ASC LIMIT 30
        ''')
    
    result = [ x[0] for x in c.fetchall() ]
    print("fetched data from db: " + str(len(result)))
    conn.close()
    return result, position

# ---------------------------------------------------

def gen_oracles_predictions(sentiment_analysis : List[np.array]) -> List[np.array] :
    '''
        Generates stochasticaly an oracle prediction gathering data
        from the latest sentiment analysis results with bootstrapping.
    '''
    oracles_values = []

    for i in range(N_ORACLES):
        value = 0
        if i < N_FAILING_ORACLES:
            value = np.random.uniform(0, 1, DIMENSION)
        else :
            subset = random.sample(sentiment_analysis, BOOTSTRAPING_SUBSET)
            value = np.mean(subset, axis=0)
        oracles_values.append(value)

    # we shuffle the failing oracles :
    np.random.shuffle(oracles_values)

    return oracles_values

def predictions_to_eel_values(oracles_predictions):
    component = []
    for i in range(0, DIMENSION, 2) :
        two_components = i+1 < DIMENSION
        
        columnNames = [ LABELS_KEYS[i] ]
        columnNames.append( LABELS_KEYS[i + 1] if two_components else "None" )

        data = []
        for j in range(DIMENSION):
            data.append({
                'x': oracles_predictions[i][j],
                'y': oracles_predictions[i+1][j] if two_components else 0
            })

        component.append({
            'columnNames': columnNames,
            'data': data
        })

    # pprint(component)
    return component

# TODO:
def commit_predictions(oracles_predictions : List[np.array], dimension) -> None :
    eel.updateComponents(predictions_to_eel_values(oracles_predictions))
    
    # reduce dimension
    reduced_oracles_predictions = [ x[:dimension] for x in oracles_predictions ]
    # pprint("Last predictions: ")
    # pprint(reduced_oracles_predictions)

def simulation_mode(dimension) :
    print("------------------------")
    print("LAUNCH : Simulation Mode")
    print("------------------------")

    classifier = gen_classifier()
    position = 0
    while True:
        posts, position = read_window_from_db(position)
        
        sentiment_analysis_results = sentiment_analysis(classifier, posts)
        oracles_predictions = gen_oracles_predictions(sentiment_analysis_results)
        commit_predictions(oracles_predictions, dimension)

        eel.sleep(SIMULATION_REFRESH_RATE)

# TODO: 
def live_mode(refresh_rate, dimension):
    print("------------------")
    print("LAUNCH : Live Mode")
    print("------------------")

    classifier = gen_classifier()
    while True:
        # sentiment_analysis(classifier, )
        # 

        eel.sleep(refresh_rate)

# ---------------------------------------------------


def main():
    parser = argparse.ArgumentParser(description="Oracle Scheduler")

    parser.add_argument('--high_dimension', action='store_true', default=False)
    parser.add_argument('--live_mode', action='store_true', default=False)
    parser.add_argument('-scrapper', type=bool, default=False, help='Run the scrapper in background.')
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

    dimension = DIMENSION if args.high_dimension else 2

    init_server()
    eel.initComponents(DIMENSION // 2)

    if args.live_mode :
        Thread(target=lambda: live_mode(args.rate, dimension)).start()
    else :
        Thread(target=lambda: simulation_mode(dimension)).start()

    while True :
        eel.sleep(100)
    
    # print("Scheduler terminated.")

def cleanup(background_process) :
    # print("Cleaning up the background process...")
    background_process.terminate()
    background_process.wait()
    print("Scrapper terminated.")

if __name__ == "__main__":
    main()
