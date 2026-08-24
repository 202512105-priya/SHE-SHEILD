import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart';

class CyberReportScreen extends StatefulWidget {
  final String? initialDescription;
  const CyberReportScreen({super.key, this.initialDescription});

  @override
  State<CyberReportScreen> createState() => _CyberReportScreenState();
}

class _CyberReportScreenState extends State<CyberReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descController;
  final _urlController = TextEditingController();
  
  String _selectedCategory = "harassment";

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.initialDescription ?? "");
  }

  @override
  void dispose() {
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Cyber Assistant"), backgroundColor: Colors.purple.shade50),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Describe cyber threat details"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
