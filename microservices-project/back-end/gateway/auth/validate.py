import os, requests

def token(request):
    if not "Authorization" in request.headers:
        return None, ("Missing credentials", 401)
    
    token = request.headers["Authorization"]

    if not token:
        return None, ("Missing credentials", 401)
    
    response = requests.post(
        f"http://{os.getenv('AUTH_SERVICE_ADDRESS')}/validate",
        headers={"Authorization": token}
    )

    if response.status_code == 200:
        return response.text, None
    else:
        return None, (response.text, response.status_code)