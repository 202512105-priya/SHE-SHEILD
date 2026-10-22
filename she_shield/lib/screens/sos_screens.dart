import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SosProtectionCenterScreen();
  }
}

class SosProtectionCenterScreen extends StatefulWidget {
  const SosProtectionCenterScreen({super.key});

  @override
  State<SosProtectionCenterScreen> createState() => _SosProtectionCenterScreenState();
}

class _SosProtectionCenterScreenState extends State<SosProtectionCenterScreen> {
  late TextEditingController _voicePhraseController;
  late TextEditingController _secretWordController;

  @override
  void initState() {
    super.initState();
    final db = Provider.of<DatabaseService>(context, listen: false);
    _voicePhraseController = TextEditingController(text: db.customVoicePhrase);
    _secretWordController = TextEditingController(text: db.secretWord);
  }

  @override
  void dispose() {
    _voicePhraseController.dispose();
    _secretWordController.dispose();
    super.dispose();
  }

  void _simulateWearableTrigger(String triggerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.flash_on, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              "$triggerName SOS Signal!",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hardware trigger detected via BLE Wearable Sensor ($triggerName).",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Dispatching High-Priority SOS Payload to Police Grid & Guardians...",
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red.shade900),
            onPressed: () => Navigator.pop(context),
            child: const Text("Acknowledge Signal"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS Protection Center"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DatabaseService>(
        builder: (context, db, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade900, Colors.purple.shade900],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_moon, color: Colors.amber, size: 40),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hardware & Voice SOS Engine",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Configure multi-trigger fallback channels & offline protection",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 1. Hardware Triggers
                const Text(
                  "Hardware Buttons Triggers",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.volume_up, color: Colors.purple),
                        title: const Text("Volume Button Trigger"),
                        subtitle: const Text("Press Volume Up + Down simultaneously"),
                        value: db.volButtonTrigger,
                        onChanged: (val) => db.toggleVolTrigger(val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.power_settings_new, color: Colors.red),
                        title: const Text("Double Power Button"),
                        subtitle: const Text("Double press power key within 1 second"),
                        value: db.doublePowerTrigger,
                        onChanged: (val) => db.toggleDoublePower(val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.touch_app, color: Colors.orange),
                        title: const Text("Triple Power Button"),
                        subtitle: const Text("Triple press power key for stealth alert"),
                        value: db.triplePowerTrigger,
                        onChanged: (val) => db.toggleTriplePower(val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.bluetooth, color: Colors.blue),
                        title: const Text("Bluetooth Trigger"),
                        subtitle: const Text("BLE Beacon signal instant trigger"),
                        value: db.bluetoothTrigger,
                        onChanged: (val) => db.toggleBluetooth(val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Voice SOS Engine
                const Text(
                  "Voice SOS Engine Settings",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _voicePhraseController,
                          decoration: InputDecoration(
                            labelText: "Custom Voice Phrase",
                            hintText: "e.g. capcap",
                            prefixIcon: const Icon(Icons.record_voice_over, color: Colors.deepPurple),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () {
                                db.setCustomVoicePhrase(_voicePhraseController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Custom Voice Phrase Saved!")),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          initialValue: db.selectedLanguage,
                          decoration: const InputDecoration(
                            labelText: "Voice SOS Multi-Language",
                            prefixIcon: Icon(Icons.translate, color: Colors.teal),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Hindi', child: Text("Hindi (हिंदी)")),
                            DropdownMenuItem(value: 'English', child: Text("English")),
                            DropdownMenuItem(value: 'Gujarati', child: Text("Gujarati (ગુજરાતી)")),
                            DropdownMenuItem(value: 'Marathi', child: Text("Marathi (मराठी)")),
                          ],
                          onChanged: (val) {
                            if (val != null) db.setSelectedLanguage(val);
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _secretWordController,
                          decoration: InputDecoration(
                            labelText: "Secret Deactivation Word",
                            hintText: "e.g. Box Box",
                            prefixIcon: const Icon(Icons.vpn_key, color: Colors.indigo),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () {
                                db.setSecretWord(_secretWordController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Secret Deactivation Word Saved!")),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Silent SOS Mode"),
                          subtitle: const Text("Stealth trigger without siren sound"),
                          value: db.silentSosMode,
                          onChanged: (val) => db.toggleSilentSos(val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Offline Fallback Settings
                const Text(
                  "Offline Fallback & Connectivity",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.sms, color: Colors.green),
                        title: const Text("SMS Fallback"),
                        subtitle: const Text("Sends encrypted SMS when data network is unavailable"),
                        value: db.smsFallback,
                        onChanged: (val) {},
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.location_off, color: Colors.blueGrey),
                        title: const Text("Offline Coordinate Caching"),
                        subtitle: const Text("Caches last known GPS points locally"),
                        value: db.offlineCacheCoords,
                        onChanged: (val) {},
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.sync, color: Colors.deepOrange),
                        title: const Text("Alert Sync Queue"),
                        subtitle: const Text("Auto-sync pending payloads upon reconnection"),
                        value: db.alertSyncQueue,
                        onChanged: (val) {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Wearable SOS Triggers Simulator
                const Text(
                  "Wearable SOS Triggers Simulator",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  "Test hardware event triggers from paired Bluetooth devices",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.vibration, size: 18),
                        label: const Text("Wrist Triple Tap", style: TextStyle(fontSize: 11)),
                        onPressed: () => _simulateWearableTrigger("Wrist Triple Tap"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.compress, size: 18),
                        label: const Text("Ring Squeeze", style: TextStyle(fontSize: 11)),
                        onPressed: () => _simulateWearableTrigger("Smart Ring Squeeze"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.album, size: 18),
                        label: const Text("Pendant Press", style: TextStyle(fontSize: 11)),
                        onPressed: () => _simulateWearableTrigger("Pendant Button Press"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
