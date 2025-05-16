from app import app, db
from sqlalchemy import text

with app.app_context():

    # Insert sample data into the Users table
    db.session.execute(text("""
        DELETE FROM Prescriptions WHERE pres_id = 'PRSA0044';
        """))
    db.session.commit()
