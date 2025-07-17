import os, gridfs, pika, json
from flask import Flask, request, jsonify
from flask_pymongo import PyMongo

from auth import validate
from auth_service import access
from storage import util


server = Flask(__name__)

server.config['MONGO_URI'] = os.getenv("MONGO_URI") or "mongodb://host.minikube.internal:27017/videos"

mongo = PyMongo(server)
fs = gridfs.GridFS(mongo.db)

connection = pika.BlockingConnection(pika.ConnectionParameters("rabbitmq"))
channel = connection.channel()


@server.route('/health', methods=['GET'])
def health():
    return "", 204


@server.route('/login', methods=['POST'])
def login():
    token, err = access.login(request)

    if not err:
        return token
    else:
        return jsonify({'error': err[0]}), err[1]


@server.route('/upload', methods=['POST'])
def upload():
    access, err = validate.token(request)

    access = json.loads(access)

    if access["admin"]:
        if len(request.files) > 1 or len(request.files) < 1:
            return "Exactly 1 file required", 400
        
        for _, f in request.files.items():
            err = util.upload(f, fs, channel, access)

            if err:
                return err
            
            return jsonify({'message': 'Upload successful'}), 200
    else:
        return jsonify({'error': 'Not authorized'}), 401
    

@server.route('/download', methods=['GET'])
def download():
    pass

if __name__ == "__main__":
    server.run(host='0.0.0.0', port=8080)