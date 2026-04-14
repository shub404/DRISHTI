import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    setState(() {
      _selectedLocation = userLoc;
      _markers = {
        Marker(markerId: const MarkerId("selected"), position: userLoc),
      };
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLoc, 16));
    await _fetchNearbyIssues(userLoc);
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

  /// 🔹 Fetch nearby issues from Firestore
  Future<void> _fetchNearbyIssues(LatLng location) async {
    final snapshot =
        await FirebaseFirestore.instance.collectionGroup('issues').get();

    List<Map<String, dynamic>> nearby = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lat = data['latitude']?.toDouble();
      final lng = data['longitude']?.toDouble();

      if (lat == null || lng == null) continue;

      final distance = _calculateDistance(
        location.latitude,
        location.longitude,
        lat,
        lng,
      );

      if (distance <= 100) {
        nearby.add({
          'id': doc.id,
          ...data,
          'distance': distance,
        });
      }
    }

    setState(() {
      _nearbyIssues = nearby;
    });
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
      appBar: AppBar(title: const Text("My Community")),
      body: _selectedLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 2,
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
                Expanded(
                  flex: 1,
                  child: _nearbyIssues.isEmpty
                      ? const Center(child: Text("🚫 No issues within 100m"))
                      : ListView.builder(
                          itemCount: _nearbyIssues.length,
                          itemBuilder: (context, index) {
                            final issue = _nearbyIssues[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                leading: issue['image_url'] != null
                                    ? Image.network(issue['image_url'],
                                        width: 50, fit: BoxFit.cover)
                                    : const Icon(Icons.report),
                                title: Text(issue['category'] ?? 'No Category'),
                                subtitle:
                                    Text(issue['description'] ?? 'No Description'),
                                trailing: Text(
                                  "${(issue['distance'] as double).toStringAsFixed(1)} m",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
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
