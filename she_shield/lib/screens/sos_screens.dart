import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/voice_engine_service.dart';
import '../widgets/voice_assistant_modals.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await db.loadVoiceSosSettings();
      if (mounted && db.customVoicePhrase.isNotEmpty) {
        _voicePhraseController.text = db.customVoicePhrase;
      }
      await VoiceEngineService().checkMicPermission();
    });
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
      body: AnimatedBuilder(
        animation: VoiceEngineService(),
        builder: (context, _) => Consumer<DatabaseService>(
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

                // 1. System Permissions & Background Voice Protection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Background Protection & Mobile Permissions",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: VoiceEngineService().isListening || VoiceEngineService().isRecording
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            VoiceEngineService().isListening || VoiceEngineService().isRecording
                                ? Icons.check_circle
                                : Icons.pause_circle_outline,
                            size: 12,
                            color: VoiceEngineService().isListening || VoiceEngineService().isRecording
                                ? Colors.green
                                : Colors.blueGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            VoiceEngineService().stateName,
                            style: TextStyle(
                              color: VoiceEngineService().isListening || VoiceEngineService().isRecording
                                  ? Colors.green
                                  : Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Allows SHE SHIELD to run continuously in the background, listening for custom voice phrases even when the screen is locked or via Bluetooth headset/wearables.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.battery_saver, color: Colors.orange),
                        title: const Text("Unrestricted Battery Access"),
                        subtitle: const Text("Prevents OS from sleeping voice detection service"),
                        value: db.batteryUnrestricted,
                        onChanged: (val) => db.toggleBatteryOptimization(val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.location_on, color: Colors.blue),
                        title: const Text("Background & Always-On GPS"),
                        subtitle: const Text("Continuous real-time corridor & location sync"),
                        value: db.backgroundLocationGranted,
                        onChanged: (val) => db.toggleBackgroundLocation(val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.mic, color: Colors.purple),
                        title: const Text("Microphone & Bluetooth Voice Access"),
                        subtitle: const Text("Background neural audio listening on mic and BLE earbuds"),
                        value: db.voiceMicGranted,
                        onChanged: (val) async {
                          if (val) {
                            final granted = await VoiceEngineService().requestMicPermission();
                            db.toggleVoiceMic(granted);
                          } else {
                            db.toggleVoiceMic(false);
                          }
                        },
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final micGranted = await VoiceEngineService().requestMicPermission();
                                  db.toggleVoiceMic(micGranted);
                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      title: Row(
                                        children: [
                                          Icon(
                                            micGranted ? Icons.verified_user : Icons.mic_off,
                                            color: micGranted ? Colors.green : Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            micGranted ? "Permissions Checked" : "Mic Permission Required",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("• Microphone Permission: ${micGranted ? 'GRANTED' : 'DENIED'}"),
                                          const SizedBox(height: 4),
                                          Text(
                                            kIsWeb
                                                ? "• Platform Note: Browser listening & recording operate while this tab stays open."
                                                : "• Platform Note: Android Foreground Microphone service & RECORD_AUDIO.",
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
                                      ],
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.purple),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.security, size: 16, color: Colors.purple),
                                label: const Text("Verify Permissions", style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  VoiceAssistantModals.showPhraseRecognitionModal(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.flash_on, size: 16),
                                label: const Text("Open Voice SOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Hardware Triggers
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
                            labelText: "Custom Voice Activation Phrase",
                            hintText: "e.g. help me now",
                            prefixIcon: const Icon(Icons.record_voice_over, color: Colors.deepPurple),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save),
                              tooltip: "Save Phrase to SQLite",
                              onPressed: () async {
                                final phrase = _voicePhraseController.text.trim();
                                final res = await db.saveVoiceSosSettings(voicePhrase: phrase);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res.success
                                          ? "Voice SOS Phrase saved to SQLite!"
                                          : (res.error ?? "Failed to save voice phrase."),
                                    ),
                                    backgroundColor: res.success ? Colors.green : Colors.red,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          initialValue: ['English', 'Hindi', 'Gujarati', 'Marathi'].contains(db.selectedLanguage)
                              ? db.selectedLanguage
                              : 'English',
                          decoration: const InputDecoration(
                            labelText: "Voice Recognition Language",
                            prefixIcon: Icon(Icons.translate, color: Colors.teal),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'English', child: Text("English (en-US)")),
                            DropdownMenuItem(value: 'Hindi', child: Text("Hindi (हिंदी)")),
                            DropdownMenuItem(value: 'Gujarati', child: Text("Gujarati (ગુજરાતી)")),
                            DropdownMenuItem(value: 'Marathi', child: Text("Marathi (मराठी)")),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              await db.saveVoiceSosSettings(language: val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<int>(
                          initialValue: [30, 60, 120, 300].contains(db.maxRecordingDurationSec)
                              ? db.maxRecordingDurationSec
                              : 120,
                          decoration: const InputDecoration(
                            labelText: "Max Auto-Recording Duration",
                            prefixIcon: Icon(Icons.timer, color: Colors.deepOrange),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 30, child: Text("30 Seconds")),
                            DropdownMenuItem(value: 60, child: Text("1 Minute (60s)")),
                            DropdownMenuItem(value: 120, child: Text("2 Minutes (120s)")),
                            DropdownMenuItem(value: 300, child: Text("5 Minutes (300s)")),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              await db.saveVoiceSosSettings(maxDurationSeconds: val);
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Enable Voice SOS (Auto-Detect & Record)"),
                          subtitle: Text(
                            kIsWeb
                                ? "Requests mic permission and listens while active in browser tab"
                                : "Requests mic permission and listens via active Voice Service",
                            style: const TextStyle(fontSize: 11),
                          ),
                          value: db.voiceSosEnabled && VoiceEngineService().isListening,
                          onChanged: (val) async {
                            final phrase = _voicePhraseController.text.trim();
                            if (val) {
                              if (phrase.length < 2) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Enter and save a custom phrase (2+ characters) first."),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                              final saveRes = await db.saveVoiceSosSettings(
                                voicePhrase: phrase,
                                voiceSosEnabled: true,
                              );
                              if (!saveRes.success && saveRes.statusCode != 0) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(saveRes.error ?? "Permission denied")),
                                );
                                return;
                              }
                              final ok = await VoiceEngineService().enableVoiceSos(db);
                              if (!ok && context.mounted) {
                                await db.saveVoiceSosSettings(voiceSosEnabled: false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(VoiceEngineService().errorMessage ?? "Unable to start Voice SOS."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              await VoiceEngineService().disableVoiceSos();
                              await db.saveVoiceSosSettings(voiceSosEnabled: false);
                            }
                          },
                        ),
                        const SizedBox(height: 6),

                        AnimatedBuilder(
                          animation: VoiceEngineService(),
                          builder: (context, _) {
                            final eng = VoiceEngineService();
                            if (eng.state == VoiceSosState.IDLE) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: eng.state == VoiceSosState.RECORDING
                                    ? Colors.red.shade50
                                    : Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: eng.state == VoiceSosState.RECORDING
                                      ? Colors.red.shade300
                                      : Colors.purple.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "State: ${eng.stateName} • ${eng.statusDetail}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: eng.state == VoiceSosState.RECORDING
                                          ? Colors.red.shade900
                                          : Colors.purple.shade900,
                                    ),
                                  ),
                                  if (eng.state == VoiceSosState.RECORDING) ...[
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade800,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.stop_circle),
                                      label: Text("Stop Recording (${eng.elapsedSeconds}s) & Save to Vault"),
                                      onPressed: () => eng.stopRecordingAndSave(db),
                                    ),
                                  ],
                                ],
                              ),
                            );
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
                          onChanged: (val) => db.saveVoiceSosSettings(silentSosMode: val),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => VoiceAssistantModals.showPhraseRecognitionModal(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.mic, size: 18),
                                label: const Text("Recognise Voice Phrase", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => VoiceAssistantModals.showAudioRecorderModal(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.deepOrange.shade700, width: 1.5),
                                  foregroundColor: Colors.deepOrange.shade900,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.fiber_manual_record, size: 16, color: Colors.deepOrange),
                                label: const Text("Record Audio Proof", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
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
      ),
    );
  }
}
