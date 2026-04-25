import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String vehicleNumber;
  final String vehicleType;
  final String subscription;
  final String profileUrl;
  final List<String> favorites;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.vehicleNumber = '',
    this.vehicleType = 'Car',
    this.subscription = 'Basic',
    this.profileUrl = '',
    this.favorites = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'Driver',
      vehicleNumber: map['vehicleNumber'] ?? '',
      vehicleType: map['vehicleType'] ?? 'Car',
      subscription: map['subscription'] ?? 'Basic',
      profileUrl: map['profileUrl'] ?? '',
      favorites: List<String>.from(map['favorites'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'subscription': subscription,
      'profileUrl': profileUrl,
      'favorites': favorites,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
