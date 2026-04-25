import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class LiquidWrapper extends StatefulWidget {
  const LiquidWrapper({Key? key}) : super(key: key);

  @override
  _LiquidWrapperState createState() => _LiquidWrapperState();
}

class _LiquidWrapperState extends State<LiquidWrapper> {
  late LiquidController liquidController;

  @override
  void initState() {
    super.initState();
    liquidController = LiquidController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidSwipe(
        pages: [
          // Onboarding Page 1
          Container(
            color: const Color(0xFFFFD54F),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/car.png',
                  height: 200,
                  errorBuilder: (c,e,s) => const Icon(Icons.directions_car, size: 150),
                ),
                const SizedBox(height: 50),
                const Text(
                  "Find the Best\nParking Spot",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Swipe to start",
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ],
            ),
          ),
          // Login Page
          LoginScreen(onLogin: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }),
        ],
        liquidController: liquidController,
        enableSideReveal: true,
        slideIconWidget: const Icon(Icons.arrow_back_ios, color: Colors.black38),
        positionSlideIcon: 0.8,
        waveType: WaveType.liquidReveal,
        fullTransitionValue: 600,
        enableLoop: false,
        ignoreUserGestureWhileAnimating: true,
      ),
    );
  }
}
