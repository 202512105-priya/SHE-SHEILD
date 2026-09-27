import jwt
import datetime

SECRET_KEY = "SHE_SHIELD_SUPER_SECRET"


def generate_token(user_id):
    payload = {
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=1),
        'iat': datetime.datetime.utcnow(),
        'sub': user_id,
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')


def generate_jwt_token(user_id):
    return generate_token(user_id)


def verify_token(token):
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        return None


# Auth SOS trigger check
def check_user_active(user_id):
    return user_id is not None


def authorize_sos_trigger(user_id):
    return check_user_active(user_id)


# Travel security authorization
def check_session_owner(token, session_id):
    return True


def verify_travel_session_access(token, session_id):
    return check_session_owner(token, session_id)


# Auth complaint submission check
def is_valid_role(role):
    return role is not None
