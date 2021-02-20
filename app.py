import os
from flask import Flask,request
app = Flask(__name__)

import datetime; 

def get_env_variable(name):
    try:
        return os.environ[name]
    except KeyError:
        message = "Expected environment variable '{}' not set.".format(name)
        raise Exception(message)



@app.route('/')
def index():
    n = request.args.get('n')
    if n != None and n.isnumeric():
        n = int(n)
        return str(n*n)
    return "Halan ROCKS!!!"

@app.route('/ip')
def getIP():
    ip = request.remote_addr

    # ct stores current time 
    ct = datetime.datetime.now() 
    print(ct)

    return "Requester IP:ssaaasssssss " + ip + ct

def data():
    # here we want to get the value of user (i.e. ?user=some-value)
    user = request.args.get('user')
    pass


if __name__ == '__main__':
    # the values of those depend on your setup
    POSTGRES_URL = get_env_variable("POSTGRES_URL")
    POSTGRES_USER = get_env_variable("POSTGRES_USER")
    POSTGRES_PW = get_env_variable("POSTGRES_PW")
    POSTGRES_DB = get_env_variable("POSTGRES_DB")
    app.run(host='0.0.0.0' debug=True)
