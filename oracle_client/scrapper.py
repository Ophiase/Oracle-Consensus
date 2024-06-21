import sqlite3
import time
from datetime import datetime, timezone
from selenium import webdriver
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.firefox.options import Options
from typing import List
from pprint import pprint

GECKODRIVER_PATH = '~/.cargo/bin/geckodriver'
JS_PATH = "hn_scrapper.js"
URL = "https://news.ycombinator.com/newcomments"
DB_PATH = "db.sqlite"
REFRESH_INTERVAL = 10 * 60  # each 10 minutes

def init_driver():
    options = Options()
    options.add_argument('--headless') 
    driver = webdriver.Firefox(options=options)
    return driver

def find_js() -> str:
    with open(JS_PATH, "r") as file:
        return file.read()

def scrap(driver, js: str) -> List[str]:
    results = []
    try:
        driver.get(URL)
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.CLASS_NAME, "commtext")))
        results = driver.execute_script(js)
    finally:
        return results

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            comment TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

def save_to_db(comments: List[str]):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.executemany('INSERT INTO comments (comment) VALUES (?)', [(comment,) for comment in comments])
    conn.commit()
    conn.close()

def get_last_comment_time():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('SELECT timestamp FROM comments ORDER BY id DESC LIMIT 1')
    last_time = c.fetchone()
    conn.close()
    if last_time is None :
        return last_time
    return last_time[0]

def main():
    init_db()
    driver = init_driver()

    last_comment_time = get_last_comment_time()
    if last_comment_time:
        last_comment_time = datetime.strptime(last_comment_time, '%Y-%m-%d %H:%M:%S')
        time_since_last_comment = datetime.now().astimezone(tz=timezone.utc).replace(tzinfo=None) - last_comment_time
        if time_since_last_comment.total_seconds() < REFRESH_INTERVAL:
            time_to_wait = REFRESH_INTERVAL - time_since_last_comment.total_seconds()
            print(f"Please wait: {time_to_wait} seconds")
            time.sleep(time_to_wait)
    
    while True:
        js = find_js()
        comments = scrap(driver, js)
        save_to_db(comments)
        pprint(comments[0])
        
        time.sleep(REFRESH_INTERVAL)

if __name__ == "__main__":
    main()
