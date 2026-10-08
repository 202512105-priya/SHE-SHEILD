import 'package:flutter/material.dart';

class SafetyMapScreen extends StatefulWidget {
  const SafetyMapScreen({super.key});
  @override
  State<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends State<SafetyMapScreen> {
  Widget _buildRiskCard(String zoneName, int riskScore, Color levelColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: levelColor),
        title: Text(zoneName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Risk Index: $riskScore / 100"),
        trailing: Chip(label: const Text("High Vigilance"), backgroundColor: levelColor.withOpacity(0.2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Safety Radar & Risk Map"), backgroundColor: Colors.purple),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRiskCard("Zone Alpha (Industrial Belt)", 78, Colors.red),
          _buildRiskCard("Zone Gamma (Transit Hub)", 45, Colors.orange),
        ],
      ),
    );
  }
}
