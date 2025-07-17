import jwt, datetime, os
from flask import Flask, request, jsonify
from flask_mysqldb import MySQL

server = Flask(__name__)
mysql = MySQL(server)

server.config['MYSQL_HOST'] = os.environ.get('MYSQL_HOST')
server.config['MYSQL_USER'] = os.environ.get('MYSQL_USER')
server.config['MYSQL_PASSWORD'] = os.environ.get('MYSQL_PASSWORD')
server.config['MYSQL_DB'] = os.environ.get('MYSQL_DB')
server.config['MYSQL_PORT'] = int(os.environ.get('MYSQL_PORT', 3306))


@server.route('/health', methods=['GET'])
def health():
    return "", 204

@server.route('/login', methods=['POST'])
def login():
    auth = request.authorization
    if not auth:
        return jsonify({'error': 'Missing credentials'}), 401
    
    cur = mysql.connection.cursor()
    res = cur.execute("SELECT email, password FROM user WHERE email=%s", (auth.username,))
    if res > 0:
        user_row = cur.fetchone()
        email = user_row[0]
        password = user_row[1]
        
        if auth.username != email or auth.password != password:
            return jsonify({'error': 'Invalid credentials'}), 401
        else:
            return createJWT(auth.username, os.environ.get('JWT_SECRET'), True)
    else:
        return jsonify({'error': 'Invalid credentials'}), 401


@server.route('/validate', methods=['POST'])
def validate():
    encoded_jwt = request.headers['Authorization']
    if not encoded_jwt:
        return jsonify({'error': 'Missing credentials'}), 401
    
    encoded_jwt = encoded_jwt.split(" ")[1]
    try:
        decoded = jwt.decode(encoded_jwt, os.environ.get('JWT_SECRET'), algorithms=['HS256'])
        return decoded, 200
    except:
        return jsonify({'error': 'Invalid token'}), 401


def createJWT(username, secret, authz):
    return jwt.encode(
        {
            'username': username,
            'exp': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=1),
            'iat': datetime.datetime.utcnow(),
            'admin': authz
        },
        secret,
        algorithm='HS256'
    )


if __name__ == '__main__':
    server.run(host='0.0.0.0', port=8000)