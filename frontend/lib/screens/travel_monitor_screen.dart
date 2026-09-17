import 'package:flutter/material.dart';

class TravelMonitorScreen extends StatefulWidget {
  const TravelMonitorScreen({super.key});
  @override
  State<TravelMonitorScreen> createState() => _TravelMonitorScreenState();
}

class _TravelMonitorScreenState extends State<TravelMonitorScreen> {
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController(text: "15");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Transit Monitor"), backgroundColor: Colors.purple.shade50),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _destinationController, decoration: const InputDecoration(labelText: "Destination")),
            TextField(controller: _durationController, decoration: const InputDecoration(labelText: "Estimated Duration (mins)")),
          ],
        ),
      ),
    );
  }
}
