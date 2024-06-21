import sqlite3

DB_PATH = "db.sqlite"

def read_all_from_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('SELECT * FROM comments')
    rows = c.fetchall()
    conn.close()
    return rows

if __name__ == "__main__":
    rows = read_all_from_db()
    for row in rows:
        print(row)