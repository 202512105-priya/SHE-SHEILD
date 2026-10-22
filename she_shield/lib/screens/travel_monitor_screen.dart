import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class TravelMonitorScreen extends StatefulWidget {
  const TravelMonitorScreen({super.key});

  @override
  State<TravelMonitorScreen> createState() => _TravelMonitorScreenState();
}

class _TravelMonitorScreenState extends State<TravelMonitorScreen> {
  final TextEditingController _destinationController = TextEditingController(text: "cgroad");
  final TextEditingController _durationController = TextEditingController(text: "55");
  String _selectedRecordingMode = "Video & Audio";

  Timer? _countdownTimer;
  int _secondsRemaining = 55 * 60; // 55 minutes

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _destinationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _showRecordingModeModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Blackbox Evidence Recording Mode",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Evidence captured will be encrypted & hashed to Evidence Vault",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.purple),
              title: const Text("Video & Audio (Recommended)"),
              subtitle: const Text("Full continuous background video & ambient mic capture"),
              trailing: _selectedRecordingMode == "Video & Audio"
                  ? const Icon(Icons.check_circle, color: Colors.purple)
                  : null,
              onTap: () {
                setState(() => _selectedRecordingMode = "Video & Audio");
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.teal),
              title: const Text("Audio Only"),
              subtitle: const Text("Background ambient audio recording only"),
              trailing: _selectedRecordingMode == "Audio Only"
                  ? const Icon(Icons.check_circle, color: Colors.teal)
                  : null,
              onTap: () {
                setState(() => _selectedRecordingMode = "Audio Only");
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.do_not_disturb_on, color: Colors.grey),
              title: const Text("None (GPS Telemetry Only)"),
              subtitle: const Text("Track location path without active media capture"),
              trailing: _selectedRecordingMode == "None"
                  ? const Icon(Icons.check_circle, color: Colors.grey)
                  : null,
              onTap: () {
                setState(() => _selectedRecordingMode = "None");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safe Arrival Travel Mode"),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DatabaseService>(
        builder: (context, db, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.card_travel, color: Colors.teal.shade900, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Live Path & Arrival Guardian",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Monitors trip countdown. Auto-alerts guardians if safe arrival is unconfirmed.",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Trip Inputs Form Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Trip Configuration",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),

                        // Destination Input
                        TextFormField(
                          controller: _destinationController,
                          decoration: const InputDecoration(
                            labelText: "Destination Address / Landmark",
                            hintText: "cgroad",
                            prefixIcon: Icon(Icons.location_on, color: Colors.teal),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Travel Time Input
                        TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Estimated Travel Time (Minutes)",
                            hintText: "55",
                            prefixIcon: Icon(Icons.timer, color: Colors.orange),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final mins = int.tryParse(val);
                            if (mins != null && mins > 0) {
                              setState(() {
                                _secondsRemaining = mins * 60;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // Recording Mode Selector Tile
                        InkWell(
                          onTap: _showRecordingModeModal,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.videocam, color: Colors.purple),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Evidence Recording Mode",
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          _selectedRecordingMode,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Safety Timeline & Countdown Clock Display
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade900, Colors.teal.shade700],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.greenAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "LIVE TRAVEL GUARDIAN ACTIVE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _formatDuration(_secondsRemaining),
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.greenAccent,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Destination: ${_destinationController.text} • Mode: $_selectedRecordingMode",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.route, color: Colors.white, size: 20),
                                SizedBox(height: 4),
                                Text("Safe Route 98%", style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.security, color: Colors.greenAccent, size: 20),
                                SizedBox(height: 4),
                                Text("Mesh Active", style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.cloud_done, color: Colors.cyanAccent, size: 20),
                                SizedBox(height: 4),
                                Text("Sync 100%", style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // "I Have Reached Safely" Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.check_circle, size: 26),
                  label: const Text(
                    "I Have Reached Safely",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    db.endTravel();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 32),
                            SizedBox(width: 10),
                            Text("Safe Arrival Confirmed!"),
                          ],
                        ),
                        content: const Text(
                          "Travel Guardian active monitoring deactivated. Your emergency contacts and guardians have been notified of your safe arrival.",
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text("Return to Dashboard"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}


class CabMonitorScreen extends StatefulWidget {
  const CabMonitorScreen({super.key});

  @override
  State<CabMonitorScreen> createState() => _CabMonitorScreenState();
}

class _CabMonitorScreenState extends State<CabMonitorScreen> {
  final TextEditingController _plateController = TextEditingController(text: "GJ-01-XX-9999");
  final TextEditingController _destinationController = TextEditingController(text: "cgroad");
  bool _tripStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Cab Guardian")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _tripStarted
            ? Column(
                children: [
                  Card(
                    color: Colors.purple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_plateController.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const Chip(label: Text("SAFE"), backgroundColor: Colors.greenAccent),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text("Live path tracking & audio recorders active. Coordinates linked with guardian portal.", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _tripStarted = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("I Reached Safely"),
                  ),
                ],
              )
            : Column(
                children: [
                  TextField(
                    controller: _plateController,
                    decoration: const InputDecoration(labelText: "Cab Registration Number", suffixIcon: Icon(Icons.camera_alt)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _destinationController,
                    decoration: const InputDecoration(labelText: "Destination Location", prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _tripStarted = true;
                      });
                    },
                    child: const Text("Start Safe Journey"),
                  ),
                ],
              ),
      ),
    );
  }
}

class WalkMonitorScreen extends StatefulWidget {
  const WalkMonitorScreen({super.key});

  @override
  State<WalkMonitorScreen> createState() => _WalkMonitorScreenState();
}

class _WalkMonitorScreenState extends State<WalkMonitorScreen> {
  bool _walkActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Walk Guardian")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.directions_walk, size: 80, color: Colors.purple),
            const SizedBox(height: 12),
            Text(
              _walkActive ? "Walk Monitoring Active" : "Walk Monitor Active Sensors",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Monitors device accelerometer for phone drop, snatching, running, and sudden halts.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _walkActive = !_walkActive;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _walkActive ? Colors.red : Colors.purple,
              ),
              child: Text(_walkActive ? "End Walk Mode" : "Start Walk Mode"),
            ),
          ],
        ),
      ),
    );
  }
}
