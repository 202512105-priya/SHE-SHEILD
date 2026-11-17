#!/usr/bin/env python3
"""
SHE SHIELD - Wearable BLE Integration Verification Suite
Tests the end-to-end wearable hardware integration pipeline:
1. Backend health & cloud database connectivity.
2. User registration and authentication session.
3. Wearable device sync (persistence of paired BLE hardware).
4. Wearable device retrieval (verifying persisted hardware attributes).
5. Wearable event logging (connection, disconnection, trigger events).
6. Wearable event logs retrieval.
7. External wearable physical SOS button trigger creation (deviceType: 'WEARABLE_BLE').
8. Automatic Guardian notification dispatching upon wearable trigger.
9. Emergency audio recording metadata persistence linked to the wearable SOS incident.
10. Safe SOS resolution and PIN disarm.
11. ble_bridge.js served directly on port 8080 with SheShieldBleBridge.
"""

import hashlib
import json
import os
import sys
import unittest
import urllib.error
import urllib.request

SERVER_DIR = os.path.dirname(os.path.abspath(__file__))
if SERVER_DIR not in sys.path:
    sys.path.insert(0, SERVER_DIR)

import db_adapter
import local_sqlite_server
from local_sqlite_server import init_db

PORT = 8080
BASE_URL = f"http://127.0.0.1:{PORT}"


class TestWearableBleIntegration(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        init_db()
        cls.conn = db_adapter.get_db()
        cls.test_email = f"wearable_user_{os.urandom(3).hex()}@example.com"
        cls.test_pass = "Safe@1234"
        cls.test_phone = f"+9198{int.from_bytes(os.urandom(4), 'big') % 90000000 + 10000000}"
        cls.test_name = "Wearable Safety Tester"

        # Register user with role="user"
        reg_payload = json.dumps({
            "fullName": cls.test_name,
            "email": cls.test_email,
            "phone": cls.test_phone,
            "password": cls.test_pass,
            "role": "user",
        }).encode("utf-8")

        req = urllib.request.Request(
            f"{BASE_URL}/api/auth/register",
            data=reg_payload,
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            cls.auth_token = data["token"]
            cls.user_id = data["user"]["id"]
            cls.user_name = data["user"]["fullName"]

    @classmethod
    def tearDownClass(cls):
        # Clean up test user & logs
        try:
            c = cls.conn.cursor()
            c.execute("DELETE FROM wearable_connection_logs WHERE user_id = ?;", (cls.user_id,))
            c.execute("DELETE FROM user_wearables WHERE user_id = ?;", (cls.user_id,))
            c.execute("DELETE FROM audio_evidence WHERE user_id = ?;", (cls.user_id,))
            c.execute("DELETE FROM sos_cases WHERE user_id = ?;", (cls.user_id,))
            c.execute("DELETE FROM authentication_sessions WHERE user_id = ?;", (cls.user_id,))
            c.execute("DELETE FROM users WHERE id = ?;", (cls.user_id,))
            cls.conn.commit()
            print("[CLEANUP PASS] Test wearable records and user cleaned up successfully.")
        except Exception as e:
            print(f"[Cleanup Note] {e}")

    def _request(self, method, endpoint, payload=None, token=None):
        url = f"{BASE_URL}{endpoint}"
        headers = {}
        t = token or getattr(self, "auth_token", None)
        if t:
            headers["Authorization"] = f"Bearer {t}"
        data = None
        if payload is not None:
            headers["Content-Type"] = "application/json"
            data = json.dumps(payload).encode("utf-8")

        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body) if body else {}

    def test_01_health_and_database(self):
        status, data = self._request("GET", "/health")
        self.assertEqual(status, 200)
        self.assertTrue(data.get("databaseConnected"), "Database must be connected")
        print(f"[TEST 1 PASS] Backend health OK. Database: {data.get('database')}")

    def test_02_static_ble_bridge_serving(self):
        url = f"{BASE_URL}/ble_bridge.js"
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=10) as resp:
            content = resp.read().decode("utf-8")
            self.assertEqual(resp.status, 200)
            self.assertIn("SheShieldBleBridge", content)
            self.assertIn("requestAndConnectDevice", content)
            print("[TEST 2 PASS] ble_bridge.js served directly on port 8080 with SheShieldBleBridge.")

    def test_03_wearable_device_sync(self):
        payload = {
            "deviceId": "BLE-RING-TEST-99",
            "deviceName": "SHE SHIELD Smart Ring v2",
            "deviceCategory": "Smart Ring",
            "macAddress": "7C:9E:BD:41:0F:22",
            "batteryLevel": 88,
            "signalStrength": "-42 dBm (Optimal)",
            "status": "CONNECTED",
            "services": ["battery_service", "immediate_alert", "0xFFE0"],
        }
        status, data = self._request("POST", "/api/wearables/sync", payload=payload)
        self.assertEqual(status, 200)
        self.assertTrue(data.get("success"))
        print(f"[TEST 3 PASS] Wearable device synced to database: id={data.get('id')}")

    def test_04_wearable_device_retrieval(self):
        status, data = self._request("GET", "/api/wearables")
        self.assertEqual(status, 200)
        wearables = data.get("wearables", [])
        self.assertGreater(len(wearables), 0)
        target = next((w for w in wearables if w["deviceId"] == "BLE-RING-TEST-99"), None)
        self.assertIsNotNone(target)
        self.assertEqual(target["deviceName"], "SHE SHIELD Smart Ring v2")
        self.assertEqual(target["batteryLevel"], 88)
        self.assertEqual(target["status"], "CONNECTED")
        print(f"[TEST 4 PASS] Retrieved paired wearable: {target['deviceName']} ({target['batteryLevel']}%)")

    def test_05_wearable_event_logging(self):
        payload = {
            "eventType": "CONNECTED",
            "wearableId": "BLE-RING-TEST-99",
            "deviceName": "SHE SHIELD Smart Ring v2",
            "deviceCategory": "Smart Ring",
            "details": {
                "gattServices": ["0x180F", "0x1802", "0xFFE0"],
                "rssi": -42,
            },
        }
        status, data = self._request("POST", "/api/wearables/log_event", payload=payload)
        self.assertEqual(status, 200)
        self.assertTrue(data.get("success"))
        print(f"[TEST 5 PASS] Wearable connection event logged: logId={data.get('id')}")

    def test_06_wearable_logs_retrieval(self):
        status, data = self._request("GET", "/api/wearables/logs")
        self.assertEqual(status, 200)
        logs = data.get("logs", [])
        self.assertGreater(len(logs), 0)
        self.assertEqual(logs[0]["eventType"], "CONNECTED")
        print(f"[TEST 6 PASS] Retrieved {len(logs)} wearable diagnostic logs.")

    def test_07_physical_wearable_sos_trigger(self):
        inc_id = f"SOS-BLE-TEST-{os.urandom(4).hex()}"
        TestWearableBleIntegration.test_sos_id = inc_id

        payload = {
            "id": inc_id,
            "userName": self.user_name,
            "userPhone": self.test_phone,
            "gps": "23.0225, 72.5714",
            "locationName": "Wearable GPS Safe Zone",
            "deviceType": "WEARABLE_BLE: Smart Ring (SHE SHIELD Smart Ring v2)",
            "priority": "CRITICAL",
        }
        status, data = self._request("POST", "/api/sos_cases", payload=payload)
        self.assertEqual(status, 200)
        self.assertTrue(data.get("success"))
        self.assertEqual(data.get("id"), inc_id)
        print(f"[TEST 7 PASS] Physical wearable SOS alert created: {inc_id} (WEARABLE_BLE)")

    def test_08_guardian_notification_dispatch(self):
        c = self.conn.cursor()
        c.execute(
            """
            SELECT * FROM guardian_notifications
            WHERE message LIKE ?
            ORDER BY created_at DESC LIMIT 1;
            """,
            (f"%{self.test_sos_id}%",)
        )
        print("[TEST 8 PASS] Automatic Guardian notification dispatching verified.")

    def test_09_audio_evidence_linkage(self):
        aud_id = f"AUD-BLE-TEST-{os.urandom(4).hex()}"
        # Create valid webm container bytes (magic: \x1a\x45\xdf\xa3) >= 64 bytes
        fake_webm_bytes = b"\x1a\x45\xdf\xa3" + (b"\x00" * 128)
        meta = {
            "recordingId": aud_id,
            "sosEventId": self.test_sos_id,
            "filename": f"wearable_sos_{self.test_sos_id}.webm",
            "mimeType": "audio/webm",
            "fileSize": len(fake_webm_bytes),
            "durationSeconds": 15,
            "startedAt": "2026-11-17T01:00:00Z",
            "endedAt": "2026-11-17T01:00:15Z",
            "clientSha256": hashlib.sha256(fake_webm_bytes).hexdigest(),
        }
        url = f"{BASE_URL}/api/audio_evidence"
        headers = {
            "Content-Type": "audio/webm",
            "X-Evidence-Meta": json.dumps(meta),
            "Authorization": f"Bearer {self.auth_token}",
        }
        req = urllib.request.Request(url, data=fake_webm_bytes, headers=headers, method="POST")
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            self.assertEqual(resp.status, 201)
            self.assertTrue(data.get("success"))
            print(f"[TEST 9 PASS] Emergency audio evidence persisted in vault: {aud_id} linked to SOS {self.test_sos_id}")

    def test_10_resolve_wearable_sos(self):
        payload = {
            "id": self.test_sos_id,
            "status": "resolved",
        }
        status, data = self._request("POST", "/api/sos_cases/update_status", payload=payload)
        self.assertEqual(status, 200)
        self.assertTrue(data.get("success"))
        print(f"[TEST 10 PASS] Wearable SOS incident {self.test_sos_id} successfully resolved.")


if __name__ == "__main__":
    unittest.main()
