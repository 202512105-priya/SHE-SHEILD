import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class ResponderDashboardScreen extends StatefulWidget {
  const ResponderDashboardScreen({super.key});

  @override
  State<ResponderDashboardScreen> createState() => _ResponderDashboardScreenState();
}

class _ResponderDashboardScreenState extends State<ResponderDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local state for dynamically managed status of cases
  final Map<String, String> _caseStatuses = {};
  final Map<String, String> _assignedResponders = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    // Mock list expansion to reach [5] SOS Cases and [2] Cyber Cases if db has fewer
    final List<Map<String, dynamic>> sosCasesList = List.from(db.sosCases);
    if (sosCasesList.length < 5) {
      sosCasesList.addAll([
        {
          'id': 'case-1780599102',
          'userName': 'Ananya Verma',
          'userEmail': 'ananya.v@gmail.com',
          'userPhone': '+91 98234 56789',
          'age': 22,
          'bloodGroup': 'B+',
          'priority': 'CRITICAL',
          'status': 'open',
          'gps': '23.0312, 72.5801',
          'timestamp': '2026-05-04T01:05:12',
          'deviceType': 'Wearable BLE Pendant Trigger',
          'evidenceCount': 3,
        },
        {
          'id': 'case-1780599304',
          'userName': 'Sneha Patel',
          'userEmail': 'sneha.p@gmail.com',
          'userPhone': '+91 97123 45678',
          'age': 26,
          'bloodGroup': 'A+',
          'priority': 'HIGH',
          'status': 'investigating',
          'gps': '23.0289, 72.5694',
          'timestamp': '2026-05-04T00:48:30',
          'deviceType': 'Cab Deviation Sensor',
          'evidenceCount': 2,
        },
        {
          'id': 'case-1780599501',
          'userName': 'Ria Mehta',
          'userEmail': 'ria.m@gmail.com',
          'userPhone': '+91 99099 12345',
          'age': 21,
          'bloodGroup': 'AB+',
          'priority': 'CRITICAL',
          'status': 'assigned',
          'gps': '23.0198, 72.5750',
          'timestamp': '2026-05-04T00:30:15',
          'deviceType': 'Secret Voice Trigger (Box Box)',
          'evidenceCount': 4,
        },
      ]);
    }

    final List<Map<String, dynamic>> cyberCasesList = List.from(db.cyberComplaints);
    if (cyberCasesList.length < 2) {
      cyberCasesList.add({
        'id': 'case-1780588220',
        'category': 'CYBER STALKING',
        'description': 'Persistent unauthorized tracking and online threat messages across social media.',
        'threatScore': '88%',
        'status': 'UNDER REVIEW',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'userName': 'Kavita Roy',
        'userPhone': '+91 98980 11223',
        'evidenceCount': 5,
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Responder Command Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent),
            ),
            child: const Row(
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 10),
                SizedBox(width: 6),
                Text(
                  'DISPATCH ACTIVE',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'SOS Emergency Cases [${sosCasesList.length}]'),
            Tab(text: 'Digital Crime Cases [${cyberCasesList.length}]'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSosCasesTab(sosCasesList),
          _buildCyberCasesTab(cyberCasesList),
        ],
      ),
    );
  }

  Widget _buildSosCasesTab(List<Map<String, dynamic>> cases) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final item = cases[index];
        final String caseId = item['id'] ?? 'case-$index';
        final String currentStatus = _caseStatuses[caseId] ?? (item['status'] ?? 'open').toString().toUpperCase();
        final String? assignedTo = _assignedResponders[caseId];

        final bool isCritical = (item['priority'] ?? 'CRITICAL') == 'CRITICAL';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isCritical ? Colors.red.shade300 : Colors.purple.shade200,
              width: 1.5,
            ),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCritical ? Colors.red.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PRIORITY: ${item['priority'] ?? 'CRITICAL'}',
                        style: TextStyle(
                          color: isCritical ? Colors.red.shade900 : Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentStatus == 'RESOLVED' || currentStatus == 'CLOSED' ? Colors.green.shade100 : Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'STATUS: $currentStatus',
                        style: TextStyle(
                          color: currentStatus == 'RESOLVED' || currentStatus == 'CLOSED' ? Colors.green.shade900 : Colors.purple.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Icon(Icons.person, color: Colors.purple.shade800),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['userName'] ?? 'Unknown User',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Phone: ${item['userPhone'] ?? 'N/A'} | ID: $caseId',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'GPS: ${item['gps'] ?? '23.023403, 72.572400'} (1.2 km away)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.devices, color: Colors.purple, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Trigger: ${item['deviceType'] ?? 'Smart Watch / BLE Beacon Relay'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
                if (assignedTo != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.badge, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Assigned Unit: $assignedTo',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                        ),
                        onPressed: () {
                          setState(() {
                            _assignedResponders[caseId] = 'Officer Shield Unit #409';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Case $caseId assigned to Officer Shield Unit #409')),
                          );
                        },
                        icon: const Icon(Icons.assignment_ind, size: 16),
                        label: const Text('Assign To Me'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A148C),
                        ),
                        onPressed: () => _openCaseDetailsBottomSheet(item, caseId),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Case Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCyberCasesTab(List<Map<String, dynamic>> cases) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final item = cases[index];
        final String caseId = item['id'] ?? 'cyber-$index';
        final String currentStatus = _caseStatuses[caseId] ?? (item['status'] ?? 'SUBMITTED');

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      backgroundColor: Colors.indigo.shade50,
                      label: Text(
                        item['category'] ?? 'DIGITAL CRIME',
                        style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Threat Score: ${item['threatScore'] ?? '92%'}',
                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Case ID: $caseId',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  item['description'] ?? 'No details specified',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: $currentStatus',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      onPressed: () => _openCaseDetailsBottomSheet(item, caseId),
                      icon: const Icon(Icons.security, size: 16),
                      label: const Text('Review Cyber Dossier'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCaseDetailsBottomSheet(Map<String, dynamic> item, String caseId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String activeStatus = _caseStatuses[caseId] ?? (item['status'] ?? 'open').toString().toUpperCase();

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A148C),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CASE DOSSIER: $caseId',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const Text(
                              'Live Response Sync & Evidence Chain',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Body Scroll
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info Section
                          _buildSectionHeader('User Information', Icons.person_pin),
                          Card(
                            elevation: 1,
                            color: Colors.purple.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  _buildInfoRow('Victim Name:', item['userName'] ?? 'tisha'),
                                  _buildInfoRow('Email Address:', item['userEmail'] ?? 'tisha@gmail.com'),
                                  _buildInfoRow('Phone Number:', item['userPhone'] ?? '12435578494630'),
                                  _buildInfoRow('Age & Blood Group:', '${item['age'] ?? 24} Yrs | Blood: ${item['bloodGroup'] ?? 'O+'}'),
                                  _buildInfoRow('Emergency Priority:', item['priority'] ?? 'CRITICAL'),
                                  _buildInfoRow('Current Case Status:', activeStatus),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Location Info & Route History Trail
                          _buildSectionHeader('Location Info & Live GPS Route History Trail', Icons.map),
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.shade300),
                            ),
                            child: Stack(
                              children: [
                                CustomPaint(
                                  size: const Size(double.infinity, 150),
                                  painter: RouteTrailPainter(),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'GPS: ${item['gps'] ?? "23.023403, 72.572400"}',
                                      style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.timeline, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('4 Breadcrumbs Recorded', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Incident Info
                          _buildSectionHeader('Incident Details', Icons.info_outline),
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  _buildInfoRow('Timestamp:', item['timestamp'] ?? DateTime.now().toIso8601String()),
                                  _buildInfoRow('Device Source:', item['deviceType'] ?? 'Smart Watch / BLE Beacon Relay'),
                                  _buildInfoRow('Signal Encryption:', 'AES-256 Validated'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Case Status Synchronization Buttons
                          _buildSectionHeader('Case Status Synchronization', Icons.sync),
                          const Text(
                            'Tap a status button to synchronize incident lifecycle:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              'Received',
                              'Review',
                              'Investigate',
                              'Verify Proof',
                              'Assign',
                              'In Progress',
                              'Resolve',
                            ].map((status) {
                              bool isSelected = activeStatus.toUpperCase() == status.toUpperCase();
                              return ChoiceChip(
                                label: Text(status),
                                selected: isSelected,
                                selectedColor: const Color(0xFF4A148C),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.purple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setModalState(() {
                                      activeStatus = status.toUpperCase();
                                    });
                                    setState(() {
                                      _caseStatuses[caseId] = status.toUpperCase();
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Case $caseId status updated to $status')),
                                    );
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Evidence List
                          _buildSectionHeader('Cryptographic Evidence List', Icons.folder_zip),
                          _buildEvidenceItem('SOS_Audio_Stream_001.aac', 'Audio Recording (00:45)', 'SHA-256: 643199974ac7...'),
                          _buildEvidenceItem('Front_Camera_Burst_01.jpg', 'Camera Snapshots', 'SHA-256: 8f921ab39e21...'),
                          _buildEvidenceItem('GPS_Telemetry_Trail.json', 'Breadcrumb Logs', 'SHA-256: e3b0c44298fc...'),
                          const SizedBox(height: 20),

                          // Buttons: Assign Case & Print Report
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                    side: const BorderSide(color: Colors.purple),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _assignedResponders[caseId] = 'Officer Shield Unit #409';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Assigned $caseId to Officer Shield Unit #409')),
                                    );
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Assign Case to Me'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Generating official print report PDF for $caseId...')),
                                    );
                                  },
                                  icon: const Icon(Icons.print),
                                  label: const Text('Print Report'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Secure Case Closure Protocol
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lock, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Secure Case Closure Protocol',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Requires Officer Badge Key verification (Enter "SHIELD911"):',
                                  style: TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                                const SizedBox(height: 10),
                                _ClosureFormWidget(
                                  onSuccess: () {
                                    setState(() {
                                      _caseStatuses[caseId] = 'CLOSED';
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Case $caseId successfully CLOSED with Officer Security Key.')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4A148C)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4A148C)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceItem(String title, String subtitle, String hash) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file, color: Colors.purple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('$subtitle\n$hash', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.verified, color: Colors.green, size: 20),
      ),
    );
  }
}

class _ClosureFormWidget extends StatefulWidget {
  final VoidCallback onSuccess;
  const _ClosureFormWidget({required this.onSuccess});

  @override
  State<_ClosureFormWidget> createState() => _ClosureFormWidgetState();
}

class _ClosureFormWidgetState extends State<_ClosureFormWidget> {
  final _keyController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _keyController,
            decoration: InputDecoration(
              hintText: 'Officer Badge Key (e.g. SHIELD911)',
              errorText: _error,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () {
            if (_keyController.text.trim() == 'SHIELD911') {
              widget.onSuccess();
            } else {
              setState(() {
                _error = 'Invalid Badge Key!';
              });
            }
          },
          child: const Text('Close Case'),
        ),
      ],
    );
  }
}

class RouteTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.amber
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.2,
      size.width * 0.7,
      size.height * 0.6,
    );
    path.lineTo(size.width * 0.9, size.height * 0.3);

    canvas.drawPath(path, paintLine);

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 5, paintDot);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 5, paintDot);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.3), 7, Paint()..color = Colors.greenAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}