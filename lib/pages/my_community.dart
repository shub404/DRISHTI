import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sih/theme/app_theme.dart';

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

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _setUserLocation();
  }

  /// 🔹 Get user location and set map
  Future<void> _setUserLocation() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng userLoc = LatLng(pos.latitude, pos.longitude);

    if (mounted) {
      setState(() {
        _selectedLocation = userLoc;
        _markers = {
          Marker(markerId: const MarkerId("selected"), position: userLoc),
        };
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLoc, 16));
      await _fetchNearbyIssues(userLoc);
    }
  }

  /// 🔹 Handle map tap (select different location)
  Future<void> _onMapTapped(LatLng tappedPoint) async {
    setState(() {
      _selectedLocation = tappedPoint;
      _markers = {
        Marker(markerId: const MarkerId("selected"), position: tappedPoint),
      };
    });

    await _fetchNearbyIssues(tappedPoint);
  }

  /// 🔹 Fetch nearby issues from Supabase
  Future<void> _fetchNearbyIssues(LatLng location) async {
    try {
      // Supabase query to get all issues (flat table)
      final response = await supabase.from('issues').select();

      List<Map<String, dynamic>> nearby = [];

      for (var data in response) {
        final lat = data['latitude']?.toDouble();
        final lng = data['longitude']?.toDouble();

        if (lat == null || lng == null) continue;

        final distance = _calculateDistance(
          location.latitude,
          location.longitude,
          lat,
          lng,
        );

        // Filter for issues within 100 meters
        if (distance <= 100) {
          nearby.add({
            ...data,
            'distance': distance,
          });
        }
      }

      if (mounted) {
        setState(() {
          _nearbyIssues = nearby;
        });
      }
    } catch (e) {
      debugPrint("Error fetching nearby issues: $e");
    }
  }

  /// 🔹 Distance calculation (Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double degree) => degree * pi / 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LOCAL RECORDS")),
      body: _selectedLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderInk, width: 1.0)),
                    ),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation!,
                        zoom: 16,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      markers: _markers,
                      onTap: _onMapTapped,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'RECORDS WITHIN 100M RADIUS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.inkyNavy,
                          fontSize: 10,
                          letterSpacing: 2.0,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  flex: 2,
                  child: _nearbyIssues.isEmpty
                      ? Center(
                          child: Text(
                            "NO LOCAL RECORDS FOUND",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.pencilGrey,
                                  letterSpacing: 1.0,
                                ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          itemCount: _nearbyIssues.length,
                          itemBuilder: (context, index) {
                            final issue = _nearbyIssues[index];
                            final category = (issue['category'] ?? 'UNCATEGORISED').toString().toUpperCase();
                            final description = issue['description'] ?? 'No detail provided.';
                            final distance = issue['distance'] as double;
                            final imageUrl = issue['image_url'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      Container(
                                        width: 60,
                                        height: 60,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppTheme.borderInk, width: 0.5),
                                        ),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: AppTheme.inkyNavy.withOpacity(0.05),
                                              child: const Center(child: CircularProgressIndicator(strokeWidth: 1)),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: AppTheme.inkyNavy.withOpacity(0.05),
                                              child: const Center(
                                                child: Icon(Icons.image_not_supported_outlined, size: 16, color: AppTheme.inkyNavy),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                category,
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
                                              ),
                                              Text(
                                                "${distance.toStringAsFixed(0)}M AWAY",
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            description,
                                            style: Theme.of(context).textTheme.bodySmall,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
