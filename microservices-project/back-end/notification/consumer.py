import pika
import os
import sys

from send import email


def main():
    print("Notification service starting...")
    connection = pika.BlockingConnection(pika.ConnectionParameters(host='rabbitmq'))
    channel = connection.channel()
    
    print("Notification service is healthy and ready!")

    def callback(channel, method, properties, body):
        err = email.notification(body)
        if err:
            print(f"Email failed: {err}")
            channel.basic_nack(delivery_tag=method.delivery_tag)
        else:
            print("Email sent successfully")
            channel.basic_ack(delivery_tag=method.delivery_tag)

    channel.basic_consume(
        queue=os.environ.get('MP3_QUEUE'), 
        on_message_callback=callback
    )

    print('Waiting for messages. To exit press CTRL+C')
    
    channel.start_consuming()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('Interrupted')
        try:
            sys.exit(0)
        except SystemExit:
            os._exit(0)