import requests

files = {
    'file': ('medical-strip.jpg', open('medical-strip.jpg', 'rb'))
}
resp = requests.post("http://localhost:8000/expiry-date-reader", files=files)
print(resp.text)
print(resp.json())