import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/local_database_service.dart';

Future<void> showLocalServerConfigDialog(BuildContext context, DatabaseService db) async {
  await showDialog(
    context: context,
    builder: (ctx) => _LocalServerConfigDialog(db: db),
  );
}

class _LocalServerConfigDialog extends StatefulWidget {
  final DatabaseService db;
  const _LocalServerConfigDialog({required this.db});

  @override
  State<_LocalServerConfigDialog> createState() => _LocalServerConfigDialogState();
}

class _LocalServerConfigDialogState extends State<_LocalServerConfigDialog> {
  late final TextEditingController _ipCtrl;
  bool _isTesting = false;
  String? _feedbackMessage;
  bool? _feedbackSuccess;

  @override
  void initState() {
    super.initState();
    _ipCtrl = TextEditingController(
      text: widget.db.activeServerUrl.isNotEmpty
          ? widget.db.activeServerUrl
          : LocalDatabaseService.defaultLanHost,
    );
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = widget.db;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.dns, color: Colors.blueAccent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Local SQLite Server",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  size: 10,
                  color: db.isDatabaseLive ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    db.isDatabaseLive
                        ? "Live Connected: ${db.activeServerUrl}"
                        : "Offline / Using Local Seed Data",
                    style: TextStyle(
                      color: db.isDatabaseLive ? Colors.green.shade700 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Server Host IP / Port:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _ipCtrl,
              decoration: const InputDecoration(
                hintText: "e.g. ${LocalDatabaseService.defaultLanHost} or 10.0.2.2:8080",
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text("Browser (localhost:8080)", style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    _ipCtrl.text = 'localhost:8080';
                  },
                ),
                ActionChip(
                  label: const Text("Wi-Fi LAN", style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    _ipCtrl.text = LocalDatabaseService.defaultLanHost;
                  },
                ),
                ActionChip(
                  label: const Text("Emulator", style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    _ipCtrl.text = '10.0.2.2:8080';
                  },
                ),
                ActionChip(
                  label: const Text("ADB USB", style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    _ipCtrl.text = '127.0.0.1:8080';
                  },
                ),
                ActionChip(
                  label: const Text("Auto-Discover", style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    _ipCtrl.text = '';
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "• Android Emulator: 10.0.2.2:8080\n• Physical Phone on Wi-Fi: ${LocalDatabaseService.defaultLanHost}\n• USB via ADB reverse: 127.0.0.1:8080\n• Leave blank to auto-detect all",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_feedbackSuccess ?? false) ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_feedbackSuccess ?? false) ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  _feedbackMessage!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: (_feedbackSuccess ?? false) ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isTesting ? null : () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
          ),
          icon: _isTesting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.sync, size: 16),
          label: Text(_isTesting ? "Connecting..." : "Connect & Sync"),
          onPressed: _isTesting
              ? null
              : () async {
                  setState(() {
                    _isTesting = true;
                    _feedbackMessage = null;
                  });
                  final ok = await db.setCustomServerHost(_ipCtrl.text.trim());
                  if (!mounted) return;
                  setState(() {
                    _isTesting = false;
                    _feedbackSuccess = ok;
                    _feedbackMessage = ok
                        ? "Connected & synced live SQLite data from ${db.activeServerUrl}!"
                        : "Could not reach SQLite server. Ensure start_local_server.sh is running and device is on same Wi-Fi.";
                  });
                },
        ),
      ],
    );
  }
}
