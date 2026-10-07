import 'package:flutter/material.dart';

class SafetyMapScreen extends StatefulWidget {
  const SafetyMapScreen({super.key});
  @override
  State<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends State<SafetyMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Safety Radar & Risk Map"), backgroundColor: Colors.purple),
      body: const Center(child: Text("AI Threat Map & Radar Scanner")),
    );
  }
}
