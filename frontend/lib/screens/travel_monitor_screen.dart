import 'package:flutter/material.dart';

class TravelMonitorScreen extends StatefulWidget {
  const TravelMonitorScreen({super.key});
  @override
  State<TravelMonitorScreen> createState() => _TravelMonitorScreenState();
}

class _TravelMonitorScreenState extends State<TravelMonitorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Transit Monitor"), backgroundColor: Colors.purple.shade50),
      body: const Center(child: Text("Travel Monitoring Screen Scaffold")),
    );
  }
}
