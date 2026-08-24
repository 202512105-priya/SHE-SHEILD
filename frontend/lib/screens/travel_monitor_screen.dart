import 'dart:async'; 
import 'package:flutter/material.dart'; 
import 'package:provider/provider.dart'; 
import '../services/database_service.dart'; 
class TravelMonitorScreen extends StatefulWidget { 
 const TravelMonitorScreen({super.key}); 
 @override 
 State<TravelMonitorScreen> createState() => _TravelMonitorScreenState(); 
} 
class _TravelMonitorScreenState extends State<TravelMonitorScreen> { 
 final _destinationController = TextEditingController(); 
 final _durationController = TextEditingController(text: "5"); 
 
 bool _isTracking = false; 
 @override 
 void dispose() { 
 _destinationController.dispose(); 
 _durationController.dispose(); 
 super.dispose(); 
 } 
 @override 
 Widget build(BuildContext context) { 
 return Scaffold( 
 appBar: AppBar(title: const Text("Safety Transit Monitor"), backgroundColor: Colors.purple.shade50), 
 body: Center( 
 child: Column( 
 children: [ 
 TextFormField( 
 controller: _destinationController, 
 decoration: const InputDecoration(labelText: "Destination Name"), 
 ), 
 ], 
 ), 
 ), 
 ); 
 } 
}
