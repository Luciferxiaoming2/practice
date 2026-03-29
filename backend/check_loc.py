import sqlite3
conn = sqlite3.connect('app/endpage.db')
cur = conn.cursor()
cur.execute('SELECT id, username, require_location, location_lat, location_lng, location_radius FROM users WHERE require_location=1')
rows = cur.fetchall()
for r in rows:
    print(r)
conn.close()
