import json
import requests
from app import db, app
from models import *
from rapidfuzz import process, fuzz



with open("authorization.json", "r") as file:
  auth = json.load(file)

with app.app_context():
  medicine_names = db.session.query(Medicines.med_name).all()
  medicine_names = [name[0] for name in medicine_names]
  print(medicine_names)

def find_all_matches(user_input, medicines, top_n=5):
    # Get all matches without any threshold filtering
    matches = process.extract(user_input, medicines, scorer=fuzz.WRatio, limit=None)
    
    # Sort matches by score (already sorted by extract)
    sorted_matches = sorted(matches, key=lambda x: x[1], reverse=True)
    
    # If more than top_n matches, take only top_n
    if len(sorted_matches) > top_n:
        sorted_matches = sorted_matches[:top_n]
    
    return sorted_matches

matches = find_all_matches("ZZZZZZZZ", medicine_names)
for match in matches:
    print(match)