import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/voice_engine_service.dart';

class VoiceAssistantModals {
  /// Opens Live Voice SOS Phrase Detection & Automatic Audio Recording Modal
  static void showPhraseRecognitionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _VoicePhraseRecognitionSheet(),
    );
  }

  /// Opens Emergency Audio Recorder modal that records real audio and stores in SQLite Audio Vault
  static void showAudioRecorderModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AudioRecorderSheet(),
    );
  }
}

class _VoicePhraseRecognitionSheet extends StatefulWidget {
  const _VoicePhraseRecognitionSheet();

  @override
  State<_VoicePhraseRecognitionSheet> createState() => _VoicePhraseRecognitionSheetState();
}

class _VoicePhraseRecognitionSheetState extends State<_VoicePhraseRecognitionSheet> {
  final VoiceEngineService _engine = VoiceEngineService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final db = Provider.of<DatabaseService>(context, listen: false);
      if (_engine.state == VoiceSosState.IDLE ||
          _engine.state == VoiceSosState.SAVED ||
          _engine.state == VoiceSosState.FAILED) {
        _engine.enableVoiceSos(db);
      }
    });
  }

  static String _fmtSec(int total) {
    final s = total < 0 ? 0 : total;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return AnimatedBuilder(
      animation: _engine,
      builder: (context, _) {
        final st = _engine.state;
        final isRec = st == VoiceSosState.RECORDING;
        final isTriggered = st == VoiceSosState.SOS_TRIGGERED;
        final isListening = st == VoiceSosState.LISTENING;
        final isSaving = st == VoiceSosState.STOPPING || st == VoiceSosState.SAVING_TO_VAULT;
        final phrase = db.customVoicePhrase.trim();

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isRec || isTriggered) ? Colors.red.shade100 : Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isRec
                          ? Icons.fiber_manual_record
                          : (isTriggered ? Icons.warning_rounded : Icons.record_voice_over),
                      color: (isRec || isTriggered) ? Colors.red : Colors.purple,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice SOS • State: ${_engine.stateName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: (isRec || isTriggered) ? Colors.red.shade900 : Colors.purple.shade900,
                          ),
                        ),
                        Text(
                          _engine.micPermissionGranted
                              ? 'Microphone Access: GRANTED (${kIsWeb ? "Active Tab" : "Device Mic"})'
                              : 'Microphone Access: NOT GRANTED',
                          style: TextStyle(
                            fontSize: 11,
                            color: _engine.micPermissionGranted ? Colors.green.shade800 : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
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
              const Divider(height: 20),

              // Saved Config Ribbon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Configured Phrase', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          phrase.isNotEmpty ? phrase : '(Not set)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 28, color: Colors.purple.shade200),
                    Column(
                      children: [
                        const Text('Language', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          db.selectedLanguage,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 28, color: Colors.purple.shade200),
                    Column(
                      children: [
                        const Text('Max Dur', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          '${db.maxRecordingDurationSec}s',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 96 + (_engine.audioLevel.clamp(0.0, 10.0) * 4),
                          height: 96 + (_engine.audioLevel.clamp(0.0, 10.0) * 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isRec || isTriggered)
                                ? Colors.red.shade600
                                : (isListening ? Colors.purple.shade600 : Colors.grey.shade400),
                            boxShadow: [
                              BoxShadow(
                                color: (isRec || isTriggered)
                                    ? Colors.red.withValues(alpha: 0.45)
                                    : Colors.purple.withValues(alpha: 0.3),
                                blurRadius: 18 + (_engine.audioLevel.clamp(0.0, 10.0) * 3),
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isRec
                                ? Icons.graphic_eq
                                : (isListening ? Icons.mic : (st == VoiceSosState.SAVED ? Icons.check : Icons.mic_off)),
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (isRec) ...[
                          Text(
                            _fmtSec(_engine.elapsedSeconds),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'SOS ID: ${_engine.activeSosEventId ?? ''} • Max ${_fmtSec(_engine.maxDurationSeconds)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                        if (isSaving) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: _engine.uploadProgress),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _engine.statusDetail,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: st == VoiceSosState.FAILED
                                ? Colors.red.shade900
                                : (st == VoiceSosState.SAVED ? Colors.green.shade800 : Colors.black87),
                          ),
                        ),
                        if (_engine.errorMessage != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _engine.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            _engine.recognizedTranscript.isNotEmpty
                                ? '"${_engine.recognizedTranscript}"'
                                : (phrase.isNotEmpty
                                    ? 'Speak "$phrase" to trigger SOS & auto-recording...'
                                    : 'Configure a custom voice phrase first.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              color: _engine.recognizedTranscript.isNotEmpty ? Colors.black87 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              if (isRec)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.stop_circle),
                    label: const Text('Stop Recording & Save to Evidence Vault', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _engine.stopRecordingAndSave(db),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: phrase.isEmpty || _engine.isBusy
                            ? null
                            : () => _engine.triggerVoiceSosAndRecord(db, detectedPhrase: phrase),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.bolt, color: Colors.red, size: 18),
                        label: const Text('Test Phrase Trigger -> Record', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _engine.isBusy
                            ? null
                            : () async {
                                if (isListening) {
                                  await _engine.disableVoiceSos();
                                } else {
                                  await _engine.enableVoiceSos(db);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isListening ? Colors.grey.shade800 : Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(isListening ? Icons.stop : Icons.mic, size: 18),
                        label: Text(
                          isListening ? 'Stop Listening' : 'Listen Now',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AudioRecorderSheet extends StatefulWidget {
  const _AudioRecorderSheet();

  @override
  State<_AudioRecorderSheet> createState() => _AudioRecorderSheetState();
}

class _AudioRecorderSheetState extends State<_AudioRecorderSheet> {
  final VoiceEngineService _engine = VoiceEngineService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final db = Provider.of<DatabaseService>(context, listen: false);
      if (!_engine.isBusy) {
        _engine.triggerVoiceSosAndRecord(db, detectedPhrase: 'Manual_Emergency_Recorder');
      }
    });
  }

  static String _fmtSec(int total) {
    final s = total < 0 ? 0 : total;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return AnimatedBuilder(
      animation: _engine,
      builder: (context, _) {
        final st = _engine.state;
        final isRecording = st == VoiceSosState.RECORDING;
        final isSaving = st == VoiceSosState.STOPPING || st == VoiceSosState.SAVING_TO_VAULT;

        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.mic, color: Colors.deepOrange, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audio Evidence Recorder (${_engine.stateName})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepOrange),
                        ),
                        Text(
                          _engine.micPermissionGranted
                              ? 'Microphone Access: GRANTED'
                              : 'Microphone Access Required',
                          style: TextStyle(
                            fontSize: 11,
                            color: _engine.micPermissionGranted ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(height: 20),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isRecording)
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          ),
                        Text(
                          _fmtSec(_engine.elapsedSeconds),
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _engine.statusDetail,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    if (_engine.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _engine.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ],
                    if (isSaving) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(value: _engine.uploadProgress),
                    ],
                  ],
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : (isRecording
                              ? () async {
                                  final ok = await _engine.stopRecordingAndSave(db);
                                  if (!context.mounted) return;
                                  if (ok) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(_engine.statusDetail),
                                        backgroundColor: Colors.green.shade800,
                                      ),
                                    );
                                  }
                                }
                              : () => _engine.triggerVoiceSosAndRecord(db, detectedPhrase: 'Manual_Emergency_Recorder')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRecording ? Colors.red.shade800 : Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(isRecording ? Icons.stop_circle : Icons.fiber_manual_record),
                      label: Text(
                        isRecording ? 'Stop & Save to Vault' : 'Record Audio Proof',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
