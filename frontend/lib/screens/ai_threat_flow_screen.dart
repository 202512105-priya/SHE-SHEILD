import 'package:flutter/material.dart';

class AIThreatFlowScreen extends StatelessWidget {
  const AIThreatFlowScreen({super.key});

  Widget buildActionGuidance() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.shield_outlined, color: Colors.purple),
        title: Text("Recommended Safety Action"),
        subtitle: Text("Reroute through main arterial road. Alerting trusted guardians."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Threat Assessment")),
      body: Padding(padding: const EdgeInsets.all(16.0), child: buildActionGuidance()),
    );
  }
}
