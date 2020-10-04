from flask import Flask
import requests
import sys
import logging
import boto3
import simplejson as json
import urllib.parse
import uuid
from boto3.dynamodb.conditions import Key, Attr
from flask import request
from flask import Response
from flask import Blueprint

app = Flask(__name__)
bp = Blueprint('app', __name__)
with open('config.json') as file:
    data = json.load(file)
dynamodb = boto3.resource('dynamodb', 
                      region_name='us-east-1', 
                      aws_access_key_id=data['AWS_ACCESS_KEY_ID'], 
                      aws_secret_access_key=data['AWS_SECRET_ACCESS_KEY'],
                      aws_session_token=data['AWS_SESSION_TOKEN'])

# This uses a sample table "Music" in the AWS DynamoDB tutorial code. The code is different than the examples due to putting it in a Flask server, but functionality is the same.


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

app.register_blueprint(bp, url_prefix='/api/v1/datastore/')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        logging.error("missing port arg 1")
        sys.exit(-1)

    p = int(sys.argv[1])
    app.run(host='0.0.0.0', port=p, debug=True, threaded=True)
