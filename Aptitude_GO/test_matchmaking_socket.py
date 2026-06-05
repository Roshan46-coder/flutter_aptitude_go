import asyncio
import websockets
import json
import urllib.request
import urllib.parse
from http.cookiejar import CookieJar

def authenticate_and_get_cookie(username, password):
    cj = CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    
    # 1. Get CSRF token
    req = urllib.request.Request('http://127.0.0.1:8080/login/', headers={'User-Agent': 'Mozilla/5.0'})
    response = opener.open(req)
    csrf_token = ''
    for c in cj:
        if c.name == 'csrftoken':
            csrf_token = c.value
            
    # 2. Login
    data = urllib.parse.urlencode({'username': username, 'password': password, 'csrfmiddlewaretoken': csrf_token}).encode('utf-8')
    req = urllib.request.Request('http://127.0.0.1:8080/login/', data=data, headers={
        'User-Agent': 'Mozilla/5.0',
        'Referer': 'http://127.0.0.1:8080/login/',
        'Content-Type': 'application/x-www-form-urlencoded'
    })
    response = opener.open(req)
    
    # 3. Get sessionid
    sessionid = ''
    for c in cj:
        if c.name == 'sessionid':
            sessionid = c.value
            
    return sessionid

async def run_client(name, cookie):
    try:
        async with websockets.connect(
            'ws://127.0.0.1:8080/ws/matchmaking/',
            extra_headers={'Cookie': cookie}
        ) as ws:
            print(f'{name} connected. Sending match request...')
            await ws.send(json.dumps({
                "action": "search_match",
                "topic": "general-aptitude"
            }))
            
            # Wait for match
            while True:
                msg = await asyncio.wait_for(ws.recv(), timeout=35.0)
                data = json.loads(msg)
                print(f'{name} received: {data}')
                if data.get('type') == 'match_found':
                    return True
                elif data.get('type') == 'error':
                    print(f'{name} got error: {data}')
                    return False
    except asyncio.TimeoutError:
        print(f'{name} Matchmaking timed out waiting for server.')
        return False
    except Exception as e:
        print(f'{name} WebSocket error: {e}')
        return False

async def test_matchmaking():
    # To run this script, we need two valid users
    # Adjust username/password according to your local DB
    session1 = authenticate_and_get_cookie('player2', 'testpassword123')
    session2 = authenticate_and_get_cookie('Neeraj@1', 'testpassword123') # Replace 'Neeraj@1' with your actual username if needed
    
    if not session1 or not session2:
        print("Failed to authenticate one or both users. Please check the test script credentials.")
        return
        
    cookie1 = f'sessionid={session1}'
    cookie2 = f'sessionid={session2}'
    
    print('Starting concurrent websockets connection...')
    
    results = await asyncio.gather(
        run_client('Player 2', cookie1),
        run_client('Player 1', cookie2)
    )
    
    if all(results):
        print('\nSUCCESS: Both players successfully matched! The matchmaking system is fully functional.')
    else:
        print('\nFAILED: One or both players did not match.')

if __name__ == '__main__':
    asyncio.run(test_matchmaking())
