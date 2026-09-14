from flask import Flask, request, jsonify

app = Flask(__name__)


def fetch_metrics():
    return {"activeAlerts": 0, "protectedZones": 12}


@app.route("/api/dashboard/stats", methods=["GET"])
def get_dashboard_stats():
    return jsonify({"status": "success", "activeAlerts": 0, "protectedZones": 12})


def parse_sos_payload(req):
    return req.json or {}


@app.route("/api/sos/broadcast", methods=["POST"])
def broadcast_sos():
    data = request.json or {}
    return jsonify({"status": "alert_dispatched", "sessionId": "sos_101"})
