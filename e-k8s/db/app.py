from flask import Flask
import requests
import sys
import logging
import boto3
import simplejson as json
import urllib.parse
import uuid
import os
from boto3.dynamodb.conditions import Key, Attr
from flask import request
from flask import Response
from flask import Blueprint
from prometheus_flask_exporter import PrometheusMetrics


app = Flask(__name__)

metrics = PrometheusMetrics(app)
metrics.info('app_info', 'Database process')

bp = Blueprint('app', __name__)
#with open('config.json') as file:
#    data = json.load(file)

# default to us-east-1 if no region is specified
# (us-east-1 is the default/only supported region for a starter account)
region = os.getenv('AWS_REGION', 'us-east-1')

# these must be present; if they are missing, we should probably bail now
access_key = os.getenv('AWS_ACCESS_KEY_ID')
secret_access_key = os.getenv('AWS_SECRET_ACCESS_KEY')

# this is only needed for starter accounts
session_token = os.getenv('AWS_SESSION_TOKEN')

# if session_token is not present in the environment, assume it is a 
# standard acct which doesn't need one; otherwise, add it on.
if ( not session_token ):
  dynamodb = boto3.resource('dynamodb', 
                      region_name=region,
                      aws_access_key_id=access_key,
                      aws_secret_access_key=secret_access_key)
else:
  dynamodb = boto3.resource('dynamodb', 
                      region_name=region,
                      aws_access_key_id=access_key,
                      aws_secret_access_key=secret_access_key,
		      aws_session_token=session_token)


# Change the implementation of this: you should probably have a separate driver class for interfacing with a db like dynamodb in a different file.

@bp.route('/update', methods=['PUT'])
def update():
    headers = request.headers
    # check header here
    content = request.get_json()
    objtype = urllib.parse.unquote_plus(request.args.get('objtype'))
    objkey = urllib.parse.unquote_plus(request.args.get('objkey'))
    table_name = objtype.capitalize()
    table_id = objtype + "_id"
    table = dynamodb.Table(table_name)
    expression = 'SET '
    x = 1
    attrvals = {}
    for k in content.keys():
        expression += k + ' = :val' + str(x) + ', '
        attrvals[':val' + str(x)] = content[k]
        x += 1
    expression = expression[:-2]
    response = table.update_item(Key={table_id: objkey},
                                UpdateExpression=expression,
                                ExpressionAttributeValues=attrvals)
    return response

@bp.route('/read', methods=['GET'])
def read():
    headers = request.headers
    # check header here
    objtype = urllib.parse.unquote_plus(request.args.get('objtype'))
    objkey = urllib.parse.unquote_plus(request.args.get('objkey'))
    table_name = objtype.capitalize()
    table_id = objtype + "_id"
    table = dynamodb.Table(table_name)
    response = table.query(Select='ALL_ATTRIBUTES', KeyConditionExpression=Key(table_id).eq(objkey))
    return response

@bp.route('/write', methods=['POST'])
def write():
    headers = request.headers
    # check header here
    content = request.get_json()
    table_name = content['objtype'].capitalize()
    objtype = content['objtype']
    table_id = objtype + "_id"
    payload = {table_id: str(uuid.uuid4())}
    del content['objtype']
    for k in content.keys():
        payload[k] = content[k]
    table = dynamodb.Table(table_name)
    response = table.put_item(Item=payload)
    returnval = ''
    if response['ResponseMetadata']['HTTPStatusCode'] != 200:
        returnval = {"message": "fail"}
    return json.dumps(({table_id: payload[table_id]}, returnval)['returnval' in globals()])

@bp.route('/delete', methods=['DELETE'])
def delete():
    headers = request.headers
    # check header here
    objtype = urllib.parse.unquote_plus(request.args.get('objtype'))
    objkey = urllib.parse.unquote_plus(request.args.get('objkey'))
    table_name = objtype.capitalize()
    table_id = objtype + "_id"
    table = dynamodb.Table(table_name)
    response = table.delete_item(Key={table_id: objkey})
    return response

@bp.route('/health')
def health():
    return Response("", status=200, mimetype="application/json")

@bp.route('/readiness')
def readiness():
    return Response("", status=200, mimetype="application/json")

# All database calls will have this prefix.  Prometheus metric
# calls will not---they will have route '/metrics'.  This is
# the conventional organization.
app.register_blueprint(bp, url_prefix='/api/v1/datastore/')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        logging.error("missing port arg 1")
        sys.exit(-1)

    p = int(sys.argv[1])
    # Do not set debug=True---that will disable the Prometheus metrics
    app.run(host='0.0.0.0', port=p, threaded=True)
