import 'package:flutter/material.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Safety Monitoring'),
      ),
      body: const Center(
        child: Text('Live Safety Monitoring Panel'),
      ),
    );
  }
}
