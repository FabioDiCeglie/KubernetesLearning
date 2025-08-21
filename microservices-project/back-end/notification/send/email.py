import smtplib, os, json
from email.message import EmailMessage


def notification(message):
    try:
        message = json.loads(message)
        mp3_file_id = message["mp3_file_id"]
        sender_address = os.environ.get("GMAIL_ADDRESS")
        sender_password = os.environ.get("GMAIL_PASSWORD")
        receiver_address = message["username"]
        
        # Validate environment variables
        if not sender_address:
            raise ValueError("GMAIL_ADDRESS environment variable is not set")
        if not sender_password:
            raise ValueError("GMAIL_PASSWORD environment variable is not set")
        if not receiver_address:
            raise ValueError("Receiver address (username) is missing from message")

        msg = EmailMessage()
        msg.set_content(f"mp3 file_id: {mp3_file_id} is now ready!")
        msg["Subject"] = "MP3 Download"
        msg["From"] = sender_address
        msg["To"] = receiver_address

        print(f"🔌 Connecting to Gmail SMTP with {sender_address}...")
        session = smtplib.SMTP("smtp.gmail.com", 587)
        session.starttls()
        session.login(sender_address, sender_password)
        print("📧 Sending message...")
        session.send_message(msg, sender_address, receiver_address)
        session.quit()
        print("✅ Mail Sent Successfully!")

    except Exception as err:
        print(err)
        return err