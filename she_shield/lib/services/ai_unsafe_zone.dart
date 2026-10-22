class AiUnsafeZoneService {
  static Map<String, dynamic> evaluateZoneRisk(double lat, double lng) {
    return {
      'riskScore': 67,
      'riskLevel': 'MODERATE',
      'factors': ['Night Safety (Low)', 'Time-based Risk (Moderate at 10 PM)', 'GPS Deviation at 38%'],
      'recommendation': 'Approaching minor risk zone near historical complaint hotspots.',
    };
  }
}