import requests
import sys
import random

BASE_URL = "http://127.0.0.1:8000"
client = requests.Session()

def verify():
    print("Verifying Full Platform...")
    
    # Register
    username = f"player_{random.randint(1000, 9999)}"
    print(f"Registering {username}...")
    
    # Get register page for CSRF
    r = client.get(f"{BASE_URL}/register/")
    csrf = client.cookies['csrftoken']
    
    data = {
        'username': username,
        'email': f'{username}@example.com',
        'password': 'StrongPassword@123',
        'csrfmiddlewaretoken': csrf
    }
    headers = {'Referer': f"{BASE_URL}/register/"}
    r = client.post(f"{BASE_URL}/register/", data=data, headers=headers)
    
    if r.status_code == 200 and ('Level 1' in r.text or '/profile/' in r.url):
        print("PASS: Registration")
    else:
        print(f"FAIL: Registration {r.url}")
        # print(r.text) # Uncomment to debug
        return

    # Check Dashboard
    r = client.get(f"{BASE_URL}/tests/practice/")
    if "General Aptitude" in r.text:
        print("PASS: Practice Dashboard (Category found)")
    else:
        print("FAIL: Practice Dashboard")

    # Start Test
    r = client.get(f"{BASE_URL}/tests/practice/general-aptitude/")
    if "Assessment" in r.text and "Start Test" not in r.text: # Should be test interface
        print("PASS: Start Test")
    else:
        print("FAIL: Start Test")

    # Store
    r = client.get(f"{BASE_URL}/game/store/")
    if "Life Refill" in r.text:
        print("PASS: Store (Items found)")
    else:
        print("FAIL: Store")
        
    print("Verification Complete.")

if __name__ == "__main__":
    verify()
