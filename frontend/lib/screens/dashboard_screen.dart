                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off, color: Colors.red),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Firestore Offline Mode. Operating on local cache.",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await db.retryInit();
                              },
                              child: const Text("Retry", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!db.backendHealthy && !db.isOfflineMode) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                      
<truncated 3914 bytes>
                                     fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: coverageReduced ? Colors.orange : Colors.purple,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        coverageReduced ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                        color: coverageReduced ? Colors.orange : Colors.green,
                                        size: 24,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "RISK TREND",
                                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
The above content does NOT show the entire file contents. If you need to view any lines of the file which were not shown to complete your task, call this tool again to view those lines.
