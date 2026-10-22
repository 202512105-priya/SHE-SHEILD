import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() => _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  String _selectedWard = "Priya Sharma";

  void _triggerQuickAction(String action, String wardName) {
    String msg = "";
    if (action == "Call") {
      msg = "Initiating encrypted direct emergency call to $wardName...";
    } else if (action == "Navigate") {
      msg = "Launching GPS Turn-by-Turn Navigation to $wardName's live location...";
    } else if (action == "Police") {
      msg = "Dispatching SHE SHIELD Police SOS Relay to $wardName's current GPS pin!";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: action == "Police" ? Colors.red : Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Protection Portal'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.pink.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shield_moon, color: Colors.purple, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Real-Time Ward Monitoring",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                            Text(
                              "Active protection for 2 linked family members",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(radius: 4, backgroundColor: Colors.green),
                            SizedBox(width: 4),
                            Text("LIVE SYNC", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Linked User Cards Section
                const Text(
                  "Linked Protected Wards",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                ),
                const SizedBox(height: 12),

                // Card 1: Priya Sharma (95% Safety)
                _buildWardCard(
                  name: "Priya Sharma",
                  safetyScore: "95% Safety",
                  riskStatus: "SAFE",
                  riskColor: Colors.green,
                  locationText: "University Campus • Safe Zone",
                  batteryLevel: "88%",
                  deviceState: "Charging • Smartwatch Paired • GPS Active",
                  isSelected: _selectedWard == "Priya Sharma",
                  onSelect: () => setState(() => _selectedWard = "Priya Sharma"),
                ),
                const SizedBox(height: 14),

                // Card 2: Anjali Sharma (62% Medium Risk)
                _buildWardCard(
                  name: "Anjali Sharma",
                  safetyScore: "62% Medium Risk",
                  riskStatus: "MEDIUM RISK",
                  riskColor: Colors.orange,
                  locationText: "CG Road • Route Deviation 200m",
                  batteryLevel: "45%",
                  deviceState: "Walk Mode Active • Unsafe Area Nearby",
                  isSelected: _selectedWard == "Anjali Sharma",
                  onSelect: () => setState(() => _selectedWard = "Anjali Sharma"),
                ),
                const SizedBox(height: 20),

                // Live Location Map Simulation Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.map_outlined, color: Colors.purple),
                              const SizedBox(width: 8),
                              Text(
                                "Live Location Map: $_selectedWard",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.purple),
                              ),
                            ],
                          ),
                          Text(
                            "23.0225° N, 72.5714° E",
                            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.purple.shade900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Simulated Map Container Widget
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple.shade100, width: 1.5),
                        ),
                        child: Stack(
                          children: [
                            // Simulated grid / map graphic background
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.15,
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                                  itemCount: 24,
                                  itemBuilder: (context, index) => Container(
                                    decoration: BoxDecoration(border: Border.all(color: Colors.purple)),
                                  ),
                                ),
                              ),
                            ),
                            // Safe perimeter zone circle
                            Center(
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (_selectedWard == "Priya Sharma" ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: _selectedWard == "Priya Sharma" ? Colors.green : Colors.orange,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            // Ward Location Pin
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: Colors.purple.withValues(alpha: 0.2), blurRadius: 6),
                                      ],
                                    ),
                                    child: Text(
                                      "📍 $_selectedWard",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    Icons.location_on,
                                    size: 36,
                                    color: _selectedWard == "Priya Sharma" ? Colors.green : Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                            // Map Overlay Legend
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _selectedWard == "Priya Sharma"
                                      ? "GPS Accuracy: 3 meters • Safe Radius"
                                      : "GPS Accuracy: 5 meters • Route Offset +30m",
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Device State & Telemetry Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Device Telemetry: $_selectedWard",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.purple),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTelemetryItem(
                            label: "Battery Level",
                            value: _selectedWard == "Priya Sharma" ? "88%" : "45%",
                            icon: Icons.battery_charging_full,
                            color: _selectedWard == "Priya Sharma" ? Colors.green : Colors.orange,
                          ),
                          _buildTelemetryItem(
                            label: "Device State",
                            value: _selectedWard == "Priya Sharma" ? "Active" : "Walk Mode",
                            icon: Icons.smartphone,
                            color: Colors.purple,
                          ),
                          _buildTelemetryItem(
                            label: "Signal",
                            value: "5G • Strong",
                            icon: Icons.cell_tower,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Action Buttons Bar (Call / Navigate / Police)
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quick Emergency Actions",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.purple),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _triggerQuickAction("Call", _selectedWard),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text("Call", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _triggerQuickAction("Navigate", _selectedWard),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.navigation, size: 18),
                              label: const Text("Navigate", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _triggerQuickAction("Police", _selectedWard),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.local_police, size: 18),
                              label: const Text("Police", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWardCard({
    required String name,
    required String safetyScore,
    required String riskStatus,
    required Color riskColor,
    required String locationText,
    required String batteryLevel,
    required String deviceState,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: riskColor.withValues(alpha: 0.15),
                        child: Text(
                          name.substring(0, 1),
                          style: TextStyle(color: riskColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            locationText,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      safetyScore,
                      style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.battery_4_bar, color: riskColor, size: 18),
                      const SizedBox(width: 4),
                      Text("Battery: $batteryLevel", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Expanded(
                    child: Text(
                      deviceState,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}