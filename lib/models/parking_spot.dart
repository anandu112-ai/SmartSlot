import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSpot {
  final String id;
  final String name;
  final String location;
  final int totalSlots;
  final int availableSlots;
  final double carPrice;
  final double bikePrice;
  final double latitude;
  final double longitude;

  ParkingSpot({
    required this.id,
    required this.name,
    required this.location,
    required this.totalSlots,
    required this.availableSlots,
    required this.carPrice,
    required this.bikePrice,
    required this.latitude,
    required this.longitude,
  });

  factory ParkingSpot.fromMap(Map<String, dynamic> map, String id) {
    return ParkingSpot(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      totalSlots: map['totalSlots'] ?? 0,
      availableSlots: map['availableSlots'] ?? 0,
      carPrice: (map['carPrice'] ?? 0).toDouble(),
      bikePrice: (map['bikePrice'] ?? 0).toDouble(),
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'totalSlots': totalSlots,
      'availableSlots': availableSlots,
      'carPrice': carPrice,
      'bikePrice': bikePrice,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Slot {
  final String id;
  final String name;
  final String status;
  final String parkingId;

  Slot({
    required this.id,
    required this.name,
    required this.status,
    required this.parkingId,
  });

  factory Slot.fromMap(Map<String, dynamic> map, String id) {
    return Slot(
      id: id,
      name: map['name'] ?? '',
      status: map['status'] ?? 'available',
      parkingId: map['parkingId'] ?? '',
    );
  }
}

class Booking {
  final String id;
  final String userId;
  final String parkingId;
  final String parkingName;
  final String slotId;
  final String vehicleType;
  final double price;
  final DateTime timestamp;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  Booking({
    required this.id,
    required this.userId,
    required this.parkingId,
    required this.parkingName,
    required this.slotId,
    required this.vehicleType,
    required this.price,
    required this.timestamp,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      parkingId: map['parkingId'] ?? '',
      parkingName: map['parkingName'] ?? '',
      slotId: map['slotId'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      timestamp: map['timestamp'] != null ? (map['timestamp'] as Timestamp).toDate() : DateTime.now(),
      startTime: map['startTime'] != null ? (map['startTime'] as Timestamp).toDate() : DateTime.now(),
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : DateTime.now(),
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'parkingId': parkingId,
      'parkingName': parkingName,
      'slotId': slotId,
      'vehicleType': vehicleType,
      'price': price,
      'timestamp': timestamp,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
    };
  }
}
