import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_spot.dart';

class ParkingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of all parking spots
  Stream<List<ParkingSpot>> getParkingSpots() {
    return _db.collection('parkings').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ParkingSpot.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Stream of slots for a specific parking
  Stream<List<Slot>> getSlots(String parkingId) {
    return _db
        .collection('parkings')
        .doc(parkingId)
        .collection('slots')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Slot.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Book a parking spot with a specific slot
  Future<void> bookParkingSpot({
    required String userId,
    required ParkingSpot spot,
    required String slotId,
    required String vehicleType,
    required double price,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final DocumentReference parkingRef = _db.collection('parkings').doc(spot.id);
    final DocumentReference slotRef = parkingRef.collection('slots').doc(slotId);
    final DocumentReference bookingRef = _db.collection('bookings').doc();

    return _db.runTransaction((transaction) async {
      DocumentSnapshot parkingDoc = await transaction.get(parkingRef);
      DocumentSnapshot slotDoc = await transaction.get(slotRef);

      if (!parkingDoc.exists || !slotDoc.exists) {
        throw Exception("Parking or Slot does not exist!");
      }

      if (slotDoc.get('status') != 'available') {
        throw Exception("Slot is no longer available!");
      }

      int currentAvailable = parkingDoc.get('availableSlots');

      // Create booking document
      transaction.set(bookingRef, {
        'userId': userId,
        'parkingId': spot.id,
        'parkingName': spot.name,
        'slotId': slotId,
        'vehicleType': vehicleType,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
        'startTime': startTime,
        'endTime': endTime,
        'status': 'active',
      });

      // Update slot status
      transaction.update(slotRef, {
        'status': 'booked',
      });

      // Update parking available slots
      transaction.update(parkingRef, {
        'availableSlots': currentAvailable - 1,
      });
    });
  }

  // Cancel a booking
  Future<void> cancelBooking(Booking booking) async {
    final DocumentReference parkingRef = _db.collection('parkings').doc(booking.parkingId);
    final DocumentReference slotRef = parkingRef.collection('slots').doc(booking.slotId);
    final DocumentReference bookingRef = _db.collection('bookings').doc(booking.id);

    return _db.runTransaction((transaction) async {
      DocumentSnapshot parkingDoc = await transaction.get(parkingRef);
      
      transaction.update(bookingRef, {
        'status': 'cancelled',
      });

      transaction.update(slotRef, {
        'status': 'available',
      });

      if (parkingDoc.exists) {
        int currentAvailable = parkingDoc.get('availableSlots');
        transaction.update(parkingRef, {
          'availableSlots': currentAvailable + 1,
        });
      }
    });
  }

  // Stream of user's bookings
  Stream<List<Booking>> getUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  Future<void> seedData() async {
    final List<Map<String, dynamic>> sampleParkings = [
      {'name': 'Technopark Campus P1', 'location': 'Trivandrum', 'totalSlots': 120, 'availableSlots': 45, 'carPrice': 30, 'bikePrice': 10, 'latitude': 8.5581, 'longitude': 76.8770},
      {'name': 'Central Station East', 'location': 'Trivandrum', 'totalSlots': 50, 'availableSlots': 15, 'carPrice': 40, 'bikePrice': 15, 'latitude': 8.4891, 'longitude': 76.9497},
      {'name': 'Museum Gardens', 'location': 'Trivandrum', 'totalSlots': 40, 'availableSlots': 20, 'carPrice': 20, 'bikePrice': 5, 'latitude': 8.5085, 'longitude': 76.9535},
      {'name': 'Mall of Travancore', 'location': 'Trivandrum', 'totalSlots': 200, 'availableSlots': 110, 'carPrice': 50, 'bikePrice': 20, 'latitude': 8.4831, 'longitude': 76.9179},
    ];

    for (var parkingData in sampleParkings) {
      final String docId = 'sample_\${parkingData["name"].toString().replaceAll(" ", "_")}';
      final parkingRef = _db.collection('parkings').doc(docId);
      await parkingRef.set(parkingData);

      for (int i = 1; i <= (parkingData['totalSlots'] as int); i++) {
        final slotId = 'S\$i';
        String status = 'available';
        if (i % 4 == 0) status = 'booked';
        if (i % 7 == 0) status = 'reserved';

        await parkingRef.collection('slots').doc(slotId).set({
          'name': slotId,
          'status': status,
          'parkingId': parkingRef.id,
        });
      }
    }
  }

  Future<void> addCustomParking({
    required String name,
    required String location,
    required double lat,
    required double lng,
  }) async {
    final parkingData = {
      'name': name,
      'location': location,
      'totalSlots': 20,
      'availableSlots': 15,
      'carPrice': 50.0,
      'bikePrice': 20.0,
      'latitude': lat,
      'longitude': lng,
    };

    final parkingRef = _db.collection('parkings').doc();
    await parkingRef.set(parkingData);

    for (int i = 1; i <= 20; i++) {
      final slotId = 'S\$i';
      await parkingRef.collection('slots').doc(slotId).set({
        'name': slotId,
        'status': i % 5 == 0 ? 'booked' : 'available',
        'parkingId': parkingRef.id,
      });
    }
  }

  // Update parking details
  Future<void> updateParkingDetails({
    required String parkingId,
    required String name,
    required double carPrice,
    required double bikePrice,
  }) async {
    await _db.collection('parkings').doc(parkingId).update({
      'name': name,
      'carPrice': carPrice,
      'bikePrice': bikePrice,
    });
  }

  // Move parking to new location
  Future<void> moveParking({
    required String parkingId,
    required double lat,
    required double lng,
  }) async {
    await _db.collection('parkings').doc(parkingId).update({
      'latitude': lat,
      'longitude': lng,
    });
  }

  // Delete parking spot
  Future<void> deleteParking(String parkingId) async {
    final slots = await _db.collection('parkings').doc(parkingId).collection('slots').get();
    for (var slot in slots.docs) {
      await slot.reference.delete();
    }
    await _db.collection('parkings').doc(parkingId).delete();
  }
}
