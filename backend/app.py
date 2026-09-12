from flask import Flask, request, jsonify

app = Flask(__name__)


def fetch_metrics():
    return {"activeAlerts": 0, "protectedZones": 12}


@app.route("/api/dashboard/stats", methods=["GET"])
def get_dashboard_stats():
    return jsonify({"status": "success", "activeAlerts": 0, "protectedZones": 12})
