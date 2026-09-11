import 'package:flutter/material.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _isHolding = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency SOS Control Center"), backgroundColor: Colors.red),
      body: Center(
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isHolding = true),
          onTapUp: (_) => setState(() => _isHolding = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(_isHolding ? 40 : 32),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Icon(Icons.emergency, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}
