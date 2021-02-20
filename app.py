from flask import Flask,request
import datetime
import psycopg2

app = Flask(__name__)

con = psycopg2.connect(database='connections', user='postgres', host='db', password='plzwork')
cursor = con.cursor();

@app.route('/')
def index():
    n = request.args.get('n')
    if n != None and n.isnumeric():
        n = int(n)
        return str(n*n)
    else:
        return "Halan ROCKS!!!"

@app.route('/ip')
def ip():
    ip = str(request.remote_addr)
    timestampStr = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    cursor.execute("""
        INSERT INTO ip (user_ip, t1)
        VALUES(%s,%s)
        """
        ,(ip,timestampStr))

    con.commit()

    return "Requester IP: " + ip +" | Time Stamp: "+ str(timestampStr) 

@app.route('/allips')
def allips():

    cursor.execute('select * from ip')
    records = cursor.fetchall()

    out = ""
    for item in records:
        out = out +  "Requester IP: " +str(item[0]) + " | Time Stamp: " +str(item[1])+"<br>"
    return out


if __name__ == '__main__':
    app.run(host='0.0.0.0',debug=True)
