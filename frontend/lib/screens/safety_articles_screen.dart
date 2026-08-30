import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart';

// -------------------------------------------------------------
// 1. SAFETY AWARENESS HUB (Module 10)
// -------------------------------------------------------------
class AwarenessHubScreen extends StatelessWidget {
  const AwarenessHubScreen({super.key});

  final List<Map<String, String>> _articles = const [
    {
      "title": "Cyber Safety 101: Preventing Online Harassment",
      "category": "Cyber Safety",
      "summary": "Block immediate communication channels, document dates, capture chat logs, and do not submit to monetary blackmail.",
    },
    {
      "title": "Self Defense Guidelines: The Power of Pepper Spray",
      "category": "Self Defense",
      "summary": "Always hold spray with dominant thumb on the trigger button, secure distance, aim for targets, and call fallback SOS.",
    },
    {
      "title": "Scam Alert: Beware of Mock UPI Verification Linkages",
      "category": "Scam Alerts",
      "summary": "Do not click on unverified request links claiming to deposit safety balances. Government channels do not check OTPs.",
    },
    {
      "title": "Emergency Preparedness: Pairing Wearables Profiles",
      "category": "Emergency Preparedness",
      "summary": "Keep device battery optimization disabled for SHE SHIELD to secure background location feed
<truncated 5830 bytes>
e syncing...")
                            else
                              Column(
                                children: timeline.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    key: ValueKey<String>(entry['timelineId']),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(entry['status'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              Text(entry['remarks'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
