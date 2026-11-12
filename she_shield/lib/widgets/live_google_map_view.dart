import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum GoogleMapType { roadmap, satellite, hybrid, terrain }

class LiveGoogleMapView extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final double height;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final List<CircleMarker> circles;
  final bool showControls;
  final bool interactive;
  final String? title;
  final bool autoFollow;
  final List<LatLng> fitPoints;
  final String? fitBoundsKey;
  final VoidCallback? onMyLocationPressed;

  const LiveGoogleMapView({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.height = 240.0,
    this.markers = const [],
    this.polylines = const [],
    this.circles = const [],
    this.showControls = true,
    this.interactive = true,
    this.title,
    this.autoFollow = true,
    this.fitPoints = const [],
    this.fitBoundsKey,
    this.onMyLocationPressed,
  });

  @override
  State<LiveGoogleMapView> createState() => _LiveGoogleMapViewState();
}

class _LiveGoogleMapViewState extends State<LiveGoogleMapView> {
  late final MapController _mapController;
  GoogleMapType _mapType = GoogleMapType.roadmap;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFitBounds());
  }

  void _maybeFitBounds() {
    if (!mounted || widget.fitPoints.length < 2) return;
    try {
      final bounds = LatLngBounds.fromPoints(widget.fitPoints);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(44)),
      );
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant LiveGoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fitBoundsKey != oldWidget.fitBoundsKey && widget.fitPoints.length >= 2) {
      _maybeFitBounds();
      return;
    }
    if (widget.autoFollow && oldWidget.center != widget.center) {
      _mapController.move(widget.center, _mapController.camera.zoom);
    }
  }

  String _getUrlTemplate() {
    switch (_mapType) {
      case GoogleMapType.satellite:
        return 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
      case GoogleMapType.hybrid:
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case GoogleMapType.terrain:
        return 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case GoogleMapType.roadmap:
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade100, width: 1.5),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.center,
                initialZoom: widget.zoom,
                interactionOptions: InteractionOptions(
                  flags: widget.interactive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _getUrlTemplate(),
                  userAgentPackageName: 'com.sheshield.she_shield',
                ),
                if (widget.circles.isNotEmpty)
                  CircleLayer(circles: widget.circles),
                if (widget.polylines.isNotEmpty)
                  PolylineLayer(polylines: widget.polylines),
                if (widget.markers.isNotEmpty)
                  MarkerLayer(markers: widget.markers),
              ],
            ),

            // Top Google Maps Branding & Type Badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.title ?? "Google Maps • Live",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls on the right (Satellite toggle, Recenter, Zoom)
            if (widget.showControls)
              Positioned(
                top: 10,
                right: 10,
                child: Column(
                  children: [
                    // Satellite / Road toggle
                    _buildMapBtn(
                      icon: _mapType == GoogleMapType.satellite
                          ? Icons.map
                          : Icons.satellite_alt,
                      tooltip: "Toggle Satellite",
                      onPressed: () {
                        setState(() {
                          _mapType = _mapType == GoogleMapType.roadmap
                              ? GoogleMapType.hybrid
                              : GoogleMapType.roadmap;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    // Recenter
                    _buildMapBtn(
                      icon: Icons.my_location,
                      tooltip: "Recenter",
                      onPressed: () {
                        widget.onMyLocationPressed?.call();
                        _mapController.move(widget.center, widget.zoom);
                      },
                    ),
                    const SizedBox(height: 6),
                    // Zoom In
                    _buildMapBtn(
                      icon: Icons.add,
                      tooltip: "Zoom in",
                      onPressed: () {
                        final current = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, current + 1);
                      },
                    ),
                    const SizedBox(height: 6),
                    // Zoom Out
                    _buildMapBtn(
                      icon: Icons.remove,
                      tooltip: "Zoom out",
                      onPressed: () {
                        final current = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, current - 1);
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Icon(icon, size: 18, color: Colors.purple.shade900),
          ),
        ),
      ),
    );
  }
}
