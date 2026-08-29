import jwt
import datetime

SECRET_KEY = "SHE_SHIELD_SECRET"


def generate_jwt_token(user_id):
    payload = {
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=1),
        "sub": user_id,
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")
