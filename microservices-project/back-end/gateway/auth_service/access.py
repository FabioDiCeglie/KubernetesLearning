import os, requests

def login(request):
    auth = request.authorization
    if not auth:
        return None, ("Missing credentials", 401)
    
    basicAuth = (auth.username, auth.password)

    response = requests.post(
        f"http://{os.getenv('AUTH_SERVICE_ADDRESS')}/login", auth=basicAuth
    )

    if response.status_code == 200:
        return response.text, None
    else:
        return None, (response.text, response.status_code)