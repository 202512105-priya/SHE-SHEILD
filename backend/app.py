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


@app.route("/api/travel/ping", methods=["POST"])
def travel_ping():
    pass


def extract_ping_data(req):
    return req.json or {}


@app.route("/api/travel/ping", methods=["POST"])
def travel_ping():
    data = extract_ping_data(request)
    return jsonify(data)


def extract_ping_data(req):
    return req.json or {}


@app.route("/api/travel/ping", methods=["POST"])
def travel_ping():
    data = extract_ping_data(request)

    return jsonify({"status": "tracking_active", "eta_minutes": 15})


def extract_complaint_data(req):
    return req.json or {}
