import smtplib
from email.message import EmailMessage

sender_email = "my@email.com"

def send(msg, sender_email, debug=True):
    if debug:
        smtp_server = "localhost"
        port = 1025
        with smtplib.SMTP(smtp_server, port) as server:
            server.send_message(msg)

msg = EmailMessage()
msg["to"] = "test@warehouse.com"
msg["from"] = "	trade@foxgloveliving.co.uk"
msg["subject"] = "Order Request"
msg.set_content("Hi, I would like to order some dinner sets. 3 please.")
send(msg, sender_email)
