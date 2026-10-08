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
}
