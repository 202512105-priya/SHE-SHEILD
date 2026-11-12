import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/voice_engine_service.dart';

class AudioEvidenceSection extends StatelessWidget {
  final bool showVoiceStatusBanner;
  const AudioEvidenceSection({super.key, this.showVoiceStatusBanner = true});

  static String _formatSeconds(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final mins = (s ~/ 60).toString().padLeft(2, '0');
    final secs = (s % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String _formatDateTime(String iso) {
    if (iso.isEmpty) return 'Unknown';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return iso;
    final y = parsed.year;
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    final ss = parsed.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  static Color _stateColor(VoiceSosState state) {
    switch (state) {
      case VoiceSosState.LISTENING:
        return Colors.purple.shade700;
      case VoiceSosState.SOS_TRIGGERED:
      case VoiceSosState.RECORDING:
        return Colors.red.shade700;
      case VoiceSosState.STOPPING:
      case VoiceSosState.SAVING_TO_VAULT:
        return Colors.orange.shade800;
      case VoiceSosState.SAVED:
        return Colors.green.shade700;
      case VoiceSosState.FAILED:
        return Colors.red.shade900;
      case VoiceSosState.IDLE:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    if (!db.isAuthenticated || !db.hasPermission('audio_evidence:own')) {
      return const SizedBox.shrink();
    }

    final engine = VoiceEngineService();
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final recordings = db.audioEvidence;
        final offlineQueue = db.offlineAudioQueue;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.spatial_audio_off, color: Colors.purple, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Voice SOS Audio Evidence Vault',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.purple, size: 20),
                  tooltip: 'Refresh Audio Evidence',
                  onPressed: () async {
                    await db.syncPendingOfflineAudio();
                    await db.loadAudioEvidence();
                  },
                ),
              ],
            ),

            if (showVoiceStatusBanner) ...[
              const SizedBox(height: 8),
              _buildVoiceEngineStatusCard(context, db, engine),
            ],

            if (offlineQueue.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildOfflinePendingCard(context, db, offlineQueue),
            ],

            const SizedBox(height: 12),
            if (recordings.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Column(
                  children: [
                    Icon(Icons.mic_none, size: 36, color: Colors.purple.shade200),
                    const SizedBox(height: 8),
                    const Text(
                      'No Voice SOS Audio Recordings Yet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure a custom phrase and enable Voice SOS in the SOS Protection Center. When detected, recording starts automatically and saves here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ...recordings.map((rec) => _buildRecordingCard(context, db, engine, rec)),
          ],
        );
      },
    );
  }

  Widget _buildVoiceEngineStatusCard(
    BuildContext context,
    DatabaseService db,
    VoiceEngineService engine,
  ) {
    final st = engine.state;
    final stColor = _stateColor(st);
    final phraseConfigured = db.customVoicePhrase.trim().isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: stColor.withValues(alpha: 0.4), width: 1.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  st == VoiceSosState.RECORDING
                      ? Icons.fiber_manual_record
                      : (st == VoiceSosState.LISTENING ? Icons.hearing : Icons.shield),
                  color: stColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Voice SOS Engine: ${engine.stateName}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: stColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: stColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    engine.stateName,
                    style: TextStyle(color: stColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              engine.statusDetail,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            if (st == VoiceSosState.RECORDING) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Duration: ${_formatSeconds(engine.elapsedSeconds)} / ${_formatSeconds(engine.maxDurationSeconds)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontFamily: 'monospace'),
                        ),
                        Text(
                          'SOS: ${engine.activeSosEventId ?? ''}',
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                    if (engine.recordingStartedAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Started: ${_formatDateTime(engine.recordingStartedAt!.toIso8601String())}',
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.stop_circle, size: 18),
                      label: const Text('Stop Recording & Save to Vault'),
                      onPressed: () => engine.stopRecordingAndSave(db),
                    ),
                  ],
                ),
              ),
            ],
            if (st == VoiceSosState.SAVING_TO_VAULT) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: engine.uploadProgress),
            ],
            if (st == VoiceSosState.IDLE || st == VoiceSosState.SAVED || st == VoiceSosState.FAILED) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (!engine.micPermissionGranted)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange.shade700,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.mic_none, size: 15),
                      label: const Text('Allow Microphone Access', style: TextStyle(fontSize: 11)),
                      onPressed: () async {
                        final granted = await engine.requestMicPermission();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              granted
                                  ? 'Microphone permission granted!'
                                  : (engine.errorMessage ?? 'Microphone permission denied.'),
                            ),
                            backgroundColor: granted ? Colors.green : Colors.red,
                          ),
                        );
                      },
                    ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/sos_protection'),
                    icon: const Icon(Icons.tune, size: 15),
                    label: Text(
                      phraseConfigured ? 'Voice Settings (${db.selectedLanguage})' : 'Configure Voice Phrase',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  if (phraseConfigured)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade800,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.mic, size: 15),
                      label: const Text('Start Voice SOS Listening', style: TextStyle(fontSize: 11)),
                      onPressed: () async {
                        await db.saveVoiceSosSettings(voiceSosEnabled: true);
                        await engine.enableVoiceSos(db);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfflinePendingCard(
    BuildContext context,
    DatabaseService db,
    List<Map<String, dynamic>> queue,
  ) {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.amber.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.amber.shade900, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${queue.length} Offline Audio Recording(s) Saved Locally',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () async {
                    final synced = await db.syncPendingOfflineAudio();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          synced > 0
                              ? 'Synced $synced pending audio recording(s) to SQLite Vault.'
                              : 'Server still unreachable; offline audio remains safely preserved.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Sync Now', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...queue.map((item) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item['filename']} • SOS: ${item['sosEventId']} • ${_formatBytes((item['fileSize'] as num?)?.toInt() ?? 0)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        onPressed: () => db.deleteOfflineQueuedAudio(item['id'].toString()),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingCard(
    BuildContext context,
    DatabaseService db,
    VoiceEngineService engine,
    Map<String, dynamic> rec,
  ) {
    final recId = rec['id']?.toString() ?? '';
    final sosId = rec['sosEventId']?.toString() ?? 'N/A';
    final filename = rec['filename']?.toString() ?? '$recId.m4a';
    final durationSec = (rec['durationSeconds'] as num?)?.toInt() ?? 0;
    final fileSize = (rec['fileSize'] as num?)?.toInt() ?? 0;
    final status = rec['status']?.toString() ?? 'SAVED';
    final integrity = rec['integrityStatus']?.toString() ?? 'UNVERIFIED';
    final startedAt = rec['startedAt']?.toString() ?? rec['createdAt']?.toString() ?? '';

    final isThisPlaying = engine.playingRecordingId == recId && !engine.isPlaybackPaused;
    final isThisPaused = engine.playingRecordingId == recId && engine.isPlaybackPaused;
    final isVerified = integrity == 'VERIFIED';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.purple.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.graphic_eq, color: Colors.purple, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filename,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SOS Event: ${sosId.isEmpty ? "Manual" : sosId}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.purple.shade800),
                      ),
                      Text(
                        'Recorded: ${_formatDateTime(startedAt)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                      Text(
                        'Duration: ${_formatSeconds(durationSec)} • Size: ${_formatBytes(fileSize)} • Status: $status',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isVerified ? Colors.green.shade300 : Colors.orange.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified ? Icons.verified_user : Icons.help_outline,
                        size: 12,
                        color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        integrity,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isVerified ? Colors.green.shade900 : Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isThisPlaying || isThisPaused) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(isThisPlaying ? Icons.volume_up : Icons.pause_circle, size: 16, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: engine.playbackDurationSec > 0
                            ? (engine.playbackPositionSec / engine.playbackDurationSec).clamp(0.0, 1.0)
                            : null,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatSeconds(engine.playbackPositionSec.round())} / ${_formatSeconds(durationSec)}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],

            if (engine.playbackError != null && engine.playingRecordingId == null) ...[
              const SizedBox(height: 6),
              Text(
                engine.playbackError!,
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ],

            const Divider(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (isThisPlaying)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.pause, size: 15),
                    label: const Text('Pause', style: TextStyle(fontSize: 11)),
                    onPressed: () => engine.pausePlayback(),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A148C),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.play_arrow, size: 15),
                    label: Text(isThisPaused ? 'Resume' : 'Play', style: const TextStyle(fontSize: 11)),
                    onPressed: () => engine.playRecording(db, recId),
                  ),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Download', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    final res = await engine.downloadRecording(db, recId, filename);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          res.ok
                              ? (res.savedPath != null ? 'Saved to ${res.savedPath}' : 'Downloaded $filename')
                              : (res.error ?? 'Download failed'),
                        ),
                        backgroundColor: res.ok ? Colors.green : Colors.red,
                      ),
                    );
                  },
                ),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.verified, size: 15),
                  label: const Text('Verify SHA-256', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    final res = await db.verifyAudioIntegrity(recId);
                    if (!context.mounted) return;
                    final verified = res.success && res.data?['verified'] == true;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(
                              verified ? Icons.check_circle : Icons.error,
                              color: verified ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(verified ? 'Integrity Verified' : 'Verification Failed'),
                          ],
                        ),
                        content: SelectableText(
                          res.success
                              ? 'Result: ${res.data?['integrityStatus']}\n\nStored SHA-256:\n${res.data?['storedSha256']}\n\nRecomputed SHA-256:\n${res.data?['computedSha256'] ?? 'File Missing'}'
                              : (res.error ?? 'Integrity check failed'),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                ),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.info_outline, size: 15),
                  label: const Text('Metadata', style: TextStyle(fontSize: 11)),
                  onPressed: () => _showMetadataDialog(context, rec),
                ),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Delete', style: TextStyle(fontSize: 11)),
                  onPressed: () => _confirmAndDelete(context, db, engine, recId, filename),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMetadataDialog(BuildContext context, Map<String, dynamic> rec) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Audio Recording Metadata', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _metaLine('Recording ID', rec['id']?.toString() ?? ''),
              _metaLine('Owner User ID', rec['userId']?.toString() ?? ''),
              _metaLine('SOS Event ID', rec['sosEventId']?.toString() ?? ''),
              _metaLine('Filename', rec['filename']?.toString() ?? ''),
              _metaLine('Audio Format', rec['mimeType']?.toString() ?? ''),
              _metaLine('File Size', _formatBytes((rec['fileSize'] as num?)?.toInt() ?? 0)),
              _metaLine('Duration', '${rec['durationSeconds']} seconds'),
              _metaLine('Started At', _formatDateTime(rec['startedAt']?.toString() ?? '')),
              _metaLine('Ended At', _formatDateTime(rec['endedAt']?.toString() ?? '')),
              _metaLine('Created At', _formatDateTime(rec['createdAt']?.toString() ?? '')),
              _metaLine('Integrity Status', rec['integrityStatus']?.toString() ?? ''),
              _metaLine('SHA-256 Digest', rec['sha256Hash']?.toString() ?? ''),
              const Divider(height: 16),
              Text(
                'Note: SHA-256 verifies byte integrity since capture; legal admissibility depends on applicable evidentiary rules and judicial review.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _metaLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
          SelectableText(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    DatabaseService db,
    VoiceEngineService engine,
    String recId,
    String filename,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Audio Recording?'),
        content: Text(
          'Permanently delete "$filename" from secure storage and SQLite Evidence Vault? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    if (engine.playingRecordingId == recId) {
      await engine.stopPlayback();
    }
    final res = await db.deleteAudioEvidence(recId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? 'Deleted $filename securely.' : (res.error ?? 'Delete failed.')),
        backgroundColor: res.success ? Colors.green : Colors.red,
      ),
    );
  }
}
