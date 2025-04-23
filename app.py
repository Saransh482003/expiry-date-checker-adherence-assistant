from flask import Flask
from flask_cors import CORS
from flask_caching import Cache
import requests
from celery_config import celery_init_app
from celery.result import AsyncResult
from celery import shared_task
from celery.contrib.abortable import AbortableTask
from celery.schedules import crontab
from models import *
import pandas as pd
from twilio.rest import Client
from email.message import EmailMessage
import smtplib
import ssl
import json

with open("authorization.json") as f:
    auth = json.loads(f.read())

account_sid = auth["authorization-sid"]
auth_token = auth["authorization-token"]
client = Client(account_sid, auth_token)


app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///prescription.sqlite3'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = "3T9rFtQxZ1jA77sKJiy_mT6YvFP_W0C6eM67oNOxO0Y"
app.config["CELERY"] = {
    "broker_url": "redis://localhost:6379/0",
    "result_backend": "redis://localhost:6379/0",
    "task_ignore_result": True,
    "beat_schedule": {
        "run-every-day-at-00-00-am": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=18, minute=7),  # 00:00 AM IST = 18:30 UTC
        },
        "run-every-day-at-4-00-am": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=22, minute=30),  # 4:00 AM IST = 22:30 UTC
        },
        "run-every-day-at-8-00-am": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=2, minute=30),  # 8:00 AM IST = 2:30 UTC
        },
        "run-every-day-at-12-00-pm": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=6, minute=30),  # 12:00 PM IST = 6:30 UTC
        },
        "run-every-day-at-16-00-pm": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=10, minute=30),  # 16:00 AM IST = 10:30 UTC
        },
        "run-every-day-at-20-00-pm": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=14, minute=30),  # 20:00 AM IST = 14:30 UTC
        },
        
    },
}

celery_app = celery_init_app(app)
db.init_app(app)
CORS(app)
cache = Cache(app, config={
    'CACHE_TYPE': 'RedisCache',
    'CACHE_REDIS_HOST': 'localhost',
    'CACHE_REDIS_PORT': 6379,
    'CACHE_REDIS_DB': 0,
    'CACHE_REDIS_URL': 'redis://localhost:6379/0'
})




def nextID(id):
    prefix = id[:3]
    alpha = id[3]
    num = id[4:]
    if num == "9999":
        return f"{prefix}{chr(ord(alpha)+1)}0001"
    else:
        return f"{prefix}{alpha}{'0'*(4-len(str(int(num))))}{int(num)+1}"
      

@shared_task(bind=True, base=AbortableTask, ignore_result=False)
def send_email_message(self):
    with app.app_context():
        data = pd.read_csv("data.csv")
        email_sender = 'saini.saransh03@gmail.com'
        email_password = auth["email-password"]
        subject = 'Medication Daily Reminder'
        for index, row in data.iterrows():
            try:
                
                body = f"""
                    Dear {row['name']},

                    This is a friendly reminder to take your prescribed medication: **{row['medicine_name']}**.

                    Staying consistent with your medication is essential for your health and well-being. 
                    If you have any questions or concerns, feel free to reach out to your healthcare provider.

                    Take care and stay healthy!

                    Warm regards,  
                    Your Healthcare Team
                """
                em = EmailMessage()
                em['From'] = email_sender
                em['To'] = row["email"]
                em['Subject'] = subject
                em.set_content(body, charset='utf-8')
                
                context = ssl.create_default_context()
                with smtplib.SMTP_SSL('smtp.gmail.com', 465, context=context) as smtp:
                    smtp.login(email_sender, email_password)
                    smtp.sendmail(email_sender, row["email"], em.as_string())
            except Exception as e:
                print(f"Failed to send message to {row['mobile']}: {e}")


@shared_task(bind=True, base=AbortableTask, ignore_result=False)
def send_whatsapp_message(self):
    with app.app_context():
        data = pd.read_csv("data.csv")
        for index, row in data.iterrows():
            try:
                client.messages.create(
                    body=f"Hello {row['name']}, this is a reminder to take your medicine: {row['medicine_name']}",
                    from_='whatsapp:+14155238886',
                    to=f'whatsapp:{row["mobile"]}'
                )
                print(f"Message sent to {row['mobile']} successfully.")
            except Exception as e:
                print(f"Failed to send message to {row['mobile']}: {e}")


@app.route("/")
def index():
    return {"message":"Hello, World!"}


if __name__ == "__main__":
    app.run(debug=True)