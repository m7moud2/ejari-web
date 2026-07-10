import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import '../theme/app_theme.dart';
import '../services/data_service.dart';
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
  bool _showListOnly = false;
  bool _mapTilesEnabled = true;
  String? _loadNote;

  final LatLng _defaultCenter = const LatLng(30.0444, 31.2357);

  static const List<Map<String, double>> _demoCoords = [
    {'lat': 30.0444, 'lng': 31.2357},
    {'lat': 30.0626, 'lng': 31.2497},
    {'lat': 30.0131, 'lng': 31.2089},
    {'lat': 30.0982, 'lng': 31.3108},
    {'lat': 29.9602, 'lng': 31.2569},
    {'lat': 30.1203, 'lng': 31.3656},
  ];

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await Future.wait([
      _requestLocationWithTimeout(),
      _loadProperties(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _requestLocationWithTimeout() async {
    try {
      final locationData = await _requestLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _loadNote = 'تم استخدام موقع تجريبي (القاهرة)';
          return null;
        },
      );

      if (locationData != null) {
        setState(() => _currentLocation = locationData);
        _mapController.move(
          LatLng(locationData.latitude!, locationData.longitude!),
          13.0,
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      _loadNote = 'تعذّر تحديد الموقع — عرض القائمة';
      if (mounted) setState(() => _showListOnly = true);
    }
  }

  Future<loc.LocationData?> _requestLocation() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return null;
    }

    loc.PermissionStatus permission = await _locationService.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _locationService.requestPermission();
      if (permission != loc.PermissionStatus.granted) return null;
    }

    return _locationService.getLocation();
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
    try {
      final allProps = await DataService.getAllProperties().timeout(
        const Duration(seconds: 10),
        onTimeout: () => <Map<String, dynamic>>[],
      );

      if (allProps.isEmpty) {
        _loadNote = 'لا توجد عقارات — تحقق من الاتصال';
        if (mounted) {
          setState(() {
            _properties = [];
            _showListOnly = true;
          });
        }
        return;
      }

      final centerLat = _currentLocation?.latitude ?? _defaultCenter.latitude;
      final centerLng = _currentLocation?.longitude ?? _defaultCenter.longitude;

      final List<Map<String, dynamic>> updatedProps = [];

      for (int i = 0; i < allProps.length; i++) {
        final prop = allProps[i];
        final demo = _demoCoords[i % _demoCoords.length];
        final lat = (prop['lat'] as num?)?.toDouble() ?? demo['lat']!;
        final lng = (prop['lng'] as num?)?.toDouble() ?? demo['lng']!;

        double distance = _calculateDistance(centerLat, centerLng, lat, lng);

        updatedProps.add({
          ...prop,
          'lat': lat,
          'lng': lng,
          'distance': distance.toStringAsFixed(1),
          'governorate': _extractGovernorate(prop['location']?.toString()),
        });
      }

      updatedProps.sort((a, b) => double.parse(a['distance'].toString())
          .compareTo(double.parse(b['distance'].toString())));

      if (mounted) {
        setState(() => _properties = updatedProps);
      }
    } catch (e) {
      debugPrint('Map properties load error: $e');
      _loadNote = 'تعذّر تحميل الخريطة — القائمة متاحة';
      if (mounted) setState(() => _showListOnly = true);
    }
  }

  String _extractGovernorate(String? location) {
    if (location == null || location.isEmpty) return 'أخرى';
    final parts = location.split('،');
    return parts.isNotEmpty ? parts.first.trim() : location;
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
      extendBodyBehindAppBar: !_showListOnly,
      appBar: AppBar(
        backgroundColor: _showListOnly
            ? AppTheme.primaryColor
            : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        foregroundColor: _showListOnly ? Colors.white : AppTheme.textPrimary,
        title: Text(
          _showListOnly ? 'العقارات حسب المحافظة' : 'استكشف العقارات من حولك 📍',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _showListOnly ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _showListOnly ? Colors.white : AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: _showListOnly ? 'عرض الخريطة' : 'عرض القائمة',
            icon: Icon(_showListOnly ? Icons.map_rounded : Icons.list_rounded),
            onPressed: () => setState(() => _showListOnly = !_showListOnly),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showListOnly
              ? _buildListFallback()
              : _buildMapView(),
    );
  }

  Widget _buildListFallback() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final p in _properties) {
      final gov = p['governorate']?.toString() ?? 'أخرى';
      grouped.putIfAbsent(gov, () => []).add(p);
    }

    return Column(
      children: [
        if (_loadNote != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppTheme.accentColor.withOpacity(0.12),
            child: Text(
              _loadNote!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        Expanded(
          child: _properties.isEmpty
              ? const Center(child: Text('لا توجد عقارات للعرض'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        ...entry.value.map((prop) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildCompactCard(prop, compact: true),
                            )),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        if (_mapTilesEnabled)
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
                            ),
                            child: Text(
                              '${prop['price']} ج.م',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          )
        else
          Container(
            color: AppTheme.backgroundColor,
            child: const Center(
              child: Text('الخريطة معطّلة — استخدم القائمة'),
            ),
          ),
        if (_loadNote != null)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.92),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(_loadNote!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11)),
              ),
            ),
          ),
        Positioned(
          right: 20,
          bottom: 250,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: 'gps',
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                onPressed: _requestLocationWithTimeout,
                child:
                    const Icon(Icons.gps_fixed, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'list',
                backgroundColor: AppTheme.primaryColor,
                onPressed: () => setState(() => _showListOnly = true),
                child: const Icon(Icons.list_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          height: 180,
          child: _properties.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
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
    );
  }

  Widget _buildCompactCard(Map<String, dynamic> prop, {bool compact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
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
                width: compact ? 100 : 120,
                height: compact ? 120 : 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: compact ? 100 : 120,
                  height: compact ? 120 : 180,
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.home_rounded),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
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
                            child: Text(
                                '${prop['distance']} كم — ${prop['location'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${prop['price']} ج.م',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
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
