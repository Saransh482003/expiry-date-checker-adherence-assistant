from flask import Flask, request, jsonify, send_file
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
import pytz
import assemblyai as aai
import io
import cv2
import numpy as np
import torch
from PIL import Image
from paddleocr import PaddleOCR
from ultralytics import YOLO
import re
from werkzeug.utils import secure_filename
import os
import base64
from typing import Dict, Any

from rapidfuzz import process, fuzz

# Initialize models
model = YOLO('expiry_date_reader_model.pt')
ocr = PaddleOCR(use_angle_cls=True, lang='en')









def standardize_date(text):
    # Find dates in various formats
    date_patterns = [
        r'(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})',  # DD/MM/YYYY or MM/DD/YYYY
        r'(\d{2,4}[-/]\d{1,2}[-/]\d{1,2})',  # YYYY/MM/DD
        r'(\d{1,2}\s*(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*\d{2,4})',  # DD Mon YYYY
        r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*\d{1,2}\s*,?\s*\d{2,4}'  # Mon DD, YYYY
    ]
    
    for pattern in date_patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        if matches:
            try:
                date_str = matches[0]
                # Convert to datetime and then to standardized format
                formats = [
                    "%d/%m/%Y", "%m/%d/%Y", "%Y/%m/%d",
                    "%d-%m-%Y", "%m-%d-%Y", "%Y-%m-%d",
                    "%d %b %Y", "%d %B %Y",
                    "%b %d %Y", "%B %d %Y",
                    "%b %d, %Y", "%B %d, %Y"
                ]
                
                for fmt in formats:
                    try:
                        date_obj = datetime.strptime(date_str, fmt)
                        return date_obj.strftime("%Y-%m-%d")
                    except ValueError:
                        continue
            except Exception:
                continue
    return None


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
            # 00:00 AM IST = 18:30 UTC
            "schedule": crontab(hour=11, minute=15),
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
            # 16:00 AM IST = 10:30 UTC
            "schedule": crontab(hour=10, minute=30),
        },
        "send-whatsapp-message-at-20-00-pm": {
            "task": "app.send_whatsapp_message",
            # 20:00 AM IST = 14:30 UTC
            "schedule": crontab(hour=17, minute=44),
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
        data = data.iloc[-2:, :]
        email_sender = auth["email-address"]
        email_password = auth["email-password"]
        subject = 'Medication Daily Reminder'
        for index, row in data.iterrows():
            try:

                body = f"""Dear {row['name']},
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
        data = data.iloc[-2:, :]
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


@app.route("/login", methods=["POST"])
def login():
    form = request.get_json()
    fetchUser = Users.query.filter_by(
        user_name=form["username"], password=form["password"]).first()
    if fetchUser:
        fetchUser.last_loged = datetime.now(pytz.utc)
        db.session.commit()

        return {
            "user_id": fetchUser.user_id,
            "user_name": fetchUser.user_name,
            "email": fetchUser.email,
            "ph_no": fetchUser.ph_no,
            "gender": fetchUser.gender,
            "dob": fetchUser.dob,
            "last_loged": fetchUser.last_loged,
            "success": True
        }, 200
    else:
        return {
            "success": False,
            "message": "Invalid credentials"
        }, 401


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


@app.route("/get-user-data", methods=["POST"])
def getUserData():
    form = request.get_json()
    fetchUser = Users.query.filter_by(
        user_name=form["username"], password=form["password"]).first()
    fetchPrescriptions = Prescriptions.query.filter_by(
        user_id=fetchUser.user_id).all()
    medicine_ids = [p.med_id for p in fetchPrescriptions]
    fetchMedicines = Medicines.query.filter(
        Medicines.med_id.in_(medicine_ids)).all()
    if fetchUser:
        return {
            "user_id": fetchUser.user_id,
            "user_name": fetchUser.user_name,
            "email": fetchUser.email,
            "phone": fetchUser.ph_no,
            "gender": fetchUser.gender,
            "dob": fetchUser.dob.strftime("%A, %d %B %Y"),
            "last_loged": fetchUser.last_loged.strftime("%A, %d %B %Y"),
            "prescriptions": [{
                "pres_id": p.pres_id,
                "med_id": p.med_id,
                "medicine_name": m.med_name,
                "recommended_dosage": m.recommended_dosage,
                "side_effects": m.side_effects,
                "frequency": p.frequency,
                "expiry_date": datetime.strptime(p.expiry_date, "%Y-%m-%d %H:%M:%S").strftime("%A, %d %B %Y")
            } for p, m in zip(fetchPrescriptions, fetchMedicines)],
        }, 200
    else:
        return {
            "success": False,
            "message": "Server Error"
        }, 500

@app.route("/get-medicine", methods=["GET"])
def getMedicine():
    med_name = request.args.get("med_name", "")
    fetchMed = Medicines.query.filter(Medicines.med_name.ilike(f"%{med_name}%")).first()
    response = {
        "med_id": fetchMed.med_id if fetchMed else None,
        "med_name": fetchMed.med_name if fetchMed else None,
        "recommended_dosage": fetchMed.recommended_dosage if fetchMed else None,
        "side_effects": fetchMed.side_effects if fetchMed else None
    }
    return response, 200 if fetchMed else 404

@app.route("/add-medicine", methods=["POST"])
def addMedicine():
    form = request.get_json()
    fetchMed = Medicines.query.filter_by(med_name=form["med_name"]).first()
    if fetchMed == None:
        fetchMed = Medicines.query.order_by(desc(Medicines.med_id)).first()
        next_id = nextID(fetchMed.med_id) if fetchMed else "MEDA0001"
        addMed = Medicines(
            med_id=next_id,
            med_name=form["med_name"],
            recommended_dosage=form["recommended_dosage"],
            side_effects=form["side_effects"]
        )
        db.session.add(addMed)
        db.session.commit()
        return "Successfully Added", 200
    return "Medicine already exists", 400

@app.route("/add-prescription", methods=["POST"])
def addPrescription():
    form = request.get_json() 
    fetchUser = Users.query.filter_by(user_id=form["user_id"]).first()
    fetchMed = Medicines.query.filter_by(med_name=form["med_name"]).first()
    lastID = Prescriptions.query.order_by(Prescriptions.pres_id.desc()).first()
    next_id = nextID(lastID.pres_id) if lastID else "PRES0001"
    if fetchUser:
        if fetchMed:
            addPres = Prescriptions(
                pres_id=next_id,
                med_id=fetchMed.med_id,
                user_id=fetchUser.user_id,
                frequency=form["frequency"]
            )
            db.session.add(addPres)
            db.session.commit()
            return "Successfully Added", 200
        else:
            add_med_body = {
                "med_name": form["med_name"],
                "recommended_dosage": form["recommended_dosage"],
                "side_effects": form["side_effects"]
            }
            add_med = requests.post("http://localhost:8000/add-medicine", json=add_med_body)
            if add_med.status_code == 200:
                add_pres = requests.post("http://localhost:8000/add-prescription", json=form)
                if add_pres.status_code == 200:
                    return "Successfully Added", 200
                else:
                    return "Failed to add prescription", 500
    return "Unexpected Error", 500

def find_all_matches(user_input, medicines, top_n=5):
    matches = process.extract(user_input, medicines, scorer=fuzz.WRatio, limit=None)
    sorted_matches = sorted(matches, key=lambda x: x[1], reverse=True)
    if len(sorted_matches) > top_n:
        sorted_matches = sorted_matches[:top_n]
    return sorted_matches

@app.route("/get-similar-names", methods=["GET"])
def get_similar_names():
    with app.app_context():
        medicine_names = db.session.query(Medicines.med_name).all()
        medicine_names = [name[0] for name in medicine_names]
    user_input = request.args.get("med_name","")
    matches = find_all_matches(user_input, medicine_names)
    return {"matches": matches}

def voiceFunctionCall(medicine_name:str, frequency:str):
    return {"medicine_name": medicine_name, "frequency": frequency}

@app.route("/transcribe", methods=["POST"])
def transcribe():
    aai.settings.api_key = auth["assemblyai-api"]

    if 'file' not in request.files:
        return "No file part in the request", 400

    file = request.files['file']

    if file.filename == '':
        return "No selected file", 400

    file_stream = io.BytesIO(file.read())
    config = aai.TranscriptionConfig(speech_model=aai.SpeechModel.best)
    transcript = aai.Transcriber(config=config).transcribe(file_stream)

    if transcript.status == "error":
        raise RuntimeError(f"Transcription failed: {transcript.error}")
    
    text = transcript.text
    print(text)
    gpt_response = query_gpt(text, tools=[SPEECH_TEXT_FILLER])
    gpt_response = json.loads(gpt_response["choices"][0]["message"]["tool_calls"][0]["function"]["arguments"])
    name_matches = requests.get(f"http://localhost:8000/get-similar-names?med_name={text}").json()["matches"]
    gpt_response["similar-matches"] = [match[0] for match in name_matches]
    
    fetchMed = Medicines.query.filter_by(med_name=gpt_response["medicine_name"]).first()
    if fetchMed:
        gpt_response["recommended_dosage"] = fetchMed.recommended_dosage
        gpt_response["side_effects"] = fetchMed.side_effects
    else:
        gpt_response["recommended_dosage"] = ""
        gpt_response["side_effects"] = ""
    return gpt_response, 200

@app.route("/expiry-date-reader", methods=["POST"])
def expiry_date_reader():
    extracted_dates = []
    standardized_dates = []
    final_date = None

    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400

    try:
        # Read image bytes
        image_bytes = file.read()
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # cv2.imshow("Uploaded Image", image)
        # cv2.waitKey(0)  # Wait for a key press to close
        # cv2.destroyAllWindows()

        if image is None:
            return jsonify({"error": "Invalid image"}), 400

        # Run YOLO model on the image
        img_for_yolo = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
        results = model(img_for_yolo)
        
        # Get the result image with annotations
        result_img = results[0].plot()  # This returns a numpy array
        _, result_buffer = cv2.imencode('.jpg', result_img)
        result_img_bytes = result_buffer.tobytes()
        
        # Process bounding boxes
        boxes = results[0].boxes.xyxy.cpu().numpy() if hasattr(results[0].boxes, 'xyxy') else []
        cropped_images = []
        
        for box in boxes:
            x1, y1, x2, y2 = map(int, box)
            crop = image[y1:y2, x1:x2]
            if crop.size > 0:
                cropped_images.append(crop)

        for crop in cropped_images:
            crop_rgb = cv2.cvtColor(crop, cv2.COLOR_BGR2RGB)
            ocr_result = ocr.ocr(crop_rgb, cls=True)
            if ocr_result and len(ocr_result) > 0:
                for line in ocr_result[0]:
                    text = line[1][0]
                    extracted_dates.append(text)
                    # Improved date standardization
                    std_date = standardize_medical_date(text)
                    if std_date:
                        standardized_dates.append(std_date)

        if standardized_dates:
            try:
                date_objs = [datetime.strptime(d, "%Y-%m-%d") for d in standardized_dates]
                max_date = max(date_objs)
                final_date = max_date.strftime("%Y-%m-%d")
            except Exception:
                final_date = standardized_dates[0] if standardized_dates else None


        print({
            "success": True,
            "detected_dates": extracted_dates,
            "standardized_dates": standardized_dates,
            "final_date": final_date,
            # "annotated_image": base64.b64encode(result_img_bytes).decode('utf-8') if result_img_bytes else None
        })  
        return {
            "success": True,
            "detected_dates": extracted_dates,
            "standardized_dates": standardized_dates,
            "final_date": final_date,
            # "annotated_image": base64.b64encode(result_img_bytes).decode('utf-8') if result_img_bytes else None
        }

    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }, 500

def standardize_medical_date(date_str):
    """
    Robust date standardization that defaults to 1st day when no day is specified
    Handles formats like:
    - Dt:03/2023 → 2023-03-01
    - EXP 12/25/2025 → 2025-12-25
    - 15-02-2026 → 2026-02-15
    - 2025.12 → 2025-12-01
    - Dec 2025 → 2025-12-01
    - 20251231 → 2025-12-31
    """
    try:
        original_str = date_str
        date_str = date_str.lower()
        
        # Remove common prefixes/suffixes and normalize separators
        date_str = re.sub(r'(^dt[:]?|^exp|expiry|exp date|use by|best before)[:\s]*', '', date_str)
        date_str = re.sub(r'[\s\-_\.]', ' ', date_str).strip()
        date_str = re.sub(r'(\d)(st|nd|rd|th)\b', r'\1', date_str)
        
        # Try different date patterns
        patterns = [
            # Full dates with day
            (r'(\d{1,2}) (\d{1,2}) (\d{4})', lambda m: validate_and_format(m.group(3), m.group(2), m.group(1))),  # DD MM YYYY
            (r'(\d{1,2}) (\d{1,2}) (\d{4})', lambda m: validate_and_format(m.group(3), m.group(1), m.group(2))),  # MM DD YYYY
            (r'(\d{4}) (\d{1,2}) (\d{1,2})', lambda m: validate_and_format(m.group(1), m.group(2), m.group(3))),  # YYYY MM DD
            (r'(\w{3,}) (\d{1,2}),? (\d{4})', lambda m: format_month_name_date(m.group(1), m.group(2), m.group(3))),  # Month DD YYYY
            (r'(\d{1,2}) (\w{3,}) (\d{4})', lambda m: format_month_name_date(m.group(2), m.group(1), m.group(3))),  # DD Month YYYY
            
            # Month-year only (default to 1st day)
            (r'(\d{1,2}) (\d{4})', lambda m: f"{m.group(2)}-{int(m.group(1)):02d}-01"),  # MM YYYY
            (r'(\w{3,}) (\d{4})', lambda m: format_month_name_date(m.group(1), '1', m.group(2))),  # Month YYYY
            
            # Various separator formats
            (r'(\d{2})/(\d{2})/(\d{4})', lambda m: validate_and_format(m.group(3), m.group(2), m.group(1))),  # DD/MM/YYYY
            (r'(\d{2})/(\d{2})/(\d{4})', lambda m: validate_and_format(m.group(3), m.group(1), m.group(2))),  # MM/DD/YYYY
            (r'(\d{4})/(\d{2})/(\d{2})', lambda m: f"{m.group(1)}-{m.group(2)}-{m.group(3)}"),
            (r'(\d{2})/(\d{4})', lambda m: f"{m.group(2)}-{int(m.group(1)):02d}-01"),  # MM/YYYY
        ]
        
        for pattern, formatter in patterns:
            match = re.fullmatch(pattern, date_str)
            if match:
                try:
                    formatted_date = formatter(match)
                    if validate_date(formatted_date):
                        return formatted_date
                except (ValueError, IndexError):
                    continue
        
        # Fallback to more aggressive cleaning
        digits = re.sub(r'[^\d]', '', original_str)
        if len(digits) == 6:  # MMDDYY or DDMMYY
            return try_ambiguous_date(digits)
        elif len(digits) == 8:  # YYYYMMDD or MMDDYYYY
            return try_compact_date(digits)
        elif len(digits) in [4,5,6]:  # Partial dates
            return try_partial_date(digits)
            
        return None
        
    except Exception as e:
        print(f"Error standardizing date '{original_str}': {str(e)}")
        return None

def try_partial_date(digits):
    """Handle partial dates by defaulting to 1st day and first month if needed"""
    if len(digits) == 6:  # YYMMDD
        return f"20{digits[:2]}-{int(digits[2:4]):02d}-{int(digits[4:6]):02d}"
    elif len(digits) == 4:  # YYYY or MMDD
        if digits.isdigit():
            if 2000 <= int(digits) <= 2050:  # Likely year
                return f"{digits}-01-01"
            elif 1 <= int(digits[:2]) <= 12:  # Likely MMYY
                return f"20{digits[2:]}-{int(digits[:2]):02d}-01"
    return None

def format_month_name_date(month_str, day_str, year_str):
    """Format dates with month names"""
    month_map = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
    }
    month = month_map.get(month_str[:3].lower())
    if month:
        return f"{year_str}-{month:02d}-{int(day_str):02d}"
    return None

def validate_date(date_str):
    """Validate that the date is reasonable (not in distant past/future)"""
    try:
        date_obj = datetime.strptime(date_str, "%Y-%m-%d")
        current_year = datetime.now().year
        return 2000 <= date_obj.year <= current_year + 20
    except ValueError:
        return False

def validate_and_format(year, month, day):
    """Validate day/month ranges and format"""
    if 1 <= int(month) <= 12 and 1 <= int(day) <= 31:
        return f"{year}-{int(month):02d}-{int(day):02d}"
    return None

def try_ambiguous_date(digits):
    """Try to parse ambiguous 6-digit dates (MMDDYY or DDMMYY)"""
    # Try DDMMYY
    dd, mm, yy = int(digits[:2]), int(digits[2:4]), int(digits[4:])
    if 1 <= mm <= 12 and 1 <= dd <= 31:
        return f"20{yy:02d}-{mm:02d}-{dd:02d}"
    
    # Try MMDDYY
    mm, dd, yy = int(digits[:2]), int(digits[2:4]), int(digits[4:])
    if 1 <= mm <= 12 and 1 <= dd <= 31:
        return f"20{yy:02d}-{mm:02d}-{dd:02d}"
    
    return None

def try_compact_date(digits):
    """Try to parse 8-digit dates (YYYYMMDD or MMDDYYYY)"""
    # Try YYYYMMDD
    if digits[:4].isdigit() and 2000 <= int(digits[:4]) <= 2050:
        year, month, day = int(digits[:4]), int(digits[4:6]), int(digits[6:8])
        if 1 <= month <= 12 and 1 <= day <= 31:
            return f"{year}-{month:02d}-{day:02d}"
    
    # Try MMDDYYYY
    if digits[4:].isdigit() and 2000 <= int(digits[4:]) <= 2050:
        month, day, year = int(digits[:2]), int(digits[2:4]), int(digits[4:8])
        if 1 <= month <= 12 and 1 <= day <= 31:
            return f"{year}-{month:02d}-{day:02d}"
    
    return None
    


@app.route('/delete-content/table', methods=["GET", "DELETE"])
def delete_content():
    table = request.args.to_dict()["table"]
    num_rows_deleted = db.session.query(globals()[table]).delete()
    db.session.commit()
    return f"Deleted {num_rows_deleted} rows from the {table} table."




SPEECH_TEXT_FILLER = {
    "type": "function",
    "function": {
        "name": "voiceFunctionCall",
        "description": "This function takes textual input and extract out the medicine name and frequency from it.",
        "parameters": {
            "type": "object",
            "properties": {
                "medicine_name": {
                    "type": "string",
                    "description": "The name of the medicine"
                },
                "frequency": {
                    "type": "integer",
                    "description": "The frequency of the medicine to take each day"
                },
            },
            "required": ["medicine_name","frequency"],
            "additionalProperties": False,
        },
        "strict": True,
    },
}

tools=[SPEECH_TEXT_FILLER]

def query_gpt(user_input: str, tools: list[Dict[str, Any]] = tools) -> Dict[str, Any]:
    response = requests.post(
        "https://aiproxy.sanand.workers.dev/openai/v1/chat/completions",
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {auth['openai-api']}"
        },
        json={
            "model": "gpt-4o-mini",
            "messages": [
                {"role": "system","content": "You are a helpful assistant that can extract information from text related to medicine name, and frequency to take it per day. If the text gives you a medicine name that doesn't make sense or is not valid, rectify the name and give the correct name. If the text gives you a frequency that doesn't make sense or is not valid, rectify the frequency and give the correct frequency."},
                {"role": "user", "content": user_input}
            ],
            "tools": tools,
            "tool_choice": "auto",
        },
    )
    return response.json()



if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8000)
