import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import time

print("SETTING DB NAW")

con = psycopg2.connect(database="connections", user='postgres' ,host='db', password='plzwork')

#TODO
con.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT);
 
cursor = con.cursor();

try: 
	cursor.execute(""" CREATE TABLE ip (
        user_ip VARCHAR(15) NOT NULL,
        t1  TIMESTAMP
        );
        """)

except Exception as e:
	print(e)

con.close()