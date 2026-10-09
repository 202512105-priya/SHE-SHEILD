// lib/screens/safety_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class SafetyMapScreen extends StatefulWidget {
  const SafetyMapScreen({super.key});

  @override
  State<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends State<SafetyMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _loadUnsafeZones();
  }

  // Load AI-predicted unsafe zones and display them on the map.
Future<void> _loadUnsafeZones() async {
  final db = Provider.of<DatabaseService>(context, listen: false);
  // Use AI service to predict zones (you may customize count as needed)
  final aiService = AIUnsafeZoneService();
  List<Map<String, dynamic>> zones = await aiService.predictUnsafeZones(count: 5);
  // Clear existing circles before adding new ones
  setState(() {
    _circles.clear();
    for (var zone in zones) {
      final lat = zone['latitude'] as double? ?? 0.0;
      final lng = zone['longitude'] as double? ?? 0.0;
      final radius = zone['radius'] as double? ?? 200.0;
      _circles.add(Circle(
        circleId: CircleId('zone_${zone['id']}'),
        center: LatLng(lat, lng),
        radius: radius,
        fillColor: Colors.redAccent.withOpacity(0.3),
        strokeColor: Colors.red,
        strokeWidth: 2,
      ));
    }
  });
}
    final db = Provider.of<DatabaseService>(context, listen: false);
    // Fetch unsafe zone predictions (placeholder collection)
    final zones = await db.getCollection('AIUnsafeZones');
    for (var zone in zones) {
      final lat = zone['latitude'] as double? ?? 0.0;
      final lng = zone['longitude'] as double? ?? 0.0;
      final radius = zone['radius'] as double? ?? 200.0;
      setState(() {
        _circles.add(Circle(
          circleId: CircleId('zone_${zone['id']}'),
          center: LatLng(lat, lng),
          radius: radius,
          fillColor: Colors.redAccent.withOpacity(0.3),
          strokeColor: Colors.red,
          strokeWidth: 2,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Safety Map')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(23.0225, 72.5714), // Example location
          zoom: 13,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        circles: _circles,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
