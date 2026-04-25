import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'manage_users.dart';
import 'manage_parking.dart';
import 'all_bookings.dart';
import '../map_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  final AdminService _adminService = AdminService();
  final ImagePicker _picker = ImagePicker();
  UserModel? _manager;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadManager();
  }

  Future<void> _loadManager() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await _authService.getUserData(user.uid);
      if (mounted) setState(() => _manager = data);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 50);
      if (image == null) return;

      if (mounted) {
        Navigator.pop(context);
        setState(() => _isUploading = true);
      }

      final storageRef = FirebaseStorage.instance.ref().child('profile_pics/\${_manager!.id}.jpg');
      String downloadUrl;

      try {
        UploadTask uploadTask;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          uploadTask = storageRef.putFile(File(image.path));
        }
        await uploadTask.timeout(const Duration(seconds: 15));
        downloadUrl = await storageRef.getDownloadURL();
      } catch (e) {
        // Fallback to Base64
        final bytes = await image.readAsBytes();
        downloadUrl = "data:image/jpeg;base64,\${base64Encode(bytes)}";
      }

      await _authService.updateUserData(_manager!.id, {'profileUrl': downloadUrl});
      await _loadManager();

      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: \$e"), backgroundColor: Colors.red));
      }
    }
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              // Profile Picture
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF3F3D56),
                    backgroundImage: _manager?.profileUrl.isNotEmpty == true
                        ? (_manager!.profileUrl.startsWith('data:')
                            ? MemoryImage(base64Decode(_manager!.profileUrl.split(',').last)) as ImageProvider
                            : NetworkImage(_manager!.profileUrl))
                        : null,
                    child: (_manager?.profileUrl.isEmpty ?? true)
                        ? Text(_manager?.name[0] ?? 'M', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        onPressed: () => _showImagePicker(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(_manager?.name ?? 'Manager', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text("Manager", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 25),
              // Account Info
              _profileTile(Icons.email, "Email", _manager?.email ?? '-', () => _showEditDialog("email", _manager?.email ?? '')),
              _profileTile(Icons.phone, "Phone", _manager?.phone.isEmpty == true ? 'Not set' : (_manager?.phone ?? '-'), () => _showEditDialog("phone", _manager?.phone ?? '')),
              _profileTile(Icons.person, "Name", _manager?.name ?? '-', () => _showEditDialog("name", _manager?.name ?? '')),
              const Divider(height: 30),
              // Password Reset
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _showPasswordResetDialog();
                },
                leading: const CircleAvatar(radius: 18, backgroundColor: Color(0xFFFFECB3), child: Icon(Icons.lock, color: Colors.orange, size: 18)),
                title: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Send reset email via Firebase", style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, size: 18),
              ),
              // Logout
              ListTile(
                onTap: () async {
                  Navigator.pop(context);
                  await _authService.logout();
                },
                leading: const CircleAvatar(radius: 18, backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.logout, color: Colors.red, size: 18)),
                title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePicker() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const Text("Update Profile Picture", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ListTile(leading: const Icon(Icons.photo_library, color: Colors.blue), title: const Text("Pick from Gallery"), onTap: () => _pickAndUploadImage(ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.camera_alt, color: Colors.orange), title: const Text("Take a Photo"), onTap: () => _pickAndUploadImage(ImageSource.camera)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showEditDialog(String field, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit \${field[0].toUpperCase()}\${field.substring(1)}"),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: "Enter new \$field")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _authService.updateUserData(_manager!.id, {field: controller.text.trim()});
              Navigator.pop(context);
              await _loadManager();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: const Text("A password reset link will be sent to your registered email address."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: _manager!.email);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset email sent!"), backgroundColor: Colors.green));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: \$e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Send Reset Email"),
          ),
        ],
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, String value, VoidCallback onEdit) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: onEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Manager Dashboard", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isUploading)
            const Padding(padding: EdgeInsets.all(15), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            GestureDetector(
              onTap: _showProfileSheet,
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF3F3D56),
                  backgroundImage: _manager?.profileUrl.isNotEmpty == true
                      ? (_manager!.profileUrl.startsWith('data:')
                          ? MemoryImage(base64Decode(_manager!.profileUrl.split(',').last)) as ImageProvider
                          : NetworkImage(_manager!.profileUrl))
                      : null,
                  child: (_manager?.profileUrl.isEmpty ?? true)
                      ? Text(_manager?.name[0] ?? 'M', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                      : null,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3F3D56), Color(0xFF6C63FF)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: _manager?.profileUrl.isNotEmpty == true
                        ? (_manager!.profileUrl.startsWith('data:')
                            ? MemoryImage(base64Decode(_manager!.profileUrl.split(',').last)) as ImageProvider
                            : NetworkImage(_manager!.profileUrl))
                        : null,
                    child: (_manager?.profileUrl.isEmpty ?? true)
                        ? Text(_manager?.name[0] ?? 'M', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome back,", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      Text(_manager?.name ?? 'Manager', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text("Manager • SmartSlot", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text("Business Analytics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            FutureBuilder<Map<String, dynamic>>(
              future: _adminService.getDashboardStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final stats = snapshot.data!;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.5,
                  children: [
                    _statCard("Users", stats['totalUsers'].toString(), Icons.people, Colors.blue),
                    _statCard("Bookings", stats['totalBookings'].toString(), Icons.book_online, Colors.orange),
                    _statCard("Revenue", "₹\${stats['totalRevenue'].toInt()}", Icons.account_balance_wallet, Colors.green),
                    _statCard("Active Spots", stats['totalParkings'].toString(), Icons.local_parking, Colors.purple),
                  ],
                );
              },
            ),
            const SizedBox(height: 25),
            const Text("Management Tools", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _toolTile(context, "User Directory", "View and manage user accounts", Icons.person_search, Colors.blue, const ManageUsersScreen()),
            _toolTile(context, "Parking Map", "Interactive map to add/move spots", Icons.map, Colors.purple, const MapScreen()),
            _toolTile(context, "Parking List", "View and edit spots in a list", Icons.list, Colors.teal, const ManageParkingScreen()),
            _toolTile(context, "Booking History", "Full audit log of all transactions", Icons.history, Colors.orange, const AllBookingsScreen()),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _toolTile(BuildContext context, String title, String subtitle, IconData icon, Color color, Widget screen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
