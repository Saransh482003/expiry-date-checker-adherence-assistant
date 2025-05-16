from models import *
import sqlite3
import pandas as pd

books = pd.read_csv("prescription.csv")
print(books)
conn = sqlite3.connect("instance/prescription.sqlite3")
cursor = conn.cursor()
# print(len(books),books[0])
for i in range(len(books)):
    row = books.iloc[i]
    # cursor.execute(f"""
    #     INSERT INTO users (user_id, user_name, password, email, ph_no, last_loged, gender, dob) 
    #     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    # """, (row['user_id'], row['user_name'], row['password'], row['email'], f"{row['ph_no']}", datetime.strptime(row['last_loged'],'%d-%m-%Y'), row['gender'], datetime.strptime(row['dob'],'%d-%m-%Y')))

    cursor.execute(f"""
        INSERT INTO prescriptions (pres_id, med_id, user_id, frequency, expiry_date) 
        VALUES (?, ?, ?, ?, ?)
    """, (row['pres_id'], row['med_id'], row['user_id'], int(row['frequency']), row['expiry_date']))

    # cursor.execute(f"""
    #     INSERT INTO medicines (med_id, med_name, recommended_dosage, side_effects) 
    #     VALUES (?, ?, ?, ?)
    # """, (row['med_id'], row['med_name'], row['recommended_dosage'], row['side_effects']))
conn.commit()
conn.close()
