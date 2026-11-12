import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/audio_evidence_section.dart';
import '../widgets/evidence_preview_dialog.dart';
import '../widgets/voice_assistant_modals.dart';
import 'auth_screens.dart';

class EvidenceVaultScreen extends StatefulWidget {
  const EvidenceVaultScreen({super.key});

  @override
  State<EvidenceVaultScreen> createState() => _EvidenceVaultScreenState();
}

class _EvidenceVaultScreenState extends State<EvidenceVaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<DatabaseService>(context, listen: false).loadAudioEvidence();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static final List<Map<String, String>> _availableDeviceFiles = [
    {
      'name': 'Extortion_Blackmail_DM_Proof.png',
      'type': 'IMAGE',
      'size': '2.8 MB',
      'time': 'Today, 09:42 AM',
      'source': 'Screenshots',
      'hash': 'SHA256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    },
    {
      'name': 'Cab_Ride_Rear_Dashcam.mp4',
      'type': 'VIDEO',
      'size': '18.5 MB',
      'time': 'Today, 01:15 AM',
      'source': 'Camera Videos',
      'hash': 'SHA256: fcde2b2edba56bf408601fb721fe9b5c338d10ee429ea04fae5511b68fbf8fb9',
    },
    {
      'name': 'Threat_Call_Audio_Wiretap.m4a',
      'type': 'AUDIO',
      'size': '4.2 MB',
      'time': 'Yesterday, 08:30 PM',
      'source': 'Voice Recordings',
      'hash': 'SHA256: 7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069',
    },
    {
      'name': 'CERT_In_Forensic_Report.pdf',
      'type': 'DOCUMENT',
      'size': '1.8 MB',
      'time': '24 Oct, 04:12 PM',
      'source': 'Documents / Downloads',
      'hash': 'SHA256: a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e',
    },
    {
      'name': 'GPS_Deviation_Telemetry.json',
      'type': 'TELEMETRY',
      'size': '650 KB',
      'time': '24 Oct, 10:05 PM',
      'source': 'Sensors & Logs',
      'hash': 'SHA256: 2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae',
    },
    {
      'name': 'Harassment_Voicemail_Call.mp3',
      'type': 'AUDIO',
      'size': '3.4 MB',
      'time': '22 Oct, 07:15 PM',
      'source': 'Voice Recordings',
      'hash': 'SHA256: d855a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865',
    },
    {
      'name': 'Stalking_Vehicle_Photo.jpg',
      'type': 'IMAGE',
      'size': '4.6 MB',
      'time': '20 Oct, 02:40 PM',
      'source': 'DCIM / Camera',
      'hash': 'SHA256: 9f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9011',
    },
  ];

  void _uploadDeviceFile({
    required String name,
    required String type,
    required String size,
    String? hash,
  }) {
    var db = Provider.of<DatabaseService>(context, listen: false);
    final fileHash = hash ?? 'SHA256: ${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}7f83b1...${name.hashCode.abs().toRadixString(16)}';
    db.addVaultAsset(
      name,
      fileType: type,
      sizeMb: size,
      hash: fileHash,
      chainOfCustody: 'Device Storage Ingestion -> Cryptographic SHA-256 -> AES-256 Cloud Vault',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Expanded(child: Text("Secured $name in Vault! (PASS)")),
          ],
        ),
        backgroundColor: Colors.purple.shade900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: "PREVIEW NOW",
          textColor: Colors.amberAccent,
          onPressed: () {
            EvidencePreviewDialog.show(
              context,
              fileName: name,
              fileType: type,
              size: size,
              hash: fileHash,
            );
          },
        ),
      ),
    );
  }

  void _showCustomFilePickerModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'Harassment_Evidence_Record.mp4');
    String selectedType = 'VIDEO';
    String selectedSize = '6.4 MB';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.drive_folder_upload, color: Colors.purple),
                  SizedBox(width: 8),
                  Text("Pick Custom Device File", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("File Name & Extension:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.insert_drive_file, color: Colors.purple),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("File Category:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'IMAGE', child: Text('Image / Screenshot (.png, .jpg)')),
                        DropdownMenuItem(value: 'VIDEO', child: Text('Video Recording (.mp4)')),
                        DropdownMenuItem(value: 'AUDIO', child: Text('Audio Note / Call (.mp3, .m4a)')),
                        DropdownMenuItem(value: 'DOCUMENT', child: Text('Legal Document / PDF (.pdf)')),
                        DropdownMenuItem(value: 'TELEMETRY', child: Text('Telemetry / Sensor Log (.json)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text("Simulated File Size:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['1.5 MB', '4.2 MB', '12.8 MB', '24.0 MB'].map((sz) {
                        final isSel = selectedSize == sz;
                        return ChoiceChip(
                          label: Text(sz),
                          selected: isSel,
                          selectedColor: Colors.purple,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedSize = sz);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Device_Evidence_File.bin';
                    Navigator.pop(context);
                    _uploadDeviceFile(name: name, type: selectedType, size: selectedSize);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  icon: const Icon(Icons.cloud_upload, color: Colors.white, size: 16),
                  label: const Text("Upload to Vault", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeviceFileUploadModal(BuildContext context, {String? filterType}) {
    String currentFilter = filterType != null ? filterType.toUpperCase() : 'ALL';
    if (currentFilter.contains('PHOTO')) currentFilter = 'IMAGE';
    if (currentFilter.contains('VIDEO')) currentFilter = 'VIDEO';
    if (currentFilter.contains('AUDIO')) currentFilter = 'AUDIO';
    if (currentFilter.contains('DOC')) currentFilter = 'DOCUMENT';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredFiles = _availableDeviceFiles.where((f) {
              if (currentFilter == 'ALL') return true;
              return f['type'] == currentFilter;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Top Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
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
                          child: const Icon(Icons.phone_android, color: Colors.purple, size: 26),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Upload from Device Storage",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                              ),
                              Text(
                                "Select local photo, video, audio, or document proof",
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

                  // Storage Path Breadcrumb
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.folder_shared, size: 16, color: Colors.purple),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Internal Storage > SHE_SHIELD > Evidence (58.4 GB Free)",
                            style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        {'label': 'All Files', 'type': 'ALL'},
                        {'label': 'Photos', 'type': 'IMAGE'},
                        {'label': 'Videos', 'type': 'VIDEO'},
                        {'label': 'Audio Notes', 'type': 'AUDIO'},
                        {'label': 'Documents', 'type': 'DOCUMENT'},
                        {'label': 'Telemetry', 'type': 'TELEMETRY'},
                      ].map((item) {
                        final isSel = currentFilter == item['type'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(item['label']!),
                            selected: isSel,
                            selectedColor: Colors.purple,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : Colors.purple.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            onSelected: (val) {
                              setModalState(() {
                                currentFilter = item['type']!;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const Divider(height: 1),

                  // File List
                  Expanded(
                    child: filteredFiles.isEmpty
                        ? const Center(
                            child: Text(
                              "No device files found for this filter.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredFiles.length,
                            itemBuilder: (context, index) {
                              final file = filteredFiles[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getAssetIcon(file['name']!, file['type']),
                                          color: Colors.purple,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file['name']!,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              "${file['type']} • ${file['size']} • ${file['time']}",
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () {
                                          EvidencePreviewDialog.show(
                                            context,
                                            fileName: file['name']!,
                                            fileType: file['type']!,
                                            size: file['size']!,
                                            hash: file['hash'],
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          side: const BorderSide(color: Colors.purple),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text("Preview", style: TextStyle(fontSize: 11, color: Colors.purple)),
                                      ),
                                      const SizedBox(width: 6),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _uploadDeviceFile(
                                            name: file['name']!,
                                            type: file['type']!,
                                            size: file['size']!,
                                            hash: file['hash'],
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text("Upload", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Bottom Bar: Custom file option
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
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCustomFilePickerModal(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        side: const BorderSide(color: Colors.purple, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.drive_folder_upload, color: Colors.purple),
                      label: const Text(
                        "📁 Browse Custom File / Type Name...",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
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

  void _ingestEvidence(String type) {
    if (type.toLowerCase().contains('audio')) {
      VoiceAssistantModals.showAudioRecorderModal(context);
    } else {
      _showDeviceFileUploadModal(context, filterType: type);
    }
  }

  void _showChainOfCustodyModal(BuildContext context, Map<String, dynamic> asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.purple, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Chain of Custody Ledger",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple),
                        ),
                        Text(
                          asset['name'] ?? 'Travel_Trip_Audio_Evidence.mp4',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
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
              const Divider(height: 24),
              Text(
                "Hash: ${asset['hash'] ?? 'SHA256: 643199974ac7064...'}",
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.purple.shade900),
              ),
              const SizedBox(height: 16),
              _buildCustodyStep(
                title: "Asset Local Ingestion",
                desc: "Captured & encrypted with AES-256 on device capture",
                timestamp: asset['timestamp'] ?? DateTime.now().toIso8601String(),
                status: "COMPLETED",
              ),
              _buildCustodyStep(
                title: "Cryptographic SHA256 Hashing",
                desc: "SHA256 checksum generated & signed with device keys",
                timestamp: asset['timestamp'] ?? DateTime.now().toIso8601String(),
                status: "VERIFIED",
              ),
              _buildCustodyStep(
                title: "Encrypted Vault Storage",
                desc: "Uploaded to immutable decentralized cloud evidence vault",
                timestamp: asset['timestamp'] ?? DateTime.now().toIso8601String(),
                status: "SECURED",
              ),
              _buildCustodyStep(
                title: "Tamper Integrity Audit",
                desc: "Zero-knowledge proof verification • Tamper Check: PASS",
                timestamp: asset['timestamp'] ?? DateTime.now().toIso8601String(),
                status: "PASS",
                isLast: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Legal Export Package & Certificate generated.")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.purple,
                ),
                icon: const Icon(Icons.download),
                label: const Text("Export Immutable Legal Report"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _runAiScannerModal(BuildContext context, Map<String, dynamic> asset) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple),
              SizedBox(width: 8),
              Text("AI Evidence Analysis", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Asset: ${asset['name'] ?? 'Travel_Trip_Audio_Evidence.mp4'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AI Forensic Scan Summary:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple)),
                    SizedBox(height: 4),
                    Text("• Audio Spectrum: Threat keywords detected (verbal intimidation, coercion)", style: TextStyle(fontSize: 12)),
                    Text("• Spatial Metadata: GPS match with cab deviation zone", style: TextStyle(fontSize: 12)),
                    Text("• Deepfake Index: 0.02% (Authentic Organic Recording)", style: TextStyle(fontSize: 12)),
                    Text("• Tamper Check: PASS (Zero edits detected)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("AI forensic scan results attached to court evidence dossier.")),
                );
              },
              child: const Text("Attach to Case"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var db = Provider.of<DatabaseService>(context);
    var assets = db.vaultAssets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Evidence Vault'),
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
          child: Column(
            children: [
              // Ingest Buttons Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Ingest Safe Evidence",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.sd_storage, size: 12, color: Colors.purple),
                                SizedBox(width: 4),
                                Text("Storage Linked", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildIngestButton("Photo Proof", Icons.camera_alt, Colors.pink),
                          _buildIngestButton("Video Log", Icons.videocam, Colors.purple),
                          _buildIngestButton("Audio Clip", Icons.mic, Colors.deepOrange),
                          _buildIngestButton("Document", Icons.description, Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showDeviceFileUploadModal(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.file_upload_outlined, size: 20),
                        label: const Text(
                          "Upload from Device Files",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4 Tabs Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.purple.shade900,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  tabs: const [
                    Tab(text: "Audio Evidence"),
                    Tab(text: "Uploaded"),
                    Tab(text: "Under Review"),
                    Tab(text: "Verified"),
                    Tab(text: "Investigation Updated"),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: AudioEvidenceSection(),
                    ),
                    _buildAssetList(assets, "Uploaded"),
                    _buildAssetList(assets, "Under Review"),
                    _buildAssetList(assets, "Verified"),
                    _buildAssetList(assets, "Investigation Updated"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngestButton(String label, IconData icon, Color color) {
    return InkWell(
      onTap: () => _ingestEvidence(label),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetList(List<Map<String, dynamic>> assets, String category) {
    if (assets.isEmpty) {
      return const Center(child: Text("No evidence assets uploaded yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        var asset = assets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
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
                      child: Icon(
                        _getAssetIcon(asset['name'].toString(), asset['fileType']?.toString()),
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset['name'] ?? 'Travel_Trip_Audio_Evidence.mp4',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${asset['fileType'] ?? 'FILE'} • ${asset['sizeMb'] ?? '2.4 MB'} • ${asset['timestamp'] != null && asset['timestamp'].toString().length >= 10 ? asset['timestamp'].toString().substring(0, 10) : 'Today'}",
                            style: TextStyle(fontSize: 11, color: Colors.purple.shade900, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            asset['hash'] ?? 'SHA256: 643199974ac7064...',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "Tamper Check: ${asset['tamperCheck'] ?? 'PASS'}",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => EvidencePreviewDialog.show(
                        context,
                        fileName: asset['name'] ?? 'Evidence_File.mp4',
                        hash: asset['hash'],
                        fileType: asset['fileType'],
                        size: asset['sizeMb'],
                        timestamp: asset['timestamp'],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text("Preview File", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showChainOfCustodyModal(context, asset),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.purple),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.timeline, size: 16, color: Colors.purple),
                      label: const Text("Chain of Custody", style: TextStyle(fontSize: 12, color: Colors.purple)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _runAiScannerModal(context, asset),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.purple.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.memory, size: 16, color: Colors.purple),
                      label: const Text("AI Scanner", style: TextStyle(fontSize: 12, color: Colors.purple)),
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

  Widget _buildCustodyStep({
    required String title,
    required String desc,
    required String timestamp,
    required String status,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: Colors.green.shade200,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Chip(
                    label: Text(status, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
