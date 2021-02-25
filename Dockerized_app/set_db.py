import psycopg2
import os
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

print("Creating ip Table in Database...")

host = os.getenv('PGHOST')
database = os.environ.get('PGDATABASE')
user = os.getenv('PGUSER')
password = os.environ.get('PGPASSWORD')

con = psycopg2.connect(host=host, database=database, user=user, password=password)

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