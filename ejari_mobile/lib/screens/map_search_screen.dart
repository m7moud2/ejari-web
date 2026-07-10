import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import '../theme/app_theme.dart';
import '../services/firestore_property_service.dart';
import 'property_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final MapController _mapController = MapController();
  loc.LocationData? _currentLocation;
  final loc.Location _locationService = loc.Location();
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;

  final LatLng _defaultCenter = const LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _requestLocation();
    await _loadProperties();
  }

  Future<void> _requestLocation() async {
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) return;
      }

      loc.PermissionStatus permission = await _locationService.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await _locationService.requestPermission();
        if (permission != loc.PermissionStatus.granted) return;
      }

      final locationData = await _locationService.getLocation();
      setState(() {
        _currentLocation = locationData;
      });

      if (_currentLocation != null) {
        _mapController.move(
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            15.0);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<void> _loadProperties() async {
    final allProps = await FirestorePropertyService.getAllProperties();
    final centerLat = _currentLocation?.latitude ?? 30.0444;
    final centerLng = _currentLocation?.longitude ?? 31.2357;

    final List<Map<String, dynamic>> updatedProps = [];

    for (int i = 0; i < allProps.length; i++) {
      final prop = allProps[i];
      final lat = centerLat + (i % 2 == 0 ? 0.005 * (i + 1) : -0.005 * (i + 1));
      final lng = centerLng + (i % 3 == 0 ? 0.005 * (i + 1) : -0.005 * (i + 1));

      double distance = 0;
      if (_currentLocation != null) {
        distance = _calculateDistance(_currentLocation!.latitude!,
            _currentLocation!.longitude!, lat, lng);
      }

      updatedProps.add({
        ...prop,
        'lat': lat,
        'lng': lng,
        'distance': distance.toStringAsFixed(1),
      });
    }

    setState(() {
      _properties = updatedProps;
      _isLoading = false;
    });
  }

  Future<void> _openDirections(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        title: const Text('استكشف العقارات من حولك 📍',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ejari_mobile',
              ),
              MarkerLayer(
                markers: _properties.map((prop) {
                  return Marker(
                    point: LatLng(prop['lat'], prop['lng']),
                    width: 100,
                    height: 80,
                    child: GestureDetector(
                      onTap: () => _showPropertyPreview(prop),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [],
                            ),
                            child: Text(
                              '${prop['price']} ج.م',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                          ),
                          const Icon(Icons.location_on,
                              color: AppTheme.primaryColor, size: 30),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentLocation!.latitude!,
                          _currentLocation!.longitude!),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.my_location,
                              color: AppTheme.primaryColor, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            right: 20,
            bottom: 250,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              onPressed: _requestLocation,
              child: const Icon(Icons.gps_fixed, color: AppTheme.primaryColor),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _properties.length,
              itemBuilder: (context, index) {
                final prop = _properties[index];
                return Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildCompactCard(prop),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(Map<String, dynamic> prop) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PropertyDetailsScreen(property: prop))),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(24)),
              child: Image.asset(
                prop['image'] ?? 'assets/images/home1.jpg',
                width: 120,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      prop['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text('${prop['distance']} كم بعيداً عنك',
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12))),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${prop['price']} ج.م',
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: IconButton(
                            onPressed: () =>
                                _openDirections(prop['lat'], prop['lng']),
                            icon: const Icon(Icons.directions,
                                color: AppTheme.primaryColor, size: 20),
                            tooltip: 'الاتجاهات',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPropertyPreview(Map<String, dynamic> property) {
    _mapController.move(LatLng(property['lat'], property['lng']), 16.0);
  }
}
