import pika, json
from flask import jsonify

def upload(file, fs, channel, access):
    try:
        file_id = fs.put(file)
    except Exception as err:
        return jsonify({'error': "Internal server error"}), 500
    
    message = {
        "video_file_id": str(file_id),
        "mp3_file_id": None,
        "username": access["username"],
    }

    try:
        channel.basic_publish(
            exchange='',
            routing_key='video',
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=pika.spec.PERSISTENT_DELIVERY_MODE
            )
        )
    except:
        fs.delete(file_id)
        return jsonify({'error': "Error publishing message"}), 500
    
    return jsonify({'message': 'Message published successfully'}), 200