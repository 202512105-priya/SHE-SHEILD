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
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

// Welcome Screen with Role Selector
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
             
<truncated 30767 bytes>
                     TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: "Official Email Address"),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v!.isEmpty ? "Enter official email" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mobileController,
                          decoration: const InputDecoration(labelText: "Official Phone Number"),
                          keyboardType: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? "Enter official number" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: "Dashboard Password"),
                          obscureText: true,
                          validator: (v) => v!.isEmpty ? "Enter password" : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Police Station Details",
                          style: TextStyle(
                            fontSize: 16,
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
