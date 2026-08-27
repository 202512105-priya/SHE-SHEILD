import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

// Helper Glassmorphism Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(24.0)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: Colors.purple.shade100.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade100.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

// User Authentication Scaffold Layout
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SHE SHIELD Login"), backgroundColor: Colors.purple),
      body: const Center(child: Text("Authentication Forms")),
    );
  }
}
