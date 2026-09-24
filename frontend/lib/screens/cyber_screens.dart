import 'package:flutter/material.dart';

class CyberReportScreen extends StatefulWidget {
  const CyberReportScreen({super.key});
  @override
  State<CyberReportScreen> createState() => _CyberReportScreenState();
}

class _CyberReportScreenState extends State<CyberReportScreen> {
  String _selectedCategory = "Harassment";
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Cyber Assistant"), backgroundColor: Colors.purple.shade50),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedCategory,
              items: ["Harassment", "Stalking", "Financial Fraud", "Defamation"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: "Incident Description"), maxLines: 4),
          ],
        ),
      ),
    );
  }
}
