from flask import Flask, request
from flask_cors import CORS
from sqlalchemy import desc
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
from datetime import datetime
import smtplib
import ssl
import json
from flask_socketio import SocketIO

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
        "send-whatsapp-message-at-00-00-am": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=11, minute=15),  # 00:00 AM IST = 18:30 UTC
        },
        "send-whatsapp-message-at-4-00-am": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=22, minute=30),  # 4:00 AM IST = 22:30 UTC
        },
        "send-whatsapp-message-at-8-00-am": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=2, minute=30),  # 8:00 AM IST = 2:30 UTC
        },
        "send-whatsapp-message-at-12-00-pm": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=6, minute=30),  # 12:00 PM IST = 6:30 UTC
        },
        "send-whatsapp-message-at-16-00-pm": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=10, minute=30),  # 16:00 AM IST = 10:30 UTC
        },
        "send-whatsapp-message-at-20-00-pm": {
        "task": "app.send_whatsapp_message",
        "schedule": crontab(hour=17, minute=44),  # 20:00 AM IST = 14:30 UTC
        },
        # "send-email-message-at-00-00-am": {
        # "task": "app.send_email_message",
        # "schedule": crontab(hour=18, minute=7),  # 00:00 AM IST = 18:30 UTC
        # },
        # "send-email-message-at-4-00-am": {
        # "task": "app.send_email_message",
        # "schedule": crontab(hour=22, minute=30),  # 4:00 AM IST = 22:30 UTC
        # },
        # "send-email-message-at-8-00-am": {
        # "task": "app.send_email_message",
        # "schedule": crontab(hour=2, minute=30),  # 8:00 AM IST = 2:30 UTC
        # },
        # "send-email-message-at-12-00-pm": {
        # "task": "app.send_email_message",
        # "schedule": crontab(hour=6, minute=30),  # 12:00 PM IST = 6:30 UTC
        # },
        # "send-email-message-at-16-00-pm": {
        # "task": "app.send_email_message",
        # "schedule": crontab(hour=10, minute=30),  # 16:00 AM IST = 10:30 UTC
        # },
        # "send-email-message-at-20-00-pm": {
        # "task": "app.send_email_message",
        # "schedule": crontab(hour=17, minute=45),  # 20:00 AM IST = 14:30 UTC
        # },
        
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

socketio = SocketIO(app, cors_allowed_origins="*")

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
        fetchData = Prescriptions.query.all()
        data = pd.DataFrame([{
            "pres_id": row.pres_id,
            "med_id": row.med_id,
            "user_id": row.user_id,
            "frequency": row.frequency,
            "name": Users.query.filter_by(user_id=row.user_id).first().user_name,
            "email": Users.query.filter_by(user_id=row.user_id).first().email,
            "medicine_name": Medicines.query.filter_by(med_id=row.med_id).first().med_name
        } for row in fetchData])
        data = data.iloc[-2:,:]
        email_sender = auth["email-address"]
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
        fetchData = Prescriptions.query.all()
        data = pd.DataFrame([{
            "pres_id": row.pres_id,
            "med_id": row.med_id,
            "user_id": row.user_id,
            "frequency": row.frequency,
            "name": Users.query.filter_by(user_id=row.user_id).first().user_name,
            "email": Users.query.filter_by(user_id=row.user_id).first().email,
            "mobile": Users.query.filter_by(user_id=row.user_id).first().ph_no,
            "medicine_name": Medicines.query.filter_by(med_id=row.med_id).first().med_name
        } for row in fetchData])
        print(data)
        data = data.iloc[-2:,:]
        print(data)
        # for index, row in data.iterrows():
        #     try:
        #         client.messages.create(
        #             body=f"Hello {row['name']}, this is a reminder to take your medicine: {row['medicine_name']}",
        #             from_='whatsapp:+14155238886',
        #             to=f'whatsapp:{row["mobile"]}'
        #         )
        #         print(f"Message sent to {row['mobile']} successfully.")
        #     except Exception as e:
        #         print(f"Failed to send message to {row['mobile']}: {e}")


@app.route("/")
def index():
    return "Hello World!"

@app.route("/add-user", methods=["POST"])
def register():
    form = request.get_json()
    fetchUser = Users.query.filter_by(email=form["email"]).first()
    if fetchUser == None:
        fetchUsers = Users.query.order_by(desc(Users.user_id)).first()
        next_id = nextID(fetchUsers.user_id) if fetchUsers else "USRA0001"
        now = datetime.now()
        
        dob_str = form["dob"]
        try:
            dob = datetime.fromisoformat(dob_str)
        except ValueError:
            # fallback if milliseconds are present (Python <3.11)
            dob = datetime.strptime(dob_str.split('.')[0], "%Y-%m-%d %H:%M:%S")
        try: 
            addUser = Users(
                user_id=next_id,
                user_name=form["name"],
                password=form["password"],
                email=form["email"],
                ph_no=form["phone"],
                last_loged=now,
                gender=form["gender"],
                dob=dob,
            )
            db.session.add(addUser)
            db.session.commit()
            return "Successfully Added", 200
        except Exception as e:
            print(e)
            return "Failed to add user", 500
    return "User already exists", 400

@app.route("/add_prescription", methods=["POST"])
def addPrescription():
    form = request.get_json()
    fetchUser = Users.query.filter_by(user_name=form["user_name"], password=form["password"]).first()
    if fetchUser:
        user_id = fetchUser.user_id
        fetchMed = Medicines.query.filter_by(med_name=form["med_name"]).first()
        lastID = Prescriptions.query.order_by(Prescriptions.book_id.desc()).first().book_id
        addPres = Prescriptions(
            pres_id=nextID(lastID),
            med_id=fetchMed.med_id,
            user_id=user_id,
            frequency=form["frequency"]
        )
        db.session.add(addPres)
        db.session.commit()


@app.route('/delete-content/table', methods=["GET", "DELETE"])
def delete_content():
    table = request.args.to_dict()["table"]
    num_rows_deleted = db.session.query(globals()[table]).delete()
    db.session.commit()
    return f"Deleted {num_rows_deleted} rows from the {table} table."

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8000)