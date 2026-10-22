                                  trailing: Text(q['timestamp'].toString().substring(11, 19), style: const TextStyle(fontSize: 11)),
                                );
                              },
                            );
                          },
                        ),
                        
                        // Action buttons to simulate adding voice trigger or offline trigger
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  // Simulate a voice SOS log
                                  String logId = "vl-${DateTime.now().millisecondsSinceEpoch}";
                                  await db.addDocument("VoiceSOSLogs", logId, {
                                    "logId": logId,
                                    "userId": db.currentUserId,
                                    "detectedPhrase": _activePhrase,
                                    "language": db.currentLanguage,
                                    "confidence": 0.94,
                                    "timestamp": DateTime.now().toIso8601String()
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    
<truncated 173 bytes>
                    child: const Text("Sim Voice Trigger"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  // Simulate adding to offline queue
                                  String queueId = "oq-${DateTime.now().millisecondsSinceEpoch}";
                                  await db.addDocument("OfflineSOSQueue", queueId, {
                                    "queueId": queueId,
                                    "userId": db.currentUserId,
                                    "smsBody": "ENC_SMS_SOS_LAT_23.02_LNG_72.57_PIN_1234",
                                    "syncStatus": "pending",
                                    "timestamp": DateTime.now().toIso8601String()
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("SMS fallback queued in OfflineSOSQueue.")),
                                  );
                                  
                                  // Sync timer simulator
                                  Timer(const Duration(seconds: 4), () async {
                                    await db.updateDocument("OfflineSOSQueue", queueId, {
                                      "syncStatus": "synced"
                                    });
                                  });
                                },
                                child: const Text("Sim Offline SOS"),
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
