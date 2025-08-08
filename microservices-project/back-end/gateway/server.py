import os, gridfs, pika, json
from flask import Flask, request, jsonify, send_file
from flask_pymongo import PyMongo

from auth import validate
from auth_service import access
from storage import util
from bson.objectid import ObjectId


server = Flask(__name__)
mongo_video = PyMongo(server, uri=os.getenv("MONGO_URI_VIDEO") or "mongodb://host.minikube.internal:27017/videos")
mongo_mp3 = PyMongo(server, uri=os.getenv("MONGO_URI_MP3S") or "mongodb://host.minikube.internal:27017/mp3s")
fs_videos = gridfs.GridFS(mongo_video.db)
fs_mp3s = gridfs.GridFS(mongo_mp3.db)

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

    if err:
        return jsonify({'error': 'Not authorized'}), 401

    access = json.loads(access)

    if access["admin"]:
        if len(request.files) > 1 or len(request.files) < 1:
            return "Exactly 1 file required", 400
        
        for _, f in request.files.items():
            err = util.upload(f, fs_videos, channel, access)

            if err:
                return err
            
            return jsonify({'message': 'Upload successful'}), 200
    else:
        return jsonify({'error': 'Not authorized'}), 401
    

@server.route('/download', methods=['GET'])
def download():
    access, err = validate.token(request)

    if err:
        return jsonify({'error': 'Not authorized'}), 401

    access = json.loads(access)

    if access["admin"]:
        file_id_string = request.args.get("file_id")

        if not file_id_string:
            return "File ID is required", 400

        try:
            out = fs_mp3s.get(ObjectId(file_id_string))

            return send_file(out, download_name=f"{file_id_string}.mp3")
        except Exception as err:
            return jsonify({'error': str(err)}), 500
    else:
        return jsonify({'error': 'Not authorized'}), 401

if __name__ == "__main__":
    server.run(host='0.0.0.0', port=8080)