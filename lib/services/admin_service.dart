import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/parking_spot.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- STATS ---
  Future<Map<String, dynamic>> getDashboardStats() async {
    final users = await _db.collection('users').get();
    final bookings = await _db.collection('bookings').get();
    final parkings = await _db.collection('parkings').get();

    double totalRevenue = 0;
    for (var doc in bookings.docs) {
      totalRevenue += (doc.data()['price'] ?? 0).toDouble();
    }

    return {
      'totalUsers': users.docs.length,
      'totalBookings': bookings.docs.length,
      'totalParkings': parkings.docs.length,
      'totalRevenue': totalRevenue,
    };
  }

  // --- USERS ---
  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // --- BOOKINGS ---
  Stream<List<Booking>> getAllBookings() {
    return _db.collection('bookings').orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // --- REVENUE ---
  Future<Map<String, double>> getRevenueAnalytics() async {
    final bookings = await _db.collection('bookings').get();
    double daily = 0;
    double monthly = 0;
    final now = DateTime.now();

    for (var doc in bookings.docs) {
      final data = doc.data();
      final DateTime date = (data['timestamp'] as Timestamp).toDate();
      final double price = (data['price'] ?? 0).toDouble();

      if (date.day == now.day && date.month == now.month && date.year == now.year) {
        daily += price;
      }
      if (date.month == now.month && date.year == now.year) {
        monthly += price;
      }
    }

    return {
      'daily': daily,
      'monthly': monthly,
    };
  }
}
