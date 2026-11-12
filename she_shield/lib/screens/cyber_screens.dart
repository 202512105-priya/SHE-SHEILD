import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/evidence_preview_dialog.dart';
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
  final List<String> _selectedVaultEvidence = [];

  IconData _getAssetIcon(String name, String? type) {
    final lower = name.toLowerCase();
    final t = (type ?? '').toUpperCase();
    if (t == 'AUDIO' || lower.contains('.mp3') || lower.contains('.m4a') || lower.contains('.aac') || lower.contains('audio')) {
      return Icons.audiotrack;
    } else if (t == 'IMAGE' || lower.contains('.png') || lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('photo') || lower.contains('screenshot')) {
      return Icons.image;
    } else if (t == 'VIDEO' || lower.contains('.mp4') || lower.contains('video') || lower.contains('cctv')) {
      return Icons.videocam;
    } else if (t == 'TELEMETRY' || lower.contains('.json') || lower.contains('telemetry') || lower.contains('gps')) {
      return Icons.data_object;
    }
    return Icons.insert_drive_file;
  }

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

  void _showVaultEvidencePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final db = Provider.of<DatabaseService>(context, listen: false);
            final vaultAssets = db.vaultAssets;

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_user, color: Colors.purple, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Attach Evidence from Vault",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                              ),
                              Text(
                                "Preview files and choose proofs to attach to case",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: vaultAssets.isEmpty
                        ? const Center(
                            child: Text(
                              "No evidence assets in Vault yet.\nUpload files to Vault first.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vaultAssets.length,
                            itemBuilder: (context, index) {
                              final asset = vaultAssets[index];
                              final assetName = asset['name'] ?? 'Evidence_File.bin';
                              final isSelected = _selectedVaultEvidence.contains(assetName);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isSelected ? Colors.purple : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                elevation: isSelected ? 2 : 0,
                                color: isSelected ? Colors.purple.shade50.withValues(alpha: 0.3) : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        activeColor: Colors.purple,
                                        onChanged: (bool? val) {
                                          setModalState(() {
                                            if (val == true) {
                                              if (!_selectedVaultEvidence.contains(assetName)) {
                                                _selectedVaultEvidence.add(assetName);
                                              }
                                            } else {
                                              _selectedVaultEvidence.remove(assetName);
                                            }
                                          });
                                          setState(() {});
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          _getAssetIcon(assetName, asset['fileType']?.toString()),
                                          color: Colors.purple,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              assetName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "${asset['fileType'] ?? 'FILE'} • ${asset['sizeMb'] ?? '2.4 MB'} • Tamper: ${asset['tamperCheck'] ?? 'PASS'}",
                                              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                            ),
                                            Text(
                                              asset['hash'] ?? 'SHA256: 64319...',
                                              style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          EvidencePreviewDialog.show(
                                            context,
                                            fileName: assetName,
                                            fileType: asset['fileType'],
                                            size: asset['sizeMb'],
                                            hash: asset['hash'],
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.purple),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        icon: const Icon(Icons.visibility, size: 14, color: Colors.purple),
                                        label: const Text("Preview", style: TextStyle(fontSize: 11, color: Colors.purple)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        "Attach Selected Evidence (${_selectedVaultEvidence.length})",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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

  void _fileOfficialCase() {
    var db = Provider.of<DatabaseService>(context, listen: false);
    final List<String> allEvidence = [];
    if (_screenshotAttached) {
      allEvidence.add('Extortion_Blackmail_DM_Proof.png');
    }
    allEvidence.addAll(_selectedVaultEvidence);
    if (allEvidence.isEmpty) {
      allEvidence.add('CERT_In_Forensic_Report.pdf');
    }

    db.addCyberComplaint(
      _descController.text,
      _urlController.text,
      category: 'BLACKMAIL & EXTORTION',
      threatScore: '94%',
      attachedEvidence: allEvidence,
    );

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
    final db = Provider.of<DatabaseService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Cyber Crime'),
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
                        if (_screenshotAttached) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => EvidencePreviewDialog.show(
                              context,
                              fileName: 'Extortion_Blackmail_DM_Proof.png',
                              fileType: 'IMAGE',
                              hash: 'SHA256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.image, color: Colors.purple, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Extortion_Blackmail_DM_Proof.png',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.visibility, color: Colors.purple, size: 14),
                                      SizedBox(width: 4),
                                      Text('Preview File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Vault Evidence Attachment Section
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.lock_clock, color: Colors.purple, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "Attach Evidence from Vault",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${db.vaultAssets.length} In Vault",
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Attach immutable, SHA-256 cryptographically verified proofs stored in your Vault.",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => _showVaultEvidencePickerModal(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42),
                                  side: const BorderSide(color: Colors.purple, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.add_link, color: Colors.purple),
                                label: Text(
                                  _selectedVaultEvidence.isEmpty
                                      ? "Select Evidence from Vault"
                                      : "Edit Vault Evidence (${_selectedVaultEvidence.length} Selected)",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                                ),
                              ),
                              if (_selectedVaultEvidence.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  "Attached Vault Proofs:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple),
                                ),
                                const SizedBox(height: 6),
                                ..._selectedVaultEvidence.map((assetName) {
                                  final matchingAsset = db.vaultAssets.firstWhere(
                                    (a) => a['name'] == assetName,
                                    orElse: () => {'name': assetName, 'fileType': 'DOCUMENT', 'sizeMb': '2.0 MB'},
                                  );
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.purple.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(_getAssetIcon(matchingAsset['name']?.toString() ?? '', matchingAsset['fileType']?.toString()), color: Colors.purple, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                matchingAsset['name'] ?? assetName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "${matchingAsset['fileType'] ?? 'FILE'} • ${matchingAsset['sizeMb'] ?? '2.0 MB'}",
                                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            EvidencePreviewDialog.show(
                                              context,
                                              fileName: matchingAsset['name'] ?? assetName,
                                              fileType: matchingAsset['fileType'],
                                              size: matchingAsset['sizeMb'],
                                              hash: matchingAsset['hash'],
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                          ),
                                          icon: const Icon(Icons.visibility, size: 14, color: Colors.purple),
                                          label: const Text("Preview", style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            setState(() {
                                              _selectedVaultEvidence.remove(assetName);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Direct File Official Cyber Complaint Button
                        ElevatedButton.icon(
                          onPressed: _fileOfficialCase,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: Colors.purple.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                          ),
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
                          label: const Text(
                            "File Official Cyber Complaint",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData getEvidenceAssetIcon(String name, String? type) {
  final lower = name.toLowerCase();
  final t = (type ?? '').toUpperCase();
  if (t == 'AUDIO' || lower.contains('.mp3') || lower.contains('.m4a') || lower.contains('.aac') || lower.contains('audio') || lower.contains('recording')) {
    return Icons.audiotrack;
  } else if (t == 'IMAGE' || lower.contains('.png') || lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('photo') || lower.contains('screenshot') || lower.contains('dm')) {
    return Icons.image;
  } else if (t == 'VIDEO' || lower.contains('.mp4') || lower.contains('video') || lower.contains('cctv') || lower.contains('dashcam')) {
    return Icons.videocam;
  } else if (t == 'TELEMETRY' || lower.contains('.json') || lower.contains('telemetry') || lower.contains('gps')) {
    return Icons.data_object;
  }
  return Icons.description;
}

class ComplaintStatusScreen extends StatefulWidget {
  final String? initialCaseId;

  const ComplaintStatusScreen({super.key, this.initialCaseId});

  @override
  State<ComplaintStatusScreen> createState() => _ComplaintStatusScreenState();
}

class _ComplaintStatusScreenState extends State<ComplaintStatusScreen> {
  String? _selectedCaseId;

  static const List<String> _stages = [
    'SUBMITTED',
    'UNDER REVIEW',
    'ASSIGNED',
    'INVESTIGATING',
    'VERIFIED PROOF',
    'RESOLVED',
  ];

  int _getStageRank(String status) {
    final s = status.toUpperCase().trim();
    for (int i = 0; i < _stages.length; i++) {
      if (s == _stages[i] || s.replaceAll(' ', '_') == _stages[i].replaceAll(' ', '_')) {
        return i;
      }
    }
    if (s.contains('RESOLV') || s.contains('CLOSE')) return 5;
    if (s.contains('VERIF') || s.contains('PROOF')) return 4;
    if (s.contains('INVESTIGAT') || s.contains('PROGRESS')) return 3;
    if (s.contains('ASSIGN')) return 2;
    if (s.contains('REVIEW')) return 1;
    return 0;
  }

  void _showAttachMoreVaultEvidenceModal(BuildContext context, Map<String, dynamic> activeCase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final db = Provider.of<DatabaseService>(context, listen: false);
        final vaultAssets = db.vaultAssets;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock, color: Colors.purple, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Attach Vault Proof to Case",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                              ),
                              Text("Select evidence from Vault to link to this active complaint", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: vaultAssets.isEmpty
                        ? const Center(child: Text("No assets in Vault."))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vaultAssets.length,
                            itemBuilder: (context, index) {
                              final asset = vaultAssets[index];
                              final assetName = asset['name'] ?? 'Evidence_File.bin';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(getEvidenceAssetIcon(assetName, asset['fileType']?.toString()), color: Colors.purple, size: 20),
                                  ),
                                  title: Text(assetName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text("${asset['fileType'] ?? 'FILE'} • ${asset['sizeMb'] ?? '2.4 MB'} • Tamper: PASS", style: const TextStyle(fontSize: 11)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: Colors.purple, size: 18),
                                        onPressed: () {
                                          EvidencePreviewDialog.show(
                                            context,
                                            fileName: assetName,
                                            fileType: asset['fileType'],
                                            size: asset['sizeMb'],
                                            hash: asset['hash'],
                                          );
                                        },
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          final existingStr = activeCase['attachedEvidence']?.toString() ?? '';
                                          final updatedStr = existingStr.isNotEmpty ? '$existingStr; $assetName' : assetName;
                                          setState(() {
                                            activeCase['attachedEvidence'] = updatedStr;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Linked $assetName to complaint ${activeCase['id']}!"),
                                              backgroundColor: Colors.purple,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text("Attach", style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final complaints = db.cyberComplaints;

    if (complaints.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Tracking')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 64, color: Colors.purple),
              const SizedBox(height: 16),
              const Text("No cyber complaints filed yet.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CyberReportScreen()));
                },
                icon: const Icon(Icons.add),
                label: const Text("File First Cyber Complaint"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
        ),
      );
    }

    // Determine active case
    Map<String, dynamic> activeCase = complaints.first;
    if (_selectedCaseId != null) {
      activeCase = complaints.firstWhere(
        (c) => c['id'] == _selectedCaseId,
        orElse: () => complaints.first,
      );
    } else if (widget.initialCaseId != null) {
      activeCase = complaints.firstWhere(
        (c) => c['id'] == widget.initialCaseId,
        orElse: () => complaints.first,
      );
    }

    final activeStatus = activeCase['status']?.toString().toUpperCase() ?? 'SUBMITTED';
    final rank = _getStageRank(activeStatus);

    // Parse attached evidence
    List<String> attachedFiles = [];
    final attachedRaw = activeCase['attachedEvidence']?.toString() ?? '';
    if (attachedRaw.isNotEmpty) {
      attachedFiles = attachedRaw
          .split(RegExp(r'[;,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (attachedFiles.isEmpty) {
      attachedFiles = [
        'Extortion_Blackmail_DM_Proof.png',
        'CERT_In_Forensic_Report.pdf',
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Timeline & Status'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              db.syncFromDatabase();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Refreshed complaint status from Local SQLite Server.")),
              );
            },
          ),
        ],
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Action Bar: File New Complaint Button
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Running Complaints",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                            Text(
                              "Track real-time legal & forensic progress",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CyberReportScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("New Complaint", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Complaint Selector Chips (Carousel / Horizontal bar)
                SizedBox(
                  height: 62,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final c = complaints[index];
                      final isSelected = c['id'] == activeCase['id'];
                      final shortId = (c['id']?.toString() ?? '').length > 10
                          ? "...${c['id']!.toString().substring(c['id']!.toString().length - 6)}"
                          : c['id']?.toString() ?? 'case';

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCaseId = c['id'];
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.purple : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? Colors.purple.shade900 : Colors.purple.shade100,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Colors.purple.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    shortId,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : Colors.purple,
                                    ),
                                  ),
                                  Text(
                                    c['threatScore'] ?? '90%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isSelected ? Colors.amberAccent : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c['category'] ?? 'CYBER',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? Colors.white70 : Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Active Complaint Dossier Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.assignment_turned_in, color: Colors.purple, size: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Case #${activeCase['id'] ?? '1780512594344'}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Category: ${activeCase['category'] ?? 'BLACKMAIL & EXTORTION'}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: rank >= 5 ? Colors.green : Colors.purple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activeStatus,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Description & Details
                      Text(
                        "Incident: ${activeCase['description'] ?? 'No description'}",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                      ),
                      if (activeCase['offenderLink'] != null && activeCase['offenderLink'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.link, size: 14, color: Colors.purple),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                activeCase['offenderLink'],
                                style: const TextStyle(fontSize: 11, color: Colors.purple, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Filed By: ${activeCase['userName'] ?? 'Tisha Patel'}",
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                          Text(
                            "Threat Score: ${activeCase['threatScore'] ?? '92%'}",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Official Police Tracking Notice (Read-Only Status Display for Complainant)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              rank >= 5 ? Icons.verified : Icons.admin_panel_settings,
                              color: rank >= 5 ? Colors.green.shade700 : Colors.purple.shade800,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rank >= 5
                                        ? "Status: Case Closed & Threat Neutralized"
                                        : "Current Police Status: $activeStatus",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: rank >= 5 ? Colors.green.shade900 : Colors.purple.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "Investigation stages are updated exclusively by Police Officers & Cyber Cell Responders.",
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Case Timeline Progress Tracker Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Case Lifecycle Progression",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Stage ${rank + 1}/6",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildTimelineStep(
                        title: "1. AI Threat Analysis Completed",
                        subtitle: "Threat vector ${activeCase['category'] ?? 'BLACKMAIL'} identified • Score ${activeCase['threatScore'] ?? '92%'}",
                        time: "Verified",
                        isCompleted: true,
                        isActive: false,
                        isFirst: true,
                      ),
                      _buildTimelineStep(
                        title: "2. Complaint Formally Filed & Encrypted",
                        subtitle: "Cryptographic SHA-256 payload signed & logged in database",
                        time: "Logged",
                        isCompleted: true,
                        isActive: rank == 0,
                      ),
                      _buildTimelineStep(
                        title: "3. Assigned to SHE SHIELD Cyber Cell",
                        subtitle: "ACP Cyber Crime & Lead Digital Investigator assigned",
                        time: rank >= 2 ? "Assigned" : (rank == 1 ? "In Review" : "Pending"),
                        isCompleted: rank >= 2,
                        isActive: rank == 1,
                      ),
                      _buildTimelineStep(
                        title: "4. Digital Vault Evidence Verified",
                        subtitle: "Section 65B Indian Evidence Act package certified",
                        time: rank >= 3 ? "Certified" : (rank == 2 ? "Auditing" : "Pending"),
                        isCompleted: rank >= 3,
                        isActive: rank == 2,
                      ),
                      _buildTimelineStep(
                        title: "5. Platform Takedown & Subpoena Notice",
                        subtitle: "Targeting offender URL for takedown & ISP subscriber subpoena",
                        time: rank >= 4 ? "Issued" : (rank == 3 ? "Drafting" : "Pending"),
                        isCompleted: rank >= 4,
                        isActive: rank == 3,
                      ),
                      _buildTimelineStep(
                        title: "6. Case Resolved & Threat Neutralized",
                        subtitle: "Offender blocked, coercion prevented, legal safety active",
                        time: rank >= 5 ? "RESOLVED" : "Pending",
                        isCompleted: rank >= 5,
                        isActive: rank == 4,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Attached Evidence Section with Preview
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.folder_zip, color: Colors.purple, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Attached Evidence (${attachedFiles.length})",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _showAttachMoreVaultEvidenceModal(context, activeCase),
                            icon: const Icon(Icons.add, size: 14, color: Colors.purple),
                            label: const Text("Attach More", style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Tap 'Preview' on any file below to inspect real audio waveforms, CCTV footage, or extortion screenshots:",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      ...attachedFiles.map((file) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade100),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(getEvidenceAssetIcon(file, null), color: Colors.purple, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    const Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 11, color: Colors.green),
                                        SizedBox(width: 3),
                                        Text(
                                          "Tamper Check: PASS",
                                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  EvidencePreviewDialog.show(
                                    context,
                                    fileName: file,
                                    size: '2.8 MB',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A148C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.visibility, size: 14),
                                label: const Text("Preview", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
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
        ? Colors.green
        : (isActive ? Colors.purple : Colors.grey.shade400);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : (isActive ? Colors.purple.shade50 : Colors.grey.shade100),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 2),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check
                    : (isActive ? Icons.sync : Icons.hourglass_empty),
                size: 14,
                color: iconColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: isCompleted ? Colors.green.shade200 : Colors.grey.shade300,
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
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isActive ? Colors.purple : (isCompleted ? Colors.black87 : Colors.grey),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade50
                            : (isActive ? Colors.purple.shade50 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
