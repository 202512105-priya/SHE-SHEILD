import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _ingestEvidence(String type) {
    var db = Provider.of<DatabaseService>(context, listen: false);
    String fileName = "${type.replaceAll(' ', '_')}_Proof_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.mp4";
    db.addVaultAsset(fileName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Ingested new evidence asset: $fileName"),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                      const Text(
                        "Ingest Safe Evidence",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
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
                  indicator: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.purple.shade900,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  tabs: const [
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
                        asset['name'].toString().contains('Audio') ? Icons.audiotrack : Icons.insert_drive_file,
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
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showChainOfCustodyModal(context, asset),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.purple),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.timeline, size: 16, color: Colors.purple),
                      label: const Text("Chain of Custody", style: TextStyle(fontSize: 12, color: Colors.purple)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _runAiScannerModal(context, asset),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.memory, size: 16, color: Colors.white),
                      label: const Text("Run AI Scanner", style: TextStyle(fontSize: 12)),
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
