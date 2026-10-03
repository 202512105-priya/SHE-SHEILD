import 'package:flutter/material.dart';

class TravelFlowScreen extends StatefulWidget {
  const TravelFlowScreen({super.key});

  @override
  State<TravelFlowScreen> createState() => _TravelFlowScreenState();
}

class _TravelFlowScreenState extends State<TravelFlowScreen> {
  bool _isMonitoring = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Travel Monitoring"), backgroundColor: Colors.indigo),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isMonitoring ? Icons.location_on : Icons.location_off, size: 80, color: Colors.indigo),
            const SizedBox(height: 16),
            Text(
              _isMonitoring ? "Monitoring Active Route" : "Start Safe Walk / Cab Route",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isMonitoring = !_isMonitoring;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: Text(_isMonitoring ? "Stop Monitoring" : "Start Route Tracking"),
            ),
          ],
        ),
      ),
    );
  }
}
