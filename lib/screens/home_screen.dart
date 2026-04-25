import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/parking_spot.dart';
import '../services/auth_service.dart';
import '../services/parking_service.dart';
import '../models/user_model.dart';
import 'slot_selection_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
        Provider.of<BookingProvider>(context, listen: false).listenToMyBookings(user.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: PageView(
        controller: _pageController,
        children: [
          _buildDashboard(context, provider),
          const MapScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 40,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Slide right to explore map ", style: TextStyle(color: Colors.grey, fontSize: 11)),
            Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, BookingProvider provider) {
    return SafeArea(
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildSearchBar(),
              const SizedBox(height: 30),
              _buildVehicleSelector(provider),
              const SizedBox(height: 40),
              const Text("Nearby Parking", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildParkingList(provider),
              const SizedBox(height: 20),
            ],
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("HELLO ${_currentUser?.name.toUpperCase() ?? 'BUDDY'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const Text("SmartSlot", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: _currentUser?.profileUrl.isNotEmpty == true ? NetworkImage(_currentUser!.profileUrl) : null,
            child: _currentUser?.profileUrl.isEmpty == true ? const Icon(Icons.person, color: Colors.black) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: TextField(
        onSubmitted: (q) => Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(initialQuery: q))),
        decoration: const InputDecoration(hintText: "Search location...", border: InputBorder.none, icon: Icon(Icons.search)),
      ),
    );
  }

  Widget _buildVehicleSelector(BookingProvider provider) {
    return Row(
      children: [
        Expanded(child: _categoryBox("Car", Icons.directions_car, provider.selectedVehicleType == "Car", () => provider.selectVehicle("Car"))),
        const SizedBox(width: 20),
        Expanded(child: _categoryBox("Bike", Icons.motorcycle, provider.selectedVehicleType == "Bike", () => provider.selectVehicle("Bike"))),
      ],
    );
  }

  Widget _categoryBox(String text, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: active ? const Color(0xFFFFD54F) : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [Icon(icon, size: 30), Text(text)]),
      ),
    );
  }

  Widget _buildParkingList(BookingProvider provider) {
    if (provider.parkingSpots.isEmpty) return const Center(child: Text("No parking found"));
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.parkingSpots.length,
        itemBuilder: (context, index) => _buildSpotCard(provider.parkingSpots[index], provider),
      ),
    );
  }

  Widget _buildSpotCard(ParkingSpot spot, BookingProvider provider) {
    return GestureDetector(
      onTap: () {
        provider.selectSpot(spot);
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SlotSelectionScreen()));
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(spot.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(spot.location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("₹${provider.getDynamicPrice(spot).toInt()}/hr", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${spot.availableSlots} slots", style: TextStyle(color: spot.availableSlots > 0 ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
