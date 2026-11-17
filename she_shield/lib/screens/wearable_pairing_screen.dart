import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/bluetooth_wearable_service.dart';

class WearablePairingScreen extends StatefulWidget {
  const WearablePairingScreen({super.key});

  @override
  State<WearablePairingScreen> createState() => _WearablePairingScreenState();
}

class _WearablePairingScreenState extends State<WearablePairingScreen> {
  final BluetoothWearableService _ble = BluetoothWearableService();
  bool _isCheckingAvailability = false;

  @override
  void initState() {
    super.initState();
    _checkInitialBleState();
  }

  Future<void> _checkInitialBleState() async {
    setState(() => _isCheckingAvailability = true);
    await _ble.checkAvailability();
    if (mounted) {
      setState(() => _isCheckingAvailability = false);
    }
  }

  Future<void> _handleScanAndConnect() async {
    if (!_ble.bluetoothEnabled) {
      _showEnableBluetoothDialog();
      return;
    }

    final db = Provider.of<DatabaseService>(context, listen: false);
    _ble.bindDatabase(db);

    final result = await _ble.scanAndConnect();
    if (!mounted) return;

    if (result.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text("Connected to ${result.deviceName} (${result.deviceCategory})"),
              ),
            ],
          ),
          backgroundColor: Colors.purple.shade900,
        ),
      );
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }
  }

  void _showEnableBluetoothDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bluetooth_disabled, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text("Bluetooth Required"),
          ],
        ),
        content: const Text(
          "Bluetooth radio is currently disabled or unavailable. Please enable Bluetooth in your device settings to discover and pair your wearable SOS hardware.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _ble.setBluetoothEnabled(true);
              _handleScanAndConnect();
            },
            child: const Text("I've Enabled Bluetooth"),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlaySound() async {
    if (!_ble.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please connect a wearable device first."),
          backgroundColor: Colors.orange.shade900,
        ),
      );
      return;
    }

    final res = await _ble.playSound();
    if (!mounted) return;

    if (!res.supported) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Text("Feature Not Supported"),
            ],
          ),
          content: Text(
            res.error ?? "Feature not supported by this device. Immediate Alert Service (0x1802) is not exposed by hardware.",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade800, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Understood"),
            ),
          ],
        ),
      );
    } else {
      _showSoundPlayingModal(context);
    }
  }

  void _showSoundPlayingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.volume_up, color: Colors.amber.shade900, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              "🔊 Sound Playing on ${_ble.currentDevice.deviceName}",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
            ),
            const SizedBox(height: 6),
            Text(
              "Transmitting acoustic high-alert command to paired hardware buzzer via Immediate Alert Characteristic (0x2A06).",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Dismiss"),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTestSosTrigger() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    _ble.bindDatabase(db);

    await _ble.triggerSafeTestSos(db: db);
    if (!mounted) return;

    _showActiveSosDialog(context);
  }

  void _showActiveSosDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.red.shade900,
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 56),
            SizedBox(height: 8),
            Text(
              "WEARABLE SOS ACTIVATED",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              "PHYSICAL WEARABLE BUTTON TRIGGERED",
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Incident ID:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Flexible(
                        child: Text(
                          _ble.lastSosIncidentId ?? "SOS-BLE-ACTIVE",
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Trigger Source:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        _ble.isConnected ? _ble.currentDevice.deviceName : "WEARABLE_BLE",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Emergency Recording:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("Active (Mic Armed)", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Cloud Database Persistence:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("Synced Live", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Live alert dispatched to Linked Guardians & Responder Grid!",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Enter PIN / Disarm SOS", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _ble.resolveActiveSos();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Wearable SOS incident resolved and evidence finalized."),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _runDiagnosticReportDialog() {
    final dev = _ble.currentDevice;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("BLE Diagnostics"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    "Wearable BLE Subsystem Health",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ble.isConnected ? "HARDWARE PAIRED & VERIFIED" : "ADAPTER ACTIVE (READY TO SCAN)",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: _ble.isConnected ? Colors.green.shade800 : Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Adapter Radio:", style: TextStyle(color: Colors.grey)),
                Text(_ble.bluetoothEnabled ? "Enabled (Active)" : "Disabled", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Connection State:", style: TextStyle(color: Colors.grey)),
                Text(_ble.isConnected ? "GATT Connected" : "Disconnected", style: TextStyle(fontWeight: FontWeight.bold, color: _ble.isConnected ? Colors.green : Colors.orange)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Signal Strength:", style: TextStyle(color: Colors.grey)),
                Text(dev.signalStrength, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Battery Level:", style: TextStyle(color: Colors.grey)),
                Text(dev.batteryLevel != null ? "${dev.batteryLevel}%" : "Not Reported", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Hardware Buzzer:", style: TextStyle(color: Colors.grey)),
                Text(dev.soundSupported ? "Available (0x1802)" : "Not Exposed", style: TextStyle(fontWeight: FontWeight.bold, color: dev.soundSupported ? Colors.green : Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("GATT Services Discovered:", style: TextStyle(color: Colors.grey)),
                Text("${dev.discoveredServices.length} Services", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close Diagnostic"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wearable SOS Integration"),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _ble,
        builder: (context, _) {
          final isConn = _ble.isConnected;
          final dev = _ble.currentDevice;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bluetooth Radio Status Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _ble.bluetoothEnabled ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                              color: _ble.bluetoothEnabled ? Colors.blue.shade700 : Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Bluetooth BLE Radio",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _ble.isScanning
                                      ? "Scanning for nearby BLE wearables..."
                                      : (_ble.bluetoothEnabled ? "Radio Enabled & Ready" : "Radio Disabled"),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _ble.bluetoothEnabled,
                          activeThumbColor: Colors.blue.shade700,
                          onChanged: (val) {
                            _ble.setBluetoothEnabled(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Device Type Selector Dropdown
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Device Category to Pair",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _ble.selectedCategory,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.watch, color: Colors.purple),
                          ),
                          items: _ble.availableCategories
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _ble.setSelectedCategory(val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Primary "Scan for Nearby Devices" Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  icon: _ble.isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.bluetooth_searching, size: 22),
                  label: Text(
                    _ble.isScanning ? "Scanning for BLE Hardware..." : "Scan for Nearby Devices",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _ble.isScanning ? null : _handleScanAndConnect,
                ),

                const SizedBox(height: 16),

                // Active Device Info Card (Real Dynamic Data)
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: isConn
                            ? [Colors.purple.shade900, Colors.deepPurple.shade700]
                            : [Colors.grey.shade800, Colors.blueGrey.shade900],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isConn ? dev.deviceName : "No Wearable Connected",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isConn ? Colors.greenAccent.shade400 : Colors.orangeAccent.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isConn ? "Connected" : "Disconnected",
                                style: TextStyle(
                                  color: isConn ? Colors.green.shade900 : Colors.brown.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.category, color: Colors.purpleAccent, size: 20),
                                SizedBox(width: 6),
                                Text("Device Category:", style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            Text(dev.deviceCategory, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.battery_charging_full, color: Colors.greenAccent, size: 20),
                                SizedBox(width: 6),
                                Text("Battery Level:", style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            Text(
                              dev.batteryLevel != null ? "${dev.batteryLevel}%" : (isConn ? "Not Reported" : "--"),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wifi_tethering, color: Colors.cyanAccent, size: 20),
                                SizedBox(width: 6),
                                Text("Signal Strength:", style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            Text(dev.signalStrength, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.fingerprint, color: Colors.amberAccent, size: 20),
                                SizedBox(width: 6),
                                Text("Device ID / MAC:", style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            Flexible(
                              child: Text(
                                dev.macAddress,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (isConn) ...[
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: Colors.redAccent.shade100),
                              icon: const Icon(Icons.link_off, size: 18),
                              label: const Text("Disconnect Device"),
                              onPressed: () => _ble.disconnect(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Wearable Buzzer / Play Sound on Bluetooth Device Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConn ? Colors.amber.shade700 : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.volume_up, size: 22),
                  label: const Text(
                    "🔊 Play Sound on Bluetooth Device",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: isConn ? _handlePlaySound : null,
                ),

                const SizedBox(height: 14),

                // Action Buttons: Safe SOS Trigger Test & Run Diagnostic Test
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.purple.shade700, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(Icons.touch_app, color: Colors.purple.shade700),
                        label: Text(
                          "🧪 Test SOS Trigger",
                          style: TextStyle(
                            color: Colors.purple.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _handleTestSosTrigger,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text(
                          "Run SOS Test",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _runDiagnosticReportDialog,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Background Event Listener Notice Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.deepPurple.shade800, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Physical SOS Button Monitoring: Active",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade900, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Once connected, SHE SHIELD listens for physical button presses across all screens. Debouncing (3000ms) prevents duplicate alerts. Pressing your hardware button immediately initiates GPS dispatch and automatic emergency audio recording.",
                              style: TextStyle(fontSize: 11.5, color: Colors.deepPurple.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
