import pika, json, tempfile, os
from bson.objectid import ObjectId
from moviepy import *


def start(message, fs_videos, fs_mp3s, channel):
    # Parse the incoming JSON message containing video file information
    message = json.loads(message)

    # Create a temporary file to store the video data
    tf = tempfile.NamedTemporaryFile()

    # Retrieve the video file from MongoDB GridFS using the video file ID
    out = fs_videos.get(ObjectId(message['video_file_id']))

    # Write the video file content to the temporary file
    tf.write(out.read())

    # Extract audio from the video file using moviepy
    audio = moviepy.editor.VideoFileClip(tf.name).audio
    tf.close()

    # Create a path for the temporary MP3 file
    tf_path = tempfile.gettempdir() + f"/{message['video_file_id']}.mp3"
    # Write the extracted audio to an MP3 file
    audio.write_audiofile(tf_path)

    # Read the MP3 file data
    f = open(tf_path, 'rb')
    data = f.read()
    # Store the MP3 file in MongoDB GridFS and get the file ID
    file_id = fs_mp3s.put(data)
    f.close()
    # Clean up the temporary MP3 file
    os.remove(tf_path)

    # Add the MP3 file ID to the message for downstream processing
    message['mp3_file_id'] = str(file_id)

    try: 
        # Publish the updated message to the MP3 queue for further processing
        channel.basic_publish(
            exchange='',
            routing_key=os.environ.get('MP3_QUEUE'),
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=pika.spec.PERSISTENT_DELIVERY_MODE
            )
        )
    except Exception as err:
        # If publishing fails, clean up by deleting the MP3 file from GridFS
        fs_mp3s.delete(file_id)
        return "Failed to publish message"