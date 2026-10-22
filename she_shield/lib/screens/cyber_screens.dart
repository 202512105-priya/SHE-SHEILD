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
  final _urlController = TextEditingController(text: 'https://instagram.com/unknown_user_99');

  bool _screenshotAttached = false;
  bool _scanning = false;
  bool _scanCompleted = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(
      text: widget.initialDescription ?? 'blackmail with photoes',
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _uploadScreenshot() {
    setState(() {
      _screenshotAttached = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Screenshot uploaded successfully'),
          ],
        ),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _runAiScan() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the incident first.')),
      );
      return;
    }

    setState(() {
      _scanning = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _scanning = false;
      _scanCompleted = true;
    });
  }

  void _fileOfficialCase() {
    var db = Provider.of<DatabaseService>(context, listen: false);
    db.addCyberComplaint(_descController.text, _urlController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Official Cyber Case Filed & Transmitted to Command Dashboard!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ComplaintStatusScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Cyber Threat Assistant'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.pink.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.security, color: Colors.purple, size: 28),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Report Cyber Crime",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  Text(
                                    "AI-powered incident scan & automatic filing",
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Incident description field
                        const Text(
                          "Incident Description",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Describe the incident (e.g. blackmail with photoes)...",
                            prefixIcon: const Icon(Icons.description, color: Colors.purple),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Offender Profile Link field
                        const Text(
                          "Offender Profile Link / Social URL",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: "https://instagram.com/username or profile URL",
                            prefixIcon: const Icon(Icons.link, color: Colors.purple),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Screenshot upload button
                        OutlinedButton.icon(
                          onPressed: _uploadScreenshot,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            side: BorderSide(
                              color: _screenshotAttached ? Colors.green : Colors.purple,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(
                            _screenshotAttached ? Icons.check_circle : Icons.upload_file,
                            color: _screenshotAttached ? Colors.green : Colors.purple,
                          ),
                          label: Text(
                            _screenshotAttached
                                ? "Screenshot uploaded successfully"
                                : "Upload Screenshot Proof",
                            style: TextStyle(
                              color: _screenshotAttached ? Colors.green.shade800 : Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Perform AI Threat Scan button
                        ElevatedButton.icon(
                          onPressed: _scanning ? null : _runAiScan,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: _scanning
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.memory, color: Colors.white),
                          label: Text(
                            _scanning ? "Scanning Threat Vector..." : "Perform AI Threat Scan",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // AI Threat Scan Results Card
                  if (_scanCompleted) ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shield_outlined, color: Colors.redAccent, size: 26),
                                  SizedBox(width: 8),
                                  Text(
                                    "AI Threat Scan Results",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "HIGH RISK",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Metrics Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  "Threat Category",
                                  "BLACKMAIL",
                                  Icons.warning_amber_rounded,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricTile(
                                  "Safety Score",
                                  "15%",
                                  Icons.shield,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildMetricTile(
                                  "Confidence",
                                  "90%",
                                  Icons.verified,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            "Recommended Protocols:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                          ),
                          const SizedBox(height: 8),
                          _buildProtocolTile("1. Block & report offender's account immediately"),
                          _buildProtocolTile("2. Do NOT transfer funds or give into demand coercion"),
                          _buildProtocolTile("3. Preserve chat transcripts & raw media EXIF metadata"),
                          _buildProtocolTile("4. File official emergency case for legal takedown notice"),
                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: _fileOfficialCase,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.gavel),
                            label: const Text(
                              "File Official Case",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolTile(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.purple, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class ComplaintStatusScreen extends StatelessWidget {
  const ComplaintStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var db = Provider.of<DatabaseService>(context);
    var complaints = db.cyberComplaints;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Timeline & Status'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.pink.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in, color: Colors.purple, size: 28),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Official Cyber Case #1780512594344",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                              ),
                              Text("Category: BLACKMAIL", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          Chip(
                            label: const Text("ACTIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.purple,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Incident: blackmail with photoes", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text("Threat Score: 92%", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Case Timeline Progress Tracker Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Case Timeline Progress",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                      const SizedBox(height: 16),

                      _buildTimelineStep(
                        title: "AI Analysis Completed",
                        subtitle: "Threat category BLACKMAIL identified • Score 92%",
                        time: "10:15 AM",
                        isCompleted: true,
                        isFirst: true,
                      ),
                      _buildTimelineStep(
                        title: "Complaint Submitted",
                        subtitle: "Case payload logged into immutable database",
                        time: "10:16 AM",
                        isCompleted: true,
                      ),
                      _buildTimelineStep(
                        title: "Assigned to SHE SHIELD Cyber Cell",
                        subtitle: "Officer in charge review & evidence collection",
                        time: "10:20 AM",
                        isCompleted: true,
                        isActive: true,
                      ),
                      _buildTimelineStep(
                        title: "Platform Takedown Notice Issued",
                        subtitle: "Targeting offender URL for social link disabling",
                        time: "Pending",
                        isCompleted: false,
                      ),
                      _buildTimelineStep(
                        title: "Law Enforcement Action",
                        subtitle: "Official legal subpoena & ISP trace",
                        time: "Pending",
                        isCompleted: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (complaints.isNotEmpty) ...[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Filed Complaints Log",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: complaints.length,
                          itemBuilder: (context, index) {
                            var item = complaints[index];
                            return ListTile(
                              leading: const Icon(Icons.report_problem, color: Colors.orange),
                              title: Text(item['description'] ?? 'Cyber Complaint'),
                              subtitle: Text("ID: ${item['id']} • ${item['status']}"),
                              trailing: Text(item['threatScore'] ?? '90%', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
    bool isActive = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    Color iconColor = isCompleted
        ? (isActive ? Colors.purple : Colors.green)
        : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isCompleted ? iconColor.withValues(alpha: 0.15) : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 2),
              ),
              child: Icon(
                isCompleted ? (isActive ? Icons.sync : Icons.check) : Icons.hourglass_empty,
                size: 14,
                color: iconColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: isCompleted ? Colors.purple.shade200 : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isActive ? Colors.purple : (isCompleted ? Colors.black87 : Colors.grey),
                      ),
                    ),
                    Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
