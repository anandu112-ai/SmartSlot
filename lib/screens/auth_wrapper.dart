import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking_app/models/user_model.dart';
import 'package:smart_parking_app/services/auth_service.dart';
import 'admin/admin_dashboard.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // If the snapshot has user data, then they are logged in
        if (snapshot.hasData) {
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              // Show loader while fetching role
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF3F3D56)),
                  ),
                );
              }
              
              // If we have data and it's a manager, go to dashboard
              if (userSnapshot.hasData && userSnapshot.data?.role == 'Manager') {
                return const AdminDashboardScreen();
              }
              
              // Default for Drivers or if data is missing (newly signed up)
              return const MainScreen();
            },
          );
        }
        
        // Otherwise, they are not logged in - show login screen
        return LoginScreen(onLogin: () {
          // No action needed here as StreamBuilder will catch the auth change
        });
      },
    );
  }
}
