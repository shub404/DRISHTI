import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/theme/app_theme.dart';
import 'package:sih/widgets/record_card.dart';
class MyCommunityPage extends StatefulWidget {
  final String? id;
  const MyCommunityPage({super.key, required this.id});
  @override
  State<MyCommunityPage> createState() => _MyCommunityPageState();
}
class _MyCommunityPageState extends State<MyCommunityPage> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _nearbyIssues = [];
  double _searchRadius = 100.0; // Default 100m
  bool _isLoadingLocation = true;
  String? _locationError;
  final supabase = Supabase.instance.client;
  @override
  void initState() {
    super.initState();
    _handleLocationPermission();
  }
  Future<void> _handleLocationPermission() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError = "Location services are disabled. Please turn on GPS to see local reports.";
            _isLoadingLocation = false;
          });
        }
        return;
      }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _locationError = "Location permission denied. We need it to find nearby issues.";
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError = "Location permissions are permanently denied. Please enable them in settings.";
            _isLoadingLocation = false;
          });
        }
        return;
      }
      await _setUserLocation();
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = "Could not initialize location: $e";
          _isLoadingLocation = false;
        });
      }
    }
  }
  Future<void> _setUserLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      LatLng userLoc = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _selectedLocation = userLoc;
          _isLoadingLocation = false;
          _locationError = null;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLoc, 16));
        await _fetchNearbyIssues(userLoc);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = "Failed to get current location. Please try again.";
          _isLoadingLocation = false;
        });
      }
    }
  }
  Future<void> _onMapTapped(LatLng tappedPoint) async {
    setState(() {
      _selectedLocation = tappedPoint;
    });
    await _fetchNearbyIssues(tappedPoint);
  }
  Future<void> _fetchNearbyIssues(LatLng center) async {
    try {
      final response = await supabase.from('issues').select();
      List<Map<String, dynamic>> nearby = [];
      Set<Marker> newMarkers = {
        Marker(
          markerId: const MarkerId("user_selection"),
          position: center,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: "Search Center"),
        ),
      };
      for (var data in response) {
        final lat = data['latitude']?.toDouble();
        final lng = data['longitude']?.toDouble();
        final status = (data['status'] ?? 'SUBMITTED').toString().toUpperCase();
        if (lat == null || lng == null) continue;
        final distance = _calculateDistance(center.latitude, center.longitude, lat, lng);
        if (distance <= _searchRadius) {
          nearby.add({...data, 'distance': distance});
          double hue = BitmapDescriptor.hueBlue;
          if (status == 'COMPLETED') {
            hue = BitmapDescriptor.hueGreen;
          } else if (status == 'IN PROGRESS') {
            hue = BitmapDescriptor.hueOrange;
          } else if (status == 'REJECTED') {
            hue = BitmapDescriptor.hueRed;
          }
          newMarkers.add(
            Marker(
              markerId: MarkerId(data['id'].toString()),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              infoWindow: InfoWindow(
                title: data['category'] ?? 'Issue',
                snippet: '${distance.toStringAsFixed(0)}m away • $status',
              ),
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _nearbyIssues = nearby;
          _markers = newMarkers;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("COMMUNITY MAP"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, size: 20),
            onPressed: () {
              if (_locationError != null) {
                _handleLocationPermission();
              } else {
                _setUserLocation();
              }
            },
          ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.inkyNavy),
                  SizedBox(height: 16),
                  Text("Seeking location...", style: TextStyle(fontSize: 12, color: AppTheme.pencilGrey, letterSpacing: 1.2)),
                ],
              ),
            )
          : _locationError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off_outlined, size: 64, color: AppTheme.pencilGrey),
                        const SizedBox(height: 24),
                        Text(
                          "LOCATION REQUIRED",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 2.0),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _locationError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.pencilGrey, fontSize: 13),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.inkyNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const RoundedRectangleBorder(),
                            ),
                            onPressed: () => _handleLocationPermission(),
                            child: const Text("TURN ON & RETRY", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Geolocator.openAppSettings(),
                          child: const Text("OPEN SYSTEM SETTINGS", style: TextStyle(color: AppTheme.inkyNavy, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation ?? const LatLng(0, 0),
                          zoom: 16,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        markers: _markers,
                        onTap: _onMapTapped,
                        zoomControlsEnabled: false,
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [100.0, 500.0, 1000.0, 2000.0].map((r) {
                              final isSelected = _searchRadius == r;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('${r.toInt()}m', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.inkyNavy)),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() => _searchRadius = r);
                                      if (_selectedLocation != null) _fetchNearbyIssues(_selectedLocation!);
                                    }
                                  },
                                  selectedColor: AppTheme.inkyNavy,
                                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                                  shape: const RoundedRectangleBorder(),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: AppTheme.paperBackground,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECORDS WITHIN ${_searchRadius.toInt()}M',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.inkyNavy,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${_nearbyIssues.length} FOUND',
                        style: const TextStyle(fontSize: 10, color: AppTheme.pencilGrey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  flex: 2,
                  child: _nearbyIssues.isEmpty
                      ? Center(child: Text("NO RECORDS IN THIS RADIUS", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.pencilGrey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _nearbyIssues.length,
                          itemBuilder: (context, index) {
                            final issue = _nearbyIssues[index];
                            final distance = '${issue['distance'].toStringAsFixed(0)}m';
                            return RecordCard(
                              issue: issue,
                              compact: true,
                              distanceLabel: distance,
                              onTap: () {
                                _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(issue['latitude'], issue['longitude'])));
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
