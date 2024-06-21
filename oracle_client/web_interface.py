import eel
import time
from threading import Thread

def init_server():
    print("Starting graphical interface...")
    eel.init('web')
    eel.start('index.html',
            mode='default',
            host='localhost',
            block=False)