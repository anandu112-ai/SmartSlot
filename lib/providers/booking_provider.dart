import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parking_spot.dart';
import '../services/parking_service.dart';

class BookingProvider with ChangeNotifier {
  final ParkingService _parkingService = ParkingService();

  List<ParkingSpot> _parkingSpots = [];
  List<ParkingSpot> get parkingSpots => _parkingSpots;

  List<Booking> _myBookings = [];
  List<Booking> get myBookings => _myBookings;

  List<Slot> _slots = [];
  List<Slot> get slots => _slots;

  String _selectedVehicleType = "Car";
  String get selectedVehicleType => _selectedVehicleType;

  ParkingSpot? _selectedSpot;
  ParkingSpot? get selectedSpot => _selectedSpot;

  Slot? _selectedSlot;
  Slot? get selectedSlot => _selectedSlot;

  bool _isBooking = false;
  bool get isBooking => _isBooking;

  BookingProvider() {
    _listenToParkingSpots();
  }

  void _listenToParkingSpots() {
    _parkingService.getParkingSpots().listen((spots) {
      _parkingSpots = spots;
      notifyListeners();
    });
  }

  void listenToSlots(String parkingId) {
    _parkingService.getSlots(parkingId).listen((slots) {
      _slots = slots;
      notifyListeners();
    });
  }

  void listenToMyBookings(String userId) {
    _parkingService.getUserBookings(userId).listen((bookings) {
      _myBookings = bookings;
      notifyListeners();
    });
  }

  void selectVehicle(String type) {
    _selectedVehicleType = type;
    notifyListeners();
  }

  void selectSpot(ParkingSpot spot) {
    _selectedSpot = spot;
    _selectedSlot = null; // Reset slot when spot changes
    notifyListeners();
  }

  void selectSlot(Slot slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  Future<void> confirmBooking({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    required double totalPrice,
  }) async {
    if (_selectedSpot == null || _selectedSlot == null) return;

    _isBooking = true;
    notifyListeners();

    try {
      await _parkingService.bookParkingSpot(
        userId: userId,
        spot: _selectedSpot!,
        slotId: _selectedSlot!.id,
        vehicleType: _selectedVehicleType,
        price: totalPrice,
        startTime: startTime,
        endTime: endTime,
      );
      
      _isBooking = false;
      notifyListeners();
    } catch (e) {
      _isBooking = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelBooking(Booking booking) async {
    try {
      await _parkingService.cancelBooking(booking);
    } catch (e) {
      rethrow;
    }
  }

  // --- DYNAMIC PRICING ---
  double getDynamicPrice(ParkingSpot spot) {
    double basePrice = _selectedVehicleType == "Car" ? spot.carPrice : spot.bikePrice;
    double multiplier = 1.0;

    // 1. Demand Based (Low Availability = higher price)
    if (spot.availableSlots < 3 && spot.availableSlots > 0) {
      multiplier += 0.20; // 20% increase
    }

    // 2. Time Based (Peak Hours 6 PM - 10 PM)
    int hour = DateTime.now().hour;
    if (hour >= 18 && hour <= 22) {
      multiplier += 0.15; // 15% increase
    }

    return basePrice * multiplier;
  }
}
