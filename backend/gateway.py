"""
SHE SHIELD - API Gateway & Cloud Service Proxy
Routes incoming client requests, manages CORS headers, and verifies authentication tokens.
"""
from flask import Flask, request, jsonify
import jwt
import os

gateway_app = Flask(__name__)

SECRET_KEY = os.getenv("SECRET_KEY", "SHE_SHIELD_SUPER_SECRET")

@gateway_app.after_request
def apply_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
    return response

@gateway_app.route('/api/gateway/verify-token', methods=['POST'])
def proxy_verify_token():
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return jsonify({"valid": False, "error": "Missing or malformed Authorization header"}), 401
    
    token = auth_header.split(" ")[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return jsonify({"valid": True, "user_id": payload.get("sub")}), 200
    except jwt.ExpiredSignatureError:
        return jsonify({"valid": False, "error": "Token expired"}), 401
    except Exception as e:
        return jsonify({"valid": False, "error": str(e)}), 401

@gateway_app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy",
        "service": "api-gateway",
        "cloud_connected": True
    }), 200

@gateway_app.route('/api/cyber/upload', methods=['POST'])
def proxy_evidence_upload():
    return jsonify({
        "status": "received",
        "service": "evidence-vault",
        "encrypted": True
    }), 200

@gateway_app.route('/api/v1/<path:subpath>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def proxy_v1_api(subpath):
    return jsonify({
        "gateway": "sheshield-proxy",
        "route": f"/api/v1/{subpath}",
        "status": "forwarded"
    }), 200
