import 'dart:math';

class AIUnsafeZoneService {
  Future<List<Map<String, dynamic>>> predictUnsafeZones({int count = 5}) async {
    const centerLat = 23.0225;
    const centerLng = 72.5714;
    final random = Random();
    List<Map<String, dynamic>> zones = [];
    for (int i = 0; i < count; i++) {
      double offsetLat = (random.nextDouble() - 0.5) / 10;
      double offsetLng = (random.nextDouble() - 0.5) / 10;
      zones.add({
        'id': 'zone_${DateTime.now().millisecondsSinceEpoch}_$i',
        'latitude': centerLat + offsetLat,
        'longitude': centerLng + offsetLng,
        'radius': 150.0 + random.nextInt(200),
        'confidence': 0.6 + random.nextDouble() * 0.4,
      });
    }
    return zones;
  }
}
