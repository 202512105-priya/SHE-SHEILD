import 'package:flutter/material.dart';

class CyberReportScreen extends StatefulWidget {
  const CyberReportScreen({super.key});
  @override
  State<CyberReportScreen> createState() => _CyberReportScreenState();
}

class _CyberReportScreenState extends State<CyberReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Cyber Assistant"), backgroundColor: Colors.purple.shade50),
      body: const Center(child: Text("Cybercrime Reporting Form Layout")),
    );
  }
}
