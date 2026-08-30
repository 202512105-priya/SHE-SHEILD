import jwt
def generate_token(user_id): return jwt.encode({'user_id': user_id}, 'SECRET_KEY', algorithm='HS256')
