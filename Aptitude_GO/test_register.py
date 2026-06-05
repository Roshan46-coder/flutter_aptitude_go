import urllib.request
import json
req = urllib.request.Request('http://127.0.0.1:8000/api/register/', data=json.dumps({"username":"testuser2", "email":"testuser2@example.com", "password":"password123", "is_company":False}).encode(), headers={'Content-Type':'application/json'}, method='POST')
try:
    print(urllib.request.urlopen(req).read())
except Exception as e:
    print(e)
    if hasattr(e, 'read'):
        print(e.read())
