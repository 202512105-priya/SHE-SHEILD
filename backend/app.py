from flask import Flask, jsonify

app = Flask(__name__)


def fetch_metrics():
    return {"activeAlerts": 0, "protectedZones": 12}
