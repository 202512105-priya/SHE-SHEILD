import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
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
  bool _screenshotAttached = false;
  bool _loading = false;

  Map<String, dynamic>? _aiAnalysisResult;

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

  final List<String> _categories = [
    "harassment",
    "blackmail",
    "scam",
    "sextortion",
    "cyber stalking",
    "deepfake"
  ];

  String _detectCategoryFromDescription(String text) {
    String desc = text.toLowerCase();
    if (desc.contains("leak") || desc.contai
<truncated 6595 bytes>
ntType": "Cyber Crime",
      "casePriority": _aiAnalysisResult!['severityLevel'] == "critical" ? "critical" : "high",
      "caseSeverity": _aiAnalysisResult!['severityLevel'],
      "assignedStation": "SHE SHIELD Cyber Cell",
      "assignedOfficer": "",
      "evidenceCount": _screenshotAttached ? 1 : 0,
      "status": "open",
      "resolutionNotes": "",
      "createdAt": DateTime.now().toIso8601String()
    });

    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cyber Complaint filed and sent to SHE SHIELD Emergency Command Dashboard.")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Cyber Assistant"),
        backgroundColor: Colors.purple.shade50,
        foregroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.pink.shade50]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_aiAnalysisResult == null) ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
