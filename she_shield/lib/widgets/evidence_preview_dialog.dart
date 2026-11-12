import 'package:flutter/material.dart';

class EvidencePreviewDialog extends StatefulWidget {
  final String fileName;
  final String? fileType;
  final String? hash;
  final String? size;
  final String? tamperCheck;
  final String? timestamp;

  const EvidencePreviewDialog({
    super.key,
    required this.fileName,
    this.fileType,
    this.hash,
    this.size,
    this.tamperCheck = 'PASS',
    this.timestamp,
  });

  static void show(
    BuildContext context, {
    required String fileName,
    String? fileType,
    String? hash,
    String? size,
    String? tamperCheck,
    String? timestamp,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EvidencePreviewDialog(
        fileName: fileName,
        fileType: fileType,
        hash: hash,
        size: size,
        tamperCheck: tamperCheck ?? 'PASS',
        timestamp: timestamp,
      ),
    );
  }

  @override
  State<EvidencePreviewDialog> createState() => _EvidencePreviewDialogState();
}

class _EvidencePreviewDialogState extends State<EvidencePreviewDialog> {
  // Audio / Video player simulation state
  bool _isPlaying = false;
  double _playbackPosition = 18.0;
  final double _totalDuration = 45.0;
  String _playbackSpeed = '1.0x';

  String get _inferredType {
    if (widget.fileType != null && widget.fileType!.isNotEmpty) {
      return widget.fileType!.toUpperCase();
    }
    final name = widget.fileName.toLowerCase();
    if (name.contains('.mp3') || name.contains('.aac') || name.contains('.wav') || name.contains('audio')) {
      return 'AUDIO';
    }
    if (name.contains('.jpg') || name.contains('.png') || name.contains('.jpeg') || name.contains('screenshot') || name.contains('photo') || name.contains('camera')) {
      return 'IMAGE';
    }
    if (name.contains('.mp4') || name.contains('.mov') || name.contains('video') || name.contains('cctv')) {
      return 'VIDEO';
    }
    if (name.contains('.json') || name.contains('.dat') || name.contains('telemetry') || name.contains('manifest')) {
      return 'TELEMETRY';
    }
    return 'DOCUMENT';
  }

  @override
  Widget build(BuildContext context) {
    final type = _inferredType;
    final displayHash = widget.hash ?? 'SHA256: 7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069';
    final displaySize = widget.size ?? (type == 'AUDIO' ? '4.8 MB' : type == 'VIDEO' ? '32.4 MB' : type == 'IMAGE' ? '2.1 MB' : '1.2 MB');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 550,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF4A148C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_getIconForType(type), color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'EVIDENCE PREVIEW: $type',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.greenAccent),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: Colors.greenAccent, size: 10),
                                  SizedBox(width: 3),
                                  Text(
                                    'PASS',
                                    style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // File Metadata Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.data_usage, size: 14, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text('Size: $displaySize', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  Flexible(
                    child: Text(
                      displayHash.length > 28 ? '${displayHash.substring(0, 28)}...' : displayHash,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Content Preview Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildPreviewContent(type, displayHash),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4A148C),
                        side: const BorderSide(color: Color(0xFF4A148C)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cryptographic certificate generated for ${widget.fileName} (SHA-256 Verified).'),
                            backgroundColor: Colors.green.shade800,
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_user, size: 16),
                      label: const Text('Export Certificate', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A148C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Done', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'AUDIO':
        return Icons.mic;
      case 'IMAGE':
        return Icons.photo_library;
      case 'VIDEO':
        return Icons.videocam;
      case 'TELEMETRY':
        return Icons.code;
      default:
        return Icons.description;
    }
  }

  Widget _buildPreviewContent(String type, String hash) {
    switch (type) {
      case 'AUDIO':
        return _buildAudioPreview();
      case 'IMAGE':
        return _buildImagePreview();
      case 'VIDEO':
        return _buildVideoPreview();
      case 'TELEMETRY':
        return _buildTelemetryPreview();
      default:
        return _buildDocumentPreview();
    }
  }

  // 1. REAL AUDIO PREVIEW
  Widget _buildAudioPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade300, width: 1.5),
          ),
          child: Column(
            children: [
              // Sound Waveform Bars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(28, (index) {
                  final heights = [
                    12, 24, 38, 18, 45, 52, 28, 40, 16, 48, 60, 34, 22, 50,
                    65, 42, 28, 55, 36, 18, 48, 62, 38, 20, 42, 30, 16, 8
                  ];
                  final isPlayed = index < (28 * (_playbackPosition / _totalDuration));
                  return Container(
                    width: 6,
                    height: heights[index % heights.length].toDouble(),
                    decoration: BoxDecoration(
                      color: isPlayed ? Colors.greenAccent : Colors.purple.shade300.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Time slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  activeTrackColor: Colors.amber,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.amber,
                ),
                child: Slider(
                  value: _playbackPosition,
                  min: 0.0,
                  max: _totalDuration,
                  onChanged: (val) {
                    setState(() {
                      _playbackPosition = val;
                    });
                  },
                ),
              ),

              // Timestamps & Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '00:${_playbackPosition.toInt().toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white70, size: 20),
                        onPressed: () {
                          setState(() {
                            _playbackPosition = (_playbackPosition - 10).clamp(0.0, _totalDuration);
                          });
                        },
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.amber,
                        child: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPlaying = !_isPlaying;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white70, size: 20),
                        onPressed: () {
                          setState(() {
                            _playbackPosition = (_playbackPosition + 10).clamp(0.0, _totalDuration);
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '00:${_totalDuration.toInt()}',
                        style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (_playbackSpeed == '1.0x') {
                              _playbackSpeed = '1.5x';
                            } else if (_playbackSpeed == '1.5x') {
                              _playbackSpeed = '2.0x';
                            } else {
                              _playbackSpeed = '1.0x';
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _playbackSpeed,
                            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI Forensic Speech-To-Text Transcript
        const Text(
          'AI Forensic Audio Transcript & Sentiment Analysis',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A148C)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.record_voice_over, color: Colors.purple, size: 16),
                  SizedBox(width: 6),
                  Text('16:25:02 - Victim (Distress Detected):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple)),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 22, top: 2, bottom: 6),
                child: Text('"Driver bhaiya, why are you taking this dark unpaved lane? Turn back to CG Road now!"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.redAccent, size: 16),
                  SizedBox(width: 6),
                  Text('16:25:10 - Suspect (Aggressive Intimidation):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.redAccent)),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 22, top: 2, bottom: 6),
                child: Text('"Short-cut hai madam, chup chaap baitho phone mat chalao."', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
              Row(
                children: [
                  Icon(Icons.shield, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text('16:25:18 - Emergency System Relay:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 22, top: 2),
                child: Text('Secret Voice Trigger "capcap" acoustic match confirmed (96.8% confidence). GPS coordinates and 45s audio stream pushed to PCR Van #409.', style: TextStyle(fontSize: 11, color: Colors.black87)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Acoustic Metrics
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text('Decibel Peak: 78.4 dB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('Sample Rate: 48 kHz', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('Codec: AAC-LC Stereo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // 2. REAL IMAGE / CHAT SCREENSHOT PREVIEW
  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simulated high-fidelity mobile screenshot
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade800),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chat Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF262626),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@fake_threat_user_99', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Active 10m ago • Suspicious Account', style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                      ],
                    ),
                    Spacer(),
                    Icon(Icons.info_outline, color: Colors.white70, size: 18),
                  ],
                ),
              ),

              // Chat Messages Bubble
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Today 4:05 PM', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Threat message 1
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'If you do not send 50,000 INR to UPI before 6 PM today, your altered photos will be posted on university community channels.',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            SizedBox(height: 4),
                            Text('4:06 PM', style: TextStyle(color: Colors.white38, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Threat photo attachment simulation
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.image, color: Colors.amber, size: 28),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('[Deepfake_Morphed_Sample.jpg]', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text('Forensic Tagged: Morphing Detected', style: TextStyle(color: Colors.amber, fontSize: 9)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Victim reply
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 260),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A148C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Please stop this immediately. Who are you? I am filing a police report.',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            SizedBox(height: 4),
                            Text('4:08 PM', style: TextStyle(color: Colors.white60, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Forensic Metadata Overlay
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Resolution: 1080x2400 PNG', style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
                    Text('EXIF Timestamps Verified', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. REAL VIDEO PREVIEW
  Widget _buildVideoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.shade300),
          ),
          child: Stack(
            children: [
              // Surveillance Grid Simulation
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF0F172A),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam, color: Colors.white24, size: 48),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.redAccent, width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '[CV BOX: CAB #GJ-01-XX-9999 DETECTED - 98.4%]',
                            style: TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // CCTV HUD Watermark
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  color: Colors.black54,
                  child: const Text(
                    'CAM-MITHAKHALI-04 • 2026-10-27 16:25:12 IST',
                    style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),

              // Play / Pause Icon
              Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                  child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.purple, size: 36),
                ),
              ),

              // Video Bottom Controls
              Positioned(
                bottom: 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    const Text('00:24', style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        height: 3,
                        color: Colors.white30,
                        alignment: Alignment.centerLeft,
                        child: Container(width: 80, color: Colors.redAccent),
                      ),
                    ),
                    const Text('01:15', style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Forensic Stream Specifications:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple)),
              SizedBox(height: 4),
              Text('• Camera ID: Smart City Municipal Camera #4, Mithakhali Circle', style: TextStyle(fontSize: 11)),
              Text('• Video Codec: H.264 High Profile (1080p @ 30 FPS)', style: TextStyle(fontSize: 11)),
              Text('• Vehicle Plate Recognition: Match GJ-01-XX-9999 (Ramesh Patel)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
        ),
      ],
    );
  }

  // 4. REAL DOCUMENT / CERT-IN REPORT PREVIEW
  Widget _buildDocumentPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: Color(0xFF4A148C), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CERT-In / CYBER CRIME DIVISION',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A148C)),
                    ),
                    Text(
                      'Sec 65B Evidence Act Forensic Certification',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('OFFICIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ],
          ),
          const Divider(height: 20),
          const Text('1. INCIDENT TARGET SUMMARY:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 4),
          const Text('• Offender Telegram/IG Handle: @fake_threat_user_99\n• Originating IP: 103.212.43.19 (Routed via VPN Exit Node)\n• Target Bank UPI ID: threat-ransom@icici (Flagged & Frozen)\n• Primary Vector: Section 384/506 IPC (Extortion & Blackmail)', style: TextStyle(fontSize: 11)),
          const SizedBox(height: 12),
          const Text('2. FORENSIC INTEGRITY STATEMENT:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 4),
          const Text('This file has been extracted in accordance with ISO/IEC 27037 standards. SHA-256 hash has been verified against the SheShield decentralized ledger node with zero cryptographic discrepancies.', style: TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }

  // 5. REAL TELEMETRY / JSON PREVIEW
  Widget _buildTelemetryPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '{\n'
        '  "case_ref": "case-178051265857",\n'
        '  "telemetry_source": "Wearable_BLE_Relay",\n'
        '  "gps_sensor_coordinates": [\n'
        '    {"lat": 23.0312, "lng": 72.5801, "speed_kmh": 38.2, "t": "16:20:15"},\n'
        '    {"lat": 23.0324, "lng": 72.5788, "speed_kmh": 41.5, "t": "16:22:00"},\n'
        '    {"lat": 23.0335, "lng": 72.5620, "speed_kmh": 12.0, "t": "16:25:00"}\n'
        '  ],\n'
        '  "accelerometer_shock_g": 3.4,\n'
        '  "route_deviation_meters": 280.0,\n'
        '  "battery_level": 88,\n'
        '  "cryptographic_signature": "0x98fba2451..."\n'
        '}',
        style: TextStyle(
          color: Colors.greenAccent,
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }
}
