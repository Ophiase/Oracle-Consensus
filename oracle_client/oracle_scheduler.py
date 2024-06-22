from pprint import pprint
import random
import sqlite3
from threading import Thread
import time
import eel
import numpy as np
from transformers import pipeline
from typing import List
import time
from datetime import datetime, timezone
from common import globalState, DB_PATH, N_ORACLES, N_FAILING_ORACLES, SIMULATION_REFRESH_RATE, PREDICTION_WINDOW, BOOTSTRAPING_SUBSET, LABELS, LABELS_KEYS, DIMENSION

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
        SELECT comment, timestamp FROM comments
        WHERE id >= {position}
        ORDER BY id ASC LIMIT 30
        ''')
    
    result = c.fetchall()
    comments = [ x[0] for x in result ]
    dates = [ x[1] for x in result ]
    conn.close()

    return comments, dates, position

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

def show_predictions(oracles_predictions : List[np.array], timestamps : List[str], dimension : int) -> None :
    eel.updateComponents(predictions_to_eel_values(oracles_predictions))

    # date = datetime.strptime(timestamps[-1], '%Y-%m-%d %H:%M:%S').astimezone(tz=timezone.fromutc) 
    eel.writeToConsole(f"fetched {len(oracles_predictions)} predictions from {timestamps[-1]} UTC")
    
    # # reduce dimension
    # reduced_oracles_predictions = [ x[:dimension] for x in oracles_predictions ]
    # pprint("Last predictions: ")
    # pprint(reduced_oracles_predictions)

def simulation_fetch(classifier) :
    posts, timestamps, globalState.simulation_step = read_window_from_db(globalState.simulation_step)
    sentiment_analysis_results = sentiment_analysis(classifier, posts)
    oracles_predictions = gen_oracles_predictions(sentiment_analysis_results)
    globalState.predictions = oracles_predictions
    
    show_predictions(oracles_predictions, timestamps, globalState.dimension)

def simulation_mode() :
    print("------------------------")
    print("LAUNCH : Simulation Auto")
    print("------------------------")

    classifier = gen_classifier()
    while globalState.auto_fetch:
        simulation_fetch(classifier)
        eel.sleep(SIMULATION_REFRESH_RATE)

# TODO: 
def live_mode():
    print("------------------")
    print("LAUNCH : Live Auto")
    print("------------------")

    classifier = gen_classifier()
    while True:
        # sentiment_analysis(classifier, )
        eel.sleep(globalState.refresh_rate)