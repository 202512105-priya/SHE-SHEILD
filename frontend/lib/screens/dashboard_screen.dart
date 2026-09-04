import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Widget _buildQuickCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SHE SHIELD Hub"), backgroundColor: Colors.purple),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickCard("SOS Emergency Center", Icons.emergency, Colors.red),
          _buildQuickCard("Safe Travel Monitor", Icons.directions_car, Colors.blue),
          _buildQuickCard("Cyber Incident Reporting", Icons.security, Colors.indigo),
        ],
      ),
    );
  }
}
