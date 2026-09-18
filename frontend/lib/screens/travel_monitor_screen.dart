import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'auth_screens.dart';

class TravelMonitorScreen extends StatefulWidget {
  const TravelMonitorScreen({super.key});

  @override
  State<TravelMonitorScreen> createState() => _TravelMonitorScreenState();
}

class _TravelMonitorScreenState extends State<TravelMonitorScreen> {
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController(text: "5");
  
  bool _isTracking = false;
  int _secondsLeft = 0;
  Timer? _tripTimer;

  bool _welfareCheckActive = false;
  int _welfareCountdown = 10;
  Timer? _welfareTimer;

  @override
  void dispose() {
    _tripTimer?.cancel();
    _welfareTimer?.cancel();
    _destinationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _startTrip() async {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a destination")),
      );
      return;
    }
    int mins = int.tryParse(_durationController.text) ?? 5;
    
    var db = Provider.of<DatabaseService>(context, listen: false);
    String tripId = "trip-${DateTime.now().millisecondsSinceEpoch}";
    
    await db.addDocument("TravelTrips", tripId, {
      "tripId": tripId,
      
<truncated 15550 bytes>
fe arrival check-in. Please confirm you are safe, or emergency services will be dispatched automatically.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "$_welfareCountdown",
                              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _dismissWelfare,
                                    child: const Text("Extend Timer"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: _reachedSafely,
                                    child: const Text("I Am Safe"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
