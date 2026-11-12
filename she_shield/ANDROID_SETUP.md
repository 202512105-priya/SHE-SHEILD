# SHE SHIELD — Android APK & Backend Setup Guide

## 1. Deliverables Generated
- **Debug APK (Testing)**: `she_shield/build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK (Signed Distribution)**: `she_shield/build/app/outputs/flutter-apk/app-release.apk`
  - Application ID: `com.sheshield.she_shield`
  - App Label: `SHE SHIELD`
  - Version: `1.0.0` (versionCode `1`)
  - Signed with `she_shield/android/app/she-shield-release.jks` (`CN=SHE SHIELD`).
- **Database Schema & Initializer**:
  - Schema snapshot: `she_shield/server/schema.sql`
  - Live API server & database migrator/initializer: `she_shield/server/local_sqlite_server.py`
  - Admin credential utility: `she_shield/server/create_admin.py`

## 2. Running the SQLite Backend Server
The Android app communicates with the SQLite backend over HTTP/REST:
```bash
cd she_shield/server
python3 -u local_sqlite_server.py
```
This initializes/migrates `she_shield/server/she_shield.db` cleanly without erasing existing records and listens on `0.0.0.0:8080`.

Optional environment variables:
- `GOOGLE_MAPS_API_KEY`: Enables Google Places / Directions API instead of the default OpenStreetMap Photon/Nominatim & OSRM providers.
- `SHESHIELD_SMTP_HOST`, `SHESHIELD_SMTP_PORT`, `SHESHIELD_SMTP_USER`, `SHESHIELD_SMTP_PASS`, `SHESHIELD_SMTP_FROM`: Enables real SMTP guardian email notifications (when unset, the app explicitly displays `NOT_CONFIGURED` so links are shared manually).

## 3. Installing & Connecting on an Android Device
1. Copy `app-release.apk` (or `app-debug.apk`) to the Android device and allow installation from your file manager/browser ("Install unknown apps"), or install via USB:
   ```bash
   adb install -r she_shield/build/app/outputs/flutter-apk/app-release.apk
   ```
2. **Connecting to the Backend from Another Android Phone**:
   - **Same Wi-Fi LAN**: Ensure the host Mac/PC firewall allows incoming TCP `8080`. Open **SHE SHIELD**, tap the **Local SQLite Server** badge on Welcome/Login, and enter `<HOST_LAN_IP>:8080` (e.g., `172.24.75.79:8080`). The app persists this URL in `SharedPreferences` across restarts.
   - **Across Different Networks / Cellular Data**: Expose port `8080` over an HTTPS tunnel (e.g. Cloudflare Tunnel / ngrok) and enter that `https://...` URL in the **Local SQLite Server** dialog.
   - **USB ADB Debugging**: Run `adb reverse tcp:8080 tcp:8080` and connect to `127.0.0.1:8080`.
   - **Android Emulator**: Automatically connects to `10.0.2.2:8080`.

## 4. Account Provisioning & Login
- **Users & Guardians**: Register directly inside the app via **New Account Registration** and select either **Safety User** or **Guardian**.
- **Admin**: Provision/reset an Admin password locally using `python3 she_shield/server/create_admin.py --email <admin-email>`.
- **Officer**: Sign in as Admin -> open **Admin Command Center** -> click **Create Officer** (`POST /api/admin/users/create_officer`).
