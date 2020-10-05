from flask import Flask
import requests
import sys
import logging
import simplejson as json
import urllib
import jwt
import time
from flask import request
from flask import Response
from flask import Blueprint
app = Flask(__name__)
bp = Blueprint('app', __name__)
db = {
    "name": "http://host.docker.internal:5002/api/v1/datastore",
    "endpoint": [
        "read",
        "write",
        "delete",
        "update"
    ]
}

@bp.route('/', methods=['GET'])
def hello_world():
    return 'This is the default route for the users service. It is supposed to return a list of all the users (maybe implement via table cursor)'

@bp.route('/health')
def health():
    return Response("", status=200, mimetype="application/json")

@bp.route('/readiness')
def readiness():
    return Response("", status=200, mimetype="application/json")

@bp.route('/<user_id>', methods=['PUT'])
def update_user(user_id):
    headers = request.headers
    # check header here
    if 'Authorization' not in headers:
        return Response(json.dumps({"error": "missing auth"}), status=401, mimetype='application/json')
    try:
        content = request.get_json()
        email = content['email']
        fname = content['fname']
        lname = content['lname']
    except: 
        return json.dumps({"message": "error reading arguments"})
    url = db['name'] + '/' + db['endpoint'][3]
    response = requests.put(url, params = {"objtype": "user", "objkey": user_id}, json = {"email": email, "fname": fname, "lname": lname})
    return (response.json())

# this currently overwrites a user
@bp.route('/', methods=['POST'])
def create_user():
    try:
        content = request.get_json()
        lname = content['lname']
        email = content['email']
        fname = content['fname']
    except: 
        return json.dumps({"message": "error reading arguments"})
    url = db['name'] + '/' + db['endpoint'][1]
    response = requests.post(url, json = {"objtype":"user","lname":lname, "email": email, "fname": fname})
    return (response.json())

@bp.route('/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    headers = request.headers
    # check header here
    if 'Authorization' not in headers:
        return Response(json.dumps({"error": "missing auth"}), status=401, mimetype='application/json')
    url = db['name'] + '/' + db['endpoint'][2]

    response = requests.delete(url, params = {"objtype": "user", "objkey": user_id})
    return (response.json())

@bp.route('/<user_id>', methods=['GET'])
def get_user(user_id):
    headers = request.headers
    # check header here
    if 'Authorization' not in headers:
        return Response(json.dumps({"error": "missing auth"}), status=401, mimetype='application/json')
    payload = {"objtype": "user", "objkey": user_id}
    url = db['name'] + '/' + db['endpoint'][0]
    response = requests.get(url, params = payload)
    return (response.json())

@bp.route('/login', methods=['PUT'])
def login():
    try: 
        content = request.get_json()
        uid = content['uid']
    except:
        return json.dumps({"message": "error reading parameters"})
    url = db['name'] + '/' + db['endpoint'][0]
    response = requests.get(url, params = {"objtype": "user", "objkey": uid})
    data = response.json()
    if len(data['Items']) > 0:
        encoded = jwt.encode({'user_id': uid, 'time': time.time()}, 'secret', algorithm='HS256')
    return encoded

@bp.route('/logoff', methods=['PUT'])
def logoff():
    try: 
        content = request.get_json()
        jwt = content['jwt']
    except:
        return json.dumps({"message": "error reading parameters"})
    return {}
app.register_blueprint(bp, url_prefix='/api/v1/user/')
if __name__ == '__main__':
    if len(sys.argv) < 2:
        logging.error("missing port arg 1")
        sys.exit(-1)

    p = int(sys.argv[1])
    app.run(host='0.0.0.0', port=p, debug=True, threaded=True)