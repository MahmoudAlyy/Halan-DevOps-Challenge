import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

print("AAA")

con = psycopg2.connect(user='postgres' ,host='172.17.0.1', password='password')
#host.inter
 #ip can be ifxed later in docker compose

print("AAAAAAAAAAAAAAA")
# Connect to PostgreSQL DBMS
con.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT);

 
# Obtain a DB Cursor
cursor = con.cursor();
name_Database = "SocialMedia";
sqlCreateDatabase = "create database "+name_Database+";"

try: 
	cursor.execute(sqlCreateDatabase);

except Exception as e:
	print(e)


con.close()