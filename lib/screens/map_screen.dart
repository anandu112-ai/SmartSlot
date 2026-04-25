import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/booking_provider.dart';
import '../models/parking_spot.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/parking_service.dart';
import '../services/auth_service.dart';
import 'slot_selection_screen.dart';

class MapScreen extends StatefulWidget {
  final String? initialQuery;
  final ParkingSpot? targetSpot;
  const MapScreen({Key? key, this.initialQuery, this.targetSpot}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  LatLng _currentCenter = const LatLng(28.6139, 77.2090); // Delhi
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _userRole = "Driver";
  ParkingSpot? _draggingSpot;
  LatLng? _dragPosition;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    if (widget.targetSpot != null) {
      _currentCenter = LatLng(widget.targetSpot!.latitude, widget.targetSpot!.longitude);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentCenter, 16);
        _showSpotDetails(widget.targetSpot!);
      });
    } else {
      _setInitialLocation().then((_) {
        if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
          _searchController.text = widget.initialQuery!;
          _searchLocation(widget.initialQuery!);
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await AuthService().getUserData(user.uid);
      if (mounted && userData != null) {
        setState(() {
          _currentUser = userData;
          _userRole = userData.role;
        });
      }
    }
  }

  Future<void> _setInitialLocation() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentCenter, 14);
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lon = double.parse(data[0]['lon']);
          LatLng target = LatLng(lat, lon);
          _mapController.move(target, 14);
          setState(() => _currentCenter = target);
        }
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showSpotDetails(ParkingSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spot.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.blue),
                          const SizedBox(width: 5),
                          Text(spot.location, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (_currentUser == null) return;
                      await AuthService().toggleFavorite(_currentUser!.id, spot.id);
                      final updatedUser = await AuthService().getUserData(_currentUser!.id);
                      
                      bool isFav = updatedUser?.favorites.contains(spot.id) ?? false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFav ? "Added to Favorites" : "Removed from Favorites"),
                          duration: const Duration(seconds: 1),
                          backgroundColor: isFav ? Colors.green : Colors.red,
                        ),
                      );

                      setModalState(() => _currentUser = updatedUser);
                      setState(() => _currentUser = updatedUser);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F3D56).withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currentUser?.favorites.contains(spot.id) ?? false ? Icons.favorite : Icons.favorite_border, 
                        color: _currentUser?.favorites.contains(spot.id) ?? false ? Colors.red : const Color(0xFF3F3D56)
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _professionalStat(Icons.directions_car, "₹${spot.carPrice.toInt()}/hr", "Car"),
                  _professionalStat(Icons.motorcycle, "₹${spot.bikePrice.toInt()}/hr", "Bike"),
                  _professionalStat(Icons.local_parking, "${spot.availableSlots}", "Slots Left"),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                "Quick Preview",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        "S${index + 1}",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () => _launchNavigation(spot.latitude, spot.longitude),
                      icon: const Icon(Icons.navigation_outlined, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: spot.availableSlots == 0 ? null : () {
                          Navigator.pop(context);
                          Provider.of<BookingProvider>(context, listen: false).selectSpot(spot);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SlotSelectionScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F3D56),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          "Proceed to Slot Selection",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_userRole == 'Manager') ...[]
            ],
          ),
        ),
      ),
    );
  }

  Widget _professionalStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3F3D56), size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final markers = provider.parkingSpots.map((spot) {
      bool isFull = spot.availableSlots == 0;
      LatLng position = LatLng(spot.latitude, spot.longitude);

      return Marker(
        point: position,
        width: 100,
        height: 120,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showSpotDetails(spot),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F3D56),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Text(
                  isFull ? "FULL" : "₹${provider.getDynamicPrice(spot).toInt()}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              Icon(
                Icons.location_on,
                size: 55,
                color: const Color(0xFF3F3D56),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.smart_parking_app'),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
              child: TextField(
                controller: _searchController,
                onSubmitted: _searchLocation,
                decoration: InputDecoration(
                  hintText: "Search location...",
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(onPressed: _setInitialLocation, backgroundColor: Colors.white, child: const Icon(Icons.my_location, color: Color(0xFF3F3D56))),
          ),
        ],
      ),
    );
  }
}
