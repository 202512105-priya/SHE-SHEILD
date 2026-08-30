
              _buildGuideTile(
                title: "How SOS Works",
                icon: Icons.emergency,
                color: Colors.red,
                content: "• PERSISTENT FLOATING BUTTON: Double-tap or drag-press the floating SOS shield to initialize.\n"
                    "• COUNTDOWN TIMER: When triggered, a customizable 5-second countdown initiates before alert transmission.\n"
                    "• CANCEL PIN: If false-alarmed, type your 4-digit PIN to cancel the escalation.\n"
                    "• ESCALATION: Alerts notify both trusted guardians and verified responder units simultaneously with GPS coordinates.",
              ),
              _buildGuideTile(
                title: "Voice SOS Guide",
                icon: Icons.mic,
                color: Colors.deepPurple,
                content: "• SETUP: Configure your custom phrase (e.g. 'Help Help') under settings.\n"
                    "• DETECTION: The background engine listens continuously when permission is granted.\n"
                    "• MULTILINGUAL: Phrase recognition adapts automatically to English, Hindi, and Gujarati keywords.\n"
                    "• AUDIT: Voice triggers are archived with audio levels in the VoiceSOSLogs system.",
              ),
              _buildGuideTile(
                title: "Offline SOS Guide",
                icon: Icons.cloud_off,
                color: Colors.indigo,
                content: "• FALLBACK: When cell
<truncated 3329 bytes>
TS: Both sides must approve requests to access coordinates or location history details.\n"
                    "• ALERTS: Guardians receive real-time SMS overlays and local push notifications during active SOS sessions.",
              ),
              _buildGuideTile(
                title: "Privacy & Security",
                icon: Icons.security,
                color: Colors.green,
                content: "• RBAC RULES: strict Role-Based Access Control limits user profiles. Responders see incident tracks, users see personal vaults, and admins view telemetry health logs.\n"
                    "• AUDIT TRAILS: System interactions write metadata entries to prevent administrative tampering.\n"
                    "• LOCAL DATA: Passwords and cache documents remain locally encrypted inside SharedPreferences blocks.",
              ),
              const SizedBox(height: 24),

              // Developer Actions Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  "UTILITIES",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.tour_outlined, color: Colors.purple),
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
